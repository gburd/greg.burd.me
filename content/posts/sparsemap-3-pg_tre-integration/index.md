+++
title = "sparsemap, part 3: powering pg_tre's trigram postings"
date = "2026-06-15"
draft = true
description = "Why sparsemap's best case turns up everywhere in approximate-regex postings lists."
[taxonomies]
tags = ["sparsemap","postgres","pg_tre","indexing","series:sparsemap"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

sparsemap is the trigram postings layer in pg_tre's three-tier filter funnel.
The reason it works there isn't an accident — postings lists in real text
indexes hit sparsemap's best case (long runs of contiguous TIDs) far more
often than the literature suggests, because rows that share a trigram tend to
cluster on disk.

## outline

- [ ] Recap of pg_tre's three-tier funnel (range bloom → trigram postings →
      per-tuple bloom). One sentence each.
- [ ] Why postings lists tend to be long-run-heavy in practice (clustering,
      append-mostly insertion patterns).
- [ ] Measured size on a real corpus (pull numbers from `~/ws/pg_tre/bench/`).
- [ ] The sparse-encoding fallback when clustering breaks down.
- [ ] Honest accounting of the worst case.

## source material

- `~/ws/pg_tre/src/postings.c` — the integration point.
- `~/ws/pg_tre/bench/` — real numbers.

## open questions for me to answer

- What corpus did I benchmark on? Gutenberg? Postgres archives? Both?
- Compare to GIN posting lists' compression — is this a fair comparison?
