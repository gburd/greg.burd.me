+++
title = "what I do now: full-time on PostgreSQL"
date = "2026-05-26"
draft = true
description = "The resume changed and I want to be loud about it. C and Rust, full-time, on PostgreSQL open source and a small family of extensions."
[taxonomies]
tags = ["about","career","postgres"]
+++

This is a "now page" post.  The kind of thing where I tell the
internet what I am doing in 2026 so that when somebody asks the
question I can point at a URL.

## the short version

I write C and Rust full-time on PostgreSQL.

## the medium version

By day I am a senior engineer at Amazon Web Services on the
Amazon DocumentDB team.  The opinions on this site are mine, not
theirs.  I do not write about my employer's internals here, and
this post is not the exception.

By every other metric — hours, repos, mailing-list activity,
extension family size — my centre of gravity has shifted to
PostgreSQL open source.  The last time the resume on this site
told the truth was around 2023, when "rust" still appeared in the
*acquiring* section.  Two years later I have shipped enough Rust
on `pgrx` that the section labels are reversed.  Updating the
resume took a long time partly because I am bad at it and partly
because I wanted to be honest about what changed.

## the projects

The work splits into roughly three buckets.

**Database internals (Rust).**  An embedded transactional KV
store ([Noxu DB](https://codeberg.org/gregburd/noxu)) written in
about nineteen Cargo crates with almost zero unsafe.  A
re-imagining of Berkeley DB in Rust
([bdb-rs](https://codeberg.org/gregburd/bdb-rs)).  A relational-
algebra rule system ([Ra](https://codeberg.org/gregburd/ra)) with
1 387 transformation rules, equality saturation through
[`egg`](https://github.com/egraphs-good/egg), differential
dataflow for incremental statistics, and a learned cost model.

**PostgreSQL extensions (Rust on `pgrx`).**
[`pg_mentat`](https://github.com/gburd/pg_mentat) for Datomic-
compatible Datalog.
[`pg_infer`](https://codeberg.org/gregburd/pg_infer) for
transformer-model knowledge as SQL relations.
[`pg_tre`](https://codeberg.org/gregburd/pg_tre) for approximate
regex as a real index AM.
[`pg_turbovec`](https://codeberg.org/gregburd/pg_turbovec) for
2-/4-bit quantized vector search.  All are Apache 2.0 or MIT,
all are designed to compose with each other and with the broader
ecosystem.

**PostgreSQL upstream (C).**  A patch series adding multiple
named buffer pools with pluggable replacement algorithms,
including ARC and CAR now that the IBM patent family has
expired.  A patch series adding a RECNO-style table access
method backed by an UNDO subsystem.  Smaller things in support:
HOT-indexed updates, a left-right lock primitive, transactional
file operations.  All of these are described in
[wiki.postgresql.org](https://wiki.postgresql.org/) design pages
and in pgsql-hackers threads.

**Community infrastructure (Go and Rust).**  An
[Agora](https://pg.ddx.io/) MCP server that indexes thirty years
of PostgreSQL development — pgsql-hackers archives, the
upstream/master git history, the build farm, the commitfest, and
the pre-PostgreSQL UC Berkeley archives at
[`/m/legacy`](https://pg.ddx.io/m/legacy) — and exposes it as a
set of tools your AI agent can call.  Built on top of
[public-inbox](https://public-inbox.org/) for the mailing-list
side and on `git2` plus `tree-sitter` for the code side.

## the supporting libraries

Most of the above sits on top of small libraries that earn their
keep across multiple consumers:

  - [`sparsemap`](https://codeberg.org/gregburd/sparsemap) — a
    sparse, compressed bitmap library used as the trigram
    postings layer in `pg_tre` and as the visibility-map shape
    candidate in some of the buffer-pool work.
  - [`skiplist`](https://codeberg.org/gregburd/skiplist) — a
    header-only, lock-free C skip-list (specifically a splay-
    list) used wherever the buffer manager wants ordered
    concurrent access without a lock.
  - [`Lime`](https://codeberg.org/gregburd/lime) — an LALR(1)
    parser generator with runtime grammar extensions.  Used by
    `pg_tre`'s pattern syntax and by a slow-burning project to
    make Postgres's SQL grammar pluggable.
  - [`Hegel`](https://codeberg.org/gregburd/hegel) — a universal
    property-based-testing protocol so I can write
    Hypothesis-quality property tests in Rust, Go, C, and
    TypeScript with shrinking that actually works.

## what I am available to talk about

  - PostgreSQL extension development (especially with
    [`pgrx`](https://github.com/pgcentralfoundation/pgrx)).
  - Buffer manager internals and replacement algorithms.
  - Embedded transactional KV stores in Rust.
  - The mailing-list-as-data primitive and how to use it without
    reinventing public-inbox.
  - Approximate regex, trigram indexing, and adjacent shapes.
  - Vector search, specifically when *not* to use HNSW.
  - The Datomic data model in 2026.
  - Why an open-source PostgreSQL extension family is the right
    place to put new database ideas in the year 2026.

## what I am *not* available for

  - Anything that requires me to write about what I do for my
    employer.  The line is bright and stays bright.
  - "Generative AI as a magic SQL-completion box" essays.  I am
    happy to talk about model internals as data, which is what
    `pg_infer` is.  I am not happy to talk about prompts.

## elsewhere

Code lives at [Codeberg](https://codeberg.org/gregburd) (primary)
and [GitHub](https://github.com/gburd) (mirror).  Mailing-list
and code-archaeology tooling at [pg.ddx.io](https://pg.ddx.io/).
Toots at
[@gregburd@mastodon.social](https://mastodon.social/@gregburd).
Email is `greg@burd.me`.

There are four children in this house who are amazing,
demanding, and way too much fun to ignore.  Email is the most
reliable way to reach me; I will get back to you when I can.
