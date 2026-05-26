+++
title = "pg_infer: transformer-model knowledge as SQL relations"
date = "2026-08-17"
draft = true
description = "What if the model itself — gate vectors, learned associations, feature labels — lived in WAL-logged Postgres pages and the planner could see it as just another relation?"
[taxonomies]
tags = ["postgres","pg_infer","llm","bitnet","extensions"]
+++

There are two stories about "AI in the database" and I am tired of
both of them.

The first story is *call out to a model*.  You add a UDF
`openai_completion(prompt)`, drop it in a `WHERE` clause or a
trigger, and accept that the database is now a thin client to a
different system that owns your latency, your costs, and your
failure modes.

The second story is *embeddings as a separate index*.  You
pre-compute embeddings with one model, store them in
[`pgvector`](https://github.com/pgvector/pgvector), query them as
nearest-neighbour distances, and accept that you have two systems
of record now — the embeddings and the source text — and that
when the model changes, the embeddings have to change too.

[`pg_infer`](https://codeberg.org/gregburd/pg_infer) is a third
story.  The model itself — its gate vectors, its feature
activations, its learned associations — lives in WAL-logged
8 KB Postgres pages.  The planner sees model operators as
operators, not as RPCs.  The questions you can ask are different
from the ones the first two stories let you ask.

## the queries that motivate the work

Here are four queries.  Read them and ask which of pgvector,
pg_trgm, full-text search, or "call OpenAI from a trigger" can
answer each one.

```sql
-- (1) What does the model "know" about France?
SELECT * FROM describe('France');
--  relation  | target  | confidence | layer
-- -----------+---------+------------+-------
--  capital   | Paris   |       42.7 |    18
--  language  | French  |       38.1 |    17
--  continent | Europe  |       35.4 |    16
--  currency  | euro    |       29.8 |    19
--  leader    | president |     24.3 |    20
```

```sql
-- (2) Order by model-knowledge similarity, index-driven:
CREATE INDEX ON papers USING infer (title) WITH (model = 'qwen05b');

SELECT id, title
  FROM papers
 ORDER BY title <~> 'neural architecture search'
 LIMIT 5;
--  id |              title               | distance
-- ----+----------------------------------+----------
--  42 | AutoML for Deep Networks         |    0.023
--  17 | Efficient Neural Arch Search     |    0.031
--   8 | Meta-Learning and Model Selection|    0.058
```

That second one finds "AutoML for Deep Networks" because the model
*learned* that AutoML and neural-architecture-search are the same
research area.  No keyword overlap.  No pre-computed embedding.
`pg_trgm %` cannot do this.  Full-text search cannot do this.
`pgvector` can do this *only if* you computed and stored embeddings
ahead of time with a model whose semantics happen to agree with
your query.  pg_infer asks the model directly, through an index.

```sql
-- (3) Joining model knowledge with relational data:
SELECT c.id, c.name, p.title,
       p.title <~> c.research_interest AS dist
  FROM candidates c
  JOIN papers p
    ON p.title <~> c.research_interest < 0.2
 WHERE c.country = 'DE';
```

Standard SQL semantics.  Standard PostgreSQL planner.  A
model-driven join condition that the planner can cost,
parallelize, and combine with `WHERE c.country = 'DE'` the way it
combines any other predicate.

```sql
-- (4) Auditing model behaviour with PITR:
SELECT relation, target, confidence
  FROM describe('PostgreSQL')
 WHERE confidence > 30;
```

Because the vindex lives in WAL-logged pages, point-in-time
recovery on a pg_infer-using cluster gives you the *model state*
at any historical moment, alongside the data state.  "What was
the model saying about this entity at 03:14 UTC last Tuesday?"
is a literal `recovery_target_time = '...'` plus
`SELECT * FROM describe(...)`.

I do not have a clean way to ask any of these four questions in
PostgreSQL today without pg_infer.  That is the gap the project
fills.

## the data model

The unit of pg_infer's storage is a **vindex** — a vectorized
index of a transformer model's learned structure.  A vindex
contains:

  - per-layer gate-activation vectors (f16, decoded lazily to f32),
  - feature-label metadata (what the model treats each gate as
    "meaning"),
  - token embeddings,
  - tokenizer data.

The extraction pipeline — and the vindex format — were designed
by Chris Hayuk for the
[LARQL project](https://github.com/chrishayuk/larql).  pg_infer
adapts that format into a PostgreSQL access method, a WAL-logged
storage layer, and a planner-visible operator.  The intellectual
debt is large and I want to be loud about it: the gate-KNN
algorithm, the feature-labeling pipeline, and the vindex layout
are all from LARQL, and Chris's
[YouTube walkthroughs](https://www.youtube.com/@chrishayuk) are
the right place to start if you want to understand *why* the
format looks the way it does.

What pg_infer adds is the database story: WAL coverage,
replication, `EXPLAIN (ANALYZE, BUFFERS)`, the planner-visible
`<~>` operator, the index AM, and the deployment shapes that a
production cluster needs.

## the index access method

pg_infer registers a custom index AM under the name `infer` with
two modes:

  - **Model index.**  The full vindex lives in standard 8 KB
    PostgreSQL pages, WAL-logged via `GenericXLog`.  Backup,
    replication, point-in-time recovery, and `pg_dump` cover
    the model the same way they cover your tables.  Created
    with `CREATE INDEX ... USING infer (name) WITH (source =
    '/path/to/model.vindex')` against the internal
    `infer._models` relation.

  - **Column index.**  Attaches a registered model to a text
    column and makes `ORDER BY column <~> 'text'` index-driven.
    Created with `CREATE INDEX ... USING infer (title) WITH
    (model = 'qwen05b')`.

Page types within a model index:

  - `Meta` — model name, dimensions, configuration.
  - `LayerDir` — per-layer block ranges for gate vectors.
  - `Gate` — f16 gate activation vectors.
  - `Embed` — token embedding vectors.
  - `DownMeta` — feature metadata (labels, top-k tokens per
    feature).
  - `Blob` — tokenizer data.

The OS kernel page-shares mmap'd vindex pages across backends
that touch the same model, so the per-connection memory overhead
is small even on heavily-used models.

## why CPU and why BitNet

Database servers almost never have GPUs.  They have a lot of fast
cores, a lot of RAM, and — on most production deployments —
standby replicas, read-only physical replicas, logical
subscribers, and DR hosts that spend most of the day at single-
digit CPU utilisation while the primary takes the write traffic.

pg_infer targets that hardware profile directly:

  - The default execution paths run on CPU.  Linear algebra is
    BLAS-backed (OpenBLAS); gate vectors are f16 with lazy f32
    decode.
  - pg_infer supports models in Microsoft's
    [BitNet b1.58 family](https://arxiv.org/abs/2402.17764) —
    transformers with ternary {-1, 0, +1} weights at 1.58 bits
    per parameter, designed specifically to run on commodity
    CPUs at competitive quality and dramatically lower memory
    and power cost than f16.

Combined, this brings useful inference inside a Postgres backend
without any specialised accelerator.  And it makes the cluster
shape the actual point: a typical HA / DR / read-scale Postgres
deployment has one busy primary plus one or more largely idle
physical replicas plus a fleet of logical subscribers.  Those
replicas already pay for themselves in availability; their CPUs
are idle most of the time.  With pg_infer's remote backend,
`larql-server` runs on the replica hosts and serves model
operators back to the primary's query plans.  The model is
materialised once per host.  The activation cache is shared.
The work happens on capacity you have already paid for.  No
GPU.  No separate inference cluster.  No extra network egress.

## the two backends

  - **`local`** — mmap the vindex directly in each PostgreSQL
    backend.  Simple.  Does not share the f16 decode cache
    across connections.  The right backend for development and
    for clusters where the model is small enough to fit
    comfortably in every backend's working set.

  - **`remote`** — talk to a colocated or networked
    `larql-server` over HTTP/2 or a Unix domain socket.  One
    copy of the model per host, shared activation cache across
    every PG backend, and optional layer-sharded routing
    through `larql-router`.  In-flight remote calls respond to
    `pg_cancel_backend(...)` within roughly 100 ms via a
    polling bridge to PostgreSQL's `InterruptPending` flag.

```sql
-- Register a remote model:
SELECT infer_create_model_remote('m', 'uds:///run/larql.sock');
-- or:
SELECT infer_create_model_remote('m', 'http://server:8080');
```

The walkthrough, GUCs, pgbench scripts, and expected throughput
numbers live in
[`docs/REMOTE_BACKEND.md`](https://codeberg.org/gregburd/pg_infer/src/branch/main/docs/REMOTE_BACKEND.md).

## composing with the rest of the search ecosystem

pg_infer is a *signal*, not a search system.  The interesting
queries combine it with the other search extensions you already
have:

```sql
WITH candidates AS (
    SELECT id, title, body,
           title <~> 'neural architecture search'  AS infer_dist,
           embed <=> '[0.1, 0.2, ...]'::vector     AS vec_dist,
           similarity(title, 'neural architecture') AS trgm_score,
           ts_rank(to_tsvector('english', body),
                   plainto_tsquery('neural architecture')) AS ts_rank
      FROM papers
     WHERE to_tsvector('english', body) @@ plainto_tsquery('neural architecture')
        OR title % 'neural architecture'
     LIMIT 100
)
SELECT id, title,
       (0.4 * (1 - infer_dist) +
        0.3 * (1 - vec_dist) +
        0.2 * trgm_score +
        0.1 * ts_rank) AS combined_score
  FROM candidates
 ORDER BY combined_score DESC
 LIMIT 10;
```

Four search signals — model knowledge, vector similarity, trigram
fuzzy match, full-text relevance — combined in one query, ranked
by a weighted sum, all running through the standard PostgreSQL
planner.  None of the four can be replaced by any of the other
three.

## status, honestly

v0.1.0-alpha.  769+ tests passing.  Tested on PostgreSQL 18.
Apache 2.0.  Built on
[`pgrx`](https://github.com/pgcentralfoundation/pgrx) 0.17.

  - The SQL API may change without notice between releases.
  - There are no production deployments yet.  None.
  - The vindex format is *not* yet frozen.
  - Some compute paths require specific hardware (Apple Metal,
    NVIDIA CUDA when you opt into them; CPU otherwise).

If you want to explore what's possible at the intersection of
transformer-model internals and relational databases, pg_infer is
the place.  If you need a production-ready inference layer for an
existing application *today*, this is not it, and I will not
pretend otherwise.

The repo is at <https://codeberg.org/gregburd/pg_infer>.  Please
also look at Chris Hayuk's [LARQL repo](https://github.com/chrishayuk/larql)
and [`chuk-larql-rs`](https://github.com/chrishayuk/chuk-larql-rs)
— the foundational ideas live there.
