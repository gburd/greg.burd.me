+++
title = "pg_tre: approximate regex as a real Postgres index AM"
date = "2026-08-24"
draft = true
description = "A native USING tre index AM with WAL coverage, three-tier filtering, and Levenshtein-distance recheck."
[taxonomies]
tags = ["postgres","pg_tre","indexing","regex","extensions"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

PostgreSQL has trigram and full-text search, but neither does real
Levenshtein-distance regex. pg_tre is a native `USING tre` index AM backed
by Ville Laurikari's TRE library, with a three-tier funnel that makes
`(error){~1}.*(42[0-9]){~0}` sub-millisecond on tens of thousands of rows.
This post explains why a *real* index AM is the right shape and walks
through the funnel design.

## outline

- [ ] What "approximate regex" means and why current Postgres extensions
      don't do it.
- [ ] Three-tier funnel: range bloom → trigram postings (sparsemap-backed)
      → per-tuple bloom. Per-stage cost / precision tradeoff.
- [ ] WAL coverage and rmgr id 140 — what owning a custom rmgr buys you
      (crash recovery, streaming replication, REINDEX CONCURRENTLY).
- [ ] Lime LALR(1) parser for the pattern syntax.
- [ ] Honest performance numbers (cite `bench/`).

![three-tier filter funnel](funnel.svg)

## source material

- `~/ws/pg_tre/README.md` and `~/Desktop/_/announce-pg_tre.txt`.
- `~/ws/pg_tre/src/` — the AM implementation.
- TRE library docs: <https://github.com/laurikari/tre>.

## open questions for me to answer

- The personal arc: my time at Humio (log-analytics workloads, approximate
  matching at scale) is the *idea* lineage. What can I say publicly about
  that lineage without violating any post-employment restrictions?
- Decide whether to mention rmgr id 140 squat reservation rules — there's
  ongoing pgsql-hackers discussion.
