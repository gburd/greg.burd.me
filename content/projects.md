---
title: "selected projects"
---

A non-exhaustive list. Things I work on now or recently. Almost
everything below is on [Codeberg](https://codeberg.org/gregburd) with
a GitHub mirror at [github.com/gburd](https://github.com/gburd).

## PostgreSQL extensions

### [pg_mentat](https://github.com/gburd/pg_mentat)
Datomic-compatible Datalog query engine running entirely inside
PostgreSQL. Implements Datomic's data model — immutable facts
(datoms), schema-first attributes, the full Datalog query compiler,
the pull API, time travel, and ACID transactions — accessible from
any PostgreSQL client. Built with [pgrx](https://github.com/pgcentralfoundation/pgrx).
A continuation, in spirit, of [Mozilla's abandoned mentat](https://github.com/mozilla/mentat)
project.

### [pg_infer](https://codeberg.org/gregburd/pg_infer)
A PostgreSQL extension that exposes transformer model knowledge —
gate activations, feature labels, learned associations, embeddings
— as SQL-queryable relations and a custom index access method.
Inference becomes a planner-visible operator the planner can cost,
schedule, and parallelize, not an external service the database
calls. Status: experimental.

### [pg_tre](https://codeberg.org/gregburd/pg_tre)
Native PostgreSQL 18+ index access method for approximate-regex
matching. Three-tier filter funnel (range bloom → sparsemap-backed
trigram postings → per-tuple bloom) with a TRE-library recheck.
Genuine Levenshtein-distance regex with WAL coverage, VACUUM
awareness, and `REINDEX CONCURRENTLY` support.

## Database / query engine work

### [Ra — relational algebra rule system](https://codeberg.org/gregburd/ra)
A query optimization framework built on literate programming,
equality saturation (using `egg`), and differential dataflow.
1,387 transformation rules across logical, hardware (GPU/FPGA/SIMD),
distributed, multi-model, and physical categories — each as a
documented `.rra` file with formal algebra, preconditions, cost
model, and tests. Includes a learned cost model trained with online
execution feedback.

### [DBSQL](https://codeberg.org/gregburd/dbsql)
A small SQL92 layer on top of Berkeley DB. Inspired by SQLite,
diverged in 2003, mothballed for a decade, currently being revived.
Latest: v0.4.0, January 2026.

### [bdb-rs](https://codeberg.org/gregburd/bdb-rs)
Berkeley DB in Rust. Early-stage port; concurrency control and the
on-disk format are the interesting parts.

## Libraries

### [sparsemap](https://codeberg.org/gregburd/sparsemap)
A sparse, compressed bitmap library for C, optimized for workloads
with long runs of consecutive set or unset bits. 16 KB of
consecutive set bits in 8 bytes; worst case (random bits) is a raw
bitmap plus 8 bytes of overhead. Used as the postings layer in
pg_tre.

### [skiplist](https://codeberg.org/gregburd/skiplist)
A header-only, lock-free C skip-list (specifically a *splay-list*:
skip-list with optional adaptive rebalancing). Fraser/Harris marked
pointers, epoch-based reclamation. Implemented entirely in
preprocessor macros — type-specific code generated at compile time.

### [Lime](https://codeberg.org/gregburd/lime)
A runtime-extensible LALR(1) parser generator. Like Yacc/Bison —
but the generated parser can load and unload grammar extensions at
runtime without recompilation. SIMD-accelerated tokenization
(AVX2/NEON). Used for the regex-pattern parser in pg_tre.

### [Hegel](https://codeberg.org/gregburd/hegel)
A universal property-based testing protocol. A Python (Hypothesis)
server speaks to client libraries in Rust, Go, C, and TypeScript
via Unix sockets. One PBT engine, many languages.

## PostgreSQL community infrastructure

### [pg.ddx.io](https://pg.ddx.io/)
A community-facing portal indexing 30 years of PostgreSQL
development: pgsql-hackers and related list archives, the
upstream/master git history, the build farm, the commitfest, plus
the pre-PostgreSQL UC Berkeley archives at
[/m/legacy](https://pg.ddx.io/m/legacy). Backed by an
[Agora MCP server](https://pg.ddx.io/mcp/) exposing 50+ tools for
git/email/code-intelligence to AI agents.

## Older / fork lineage

### [mentat](https://github.com/gburd/mentat)
Original Rust port / continuation of Mozilla's mentat embedded
Datalog store. Now superseded by pg_mentat for most uses.

### [Pure language LLVM Orc port](https://codeberg.org/gregburd/pure-lang)
Albert Gräf's term-rewriting language with an LLVM JIT backend.
Updated to current LLVM Orc API.

### [pcompress](https://codeberg.org/gregburd/pcompress)
Maintenance / modernization of Moinak Ghosh's archiver. Variable-
block dedupe, polynomial fingerprinting, MinHash similarity,
adaptive compression by file type. v4.x build system + multi-
architecture support.

## Infrastructure / forks

### [Maki (fork)](https://github.com/gburd/maki)
A context-efficient AI coding agent, originally by Frostbeard.
Tree-sitter indexing, sandboxed code execution, weak/medium/strong
subagent selection. My fork pulls in changes for [TODO: write up
divergence reasons].
