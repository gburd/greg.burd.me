+++
title = "pg_fts: BM25 full-text search as a real Postgres index AM"
date = "2026-08-21"
draft = true
description = "A native fts index access method that keeps the corpus statistics BM25 needs inside the index, so ranking, phrase, boolean, and count all come from one operator with no heap recheck."
[taxonomies]
tags = ["postgres","indexing","extensions","storage"]
+++

PostgreSQL's built-in full-text search is good, and it has a hole in
the middle of it.  `tsvector`/`tsquery` over a GIN index gives you
stemming, stopwords, boolean and phrase queries, and it is battle-
tested.  What it does not give you is *relevance ranking that scales*.
The `ts_rank` family computes its score from the `tsvector` in the
heap tuple, which means ranking a query means fetching and scoring
every matching row.  On a large corpus that is the difference between
a search box that feels instant and one that does not.

The reason is that GIN doesn't store what a good ranking function
needs.  [BM25](https://en.wikipedia.org/wiki/Okapi_BM25) — the ranking
function Lucene, Elasticsearch, and every serious search engine uses —
needs three corpus statistics: how many documents there are, the
average document length, and for each query term, how many documents
contain it.  It also needs, per posting, the term frequency and the
document length.  GIN keeps none of that.  So if you want BM25 in
Postgres you have to reconstruct it at query time, which defeats the
purpose.

[`pg_fts`](https://codeberg.org/gregburd/pg_fts) is a PostgreSQL
extension that fixes this by building a real index access method — an
inverted index called `fts` — that stores exactly what BM25 needs.  The
document count and average length live in the index metapage; term
frequency and document length live in the posting lists.  Ranking is
answered from the index, with no heap recheck.

## one operator, many query shapes

The design goal was that a single index answers the questions a search
box actually asks, rather than making you keep four different indexes
in sync.  `pg_fts` exposes two operators:

```sql
-- match: boolean, phrase, NEAR, prefix, fuzzy, regex — all through @@@
SELECT id FROM docs WHERE body_fts @@@ to_ftsquery('postgres NEAR/3 replication');

-- ranked top-k: relevance-ordered, no Sort node
SELECT id FROM docs
ORDER BY body_fts <=> to_ftsquery('write ahead log')
LIMIT 10;
```

The `@@@` operator drives a bitmap scan for boolean, phrase, NEAR,
prefix, fuzzy, and regex matching.  The `<=>` operator drives a KNN
index scan for ranked retrieval — `ORDER BY ... LIMIT k` with no sort
step, because the index returns rows in relevance order directly.
Under the hood the ranked path is a block-max WAND / MaxScore
implementation with lazy per-column posting decode, so it skips the
term-frequency and document-length columns entirely when a query
doesn't need them.

Ranking is Okapi BM25, with the usual variants (Lucene, Robertson,
ATIRE, BM25+, BM25L) and BM25F multi-field weighting available.
Tokenization reuses PostgreSQL's own Snowball stemming and language
configurations, so you get the same linguistic behavior you already
know, with Unicode-correct lowercasing in UTF-8 databases.

## it behaves like a Postgres index

The thing that makes a custom access method safe to deploy is not the
clever query algorithm — it is the boring infrastructure.  `pg_fts`
does all of it.  Every page mutation goes through `GenericXLog`; there
are 65 WAL cycles in the access-method code and zero raw writes, which
means crash recovery and streaming replication just work.  Segments are
immutable and built invisibly, then published atomically by a single
metapage WAL record.  Freed pages are stamped with a transaction-id
horizon and not reused until no snapshot can reference them — the same
trick core B-tree uses to be safe on standbys.  `CREATE INDEX
CONCURRENTLY` and `REINDEX CONCURRENTLY` work, because concurrent
writes route to a small pending list that is immediately searchable.

The storage architecture is Lucene/Tantivy-shaped: immutable segments,
each with a term dictionary, frame-of-reference bit-packed posting
blocks, an optional per-segment trigram tier, and a tombstone bitmap
for deletes.  New rows land in a pending buffer; a size-tiered, leveled
merge (think LSM, or HanoiDB) with bounded fan-in keeps the segment
count in check under continuous ingestion, dropping tombstoned docs as
it goes.  Crash-recovery, streaming-replication, and corruption-
tolerance are covered by TAP tests: kill the server mid-write and WAL
replay reproduces the exact query answers; corrupt a page and the
worst case is a wrong *count* with a warning, never a crash.

## the numbers, including where it loses

I benchmarked 1.3.0 against three other Postgres BM25 extensions —
VectorChord-bm25, Timescale's pg_textsearch, and ParadeDB's pg_search
(which is Tantivy in an extension) — on 2 million Wikipedia articles,
on an EC2 `r6id.4xlarge` with local NVMe, PostgreSQL 17.  I am going to
give you the parts where `pg_fts` loses as well as where it wins,
because a benchmark that only shows the wins is marketing.

Where it wins: **ranked retrieval on rare and mid-frequency terms**,
the common case for real search.  8.5 ms for a rare term top-10, 4.6 ms
for a mid-frequency term — the fastest in the field on those.  And it
is the *only* one of the four that answers index-native `count(*)`,
phrase, boolean, and prefix/fuzzy/regex all through one operator; the
others are ranking-only or miss query classes.

Where it loses: **index size** and **common-term `count(*)`**.  The
`pg_fts` index is 1.9x to 2.9x larger than the smallest competitor —
VectorChord fits the same corpus in 1,449 MB where `pg_fts` needs
around 4,200 MB in that comparison.  That gap is the posting codec, and
it is a known, tracked optimization target rather than a mystery.  And
common-term `count(*)` — counting how many docs contain a word that
appears in a third of the corpus — was genuinely bad.

That last one is the interesting story.  In 1.2.2, counting a term with
a document frequency around 735,000 took **756 ms**, because it
decoded the whole posting list.  In 1.3.0 there is a fast path that
answers the count from the dictionary's document-frequency entry
without decoding anything, and the same query is **3.0 ms** — about
**250x** faster.  A plain-column index that used to fall back to a
bitmap scan and take ~19 seconds now uses the pushdown and takes 3 ms.
The gap you find by benchmarking honestly is the gap you fix in the
next release.

## operating it

Two maintenance knobs.  `fts_merge()` coalesces segments and drops
tombstones to bound the segment count; it runs implicitly during heap
`VACUUM` and reclaims logical space but not physical file space.
`fts_vacuum()` is the full compaction — like `VACUUM FULL`, it takes an
`AccessExclusiveLock`, truncates the file, and converges to a stable
floor in one call (a churned index in testing went from 143 MB to 60
MB, idempotently).  Build memory is bounded to roughly `shared_buffers
+ (parallel workers + 1) x 2 x maintenance_work_mem`, which matters
because an earlier version could balloon to ~19 GB on a high-vocabulary
corpus before that ceiling existed.

For anyone thinking about running this on a managed service: the
correctness blockers are closed.  The maintenance functions refuse to
run during recovery, require index ownership, and the content-exposing
functions are revoked from `PUBLIC`.  Build-time corpus statistics
exclude recently-dead tuples so a horizon-pinned snapshot can't skew
the counts.  What remains open is external review and validation on
storage-separated backends, which are integrator concerns, not
correctness ones.

## status

1.3.0, PostgreSQL License, built and gated in CI against PostgreSQL 17
and 18 with a 90% line-coverage floor, plus AddressSanitizer,
UndefinedBehaviorSanitizer, fuzz, and property-based test builds.  The
repo is at <https://codeberg.org/gregburd/pg_fts>, and the benchmark
harness and full four-way results are in `bench/` so you can reproduce
the numbers above, unflattering ones included.
