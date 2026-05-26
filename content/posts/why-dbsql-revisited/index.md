+++
title = "why dbsql, twenty-three years later"
date = "2026-09-07"
draft = true
description = "I shelved DBSQL in 2011. The world changed in ways that put it back on the bench in 2026 — for very different reasons than the ones I started with."
[taxonomies]
tags = ["dbsql","sqlite","berkeley-db","databases","sleepycat"]
+++

I wrote the [first DBSQL post](/posts/dbsql) in late 2023.  It covered
the 2002–2011 arc: SQLite, Sleepycat, the Boston Harbor sailboat,
beautiful C, the politics of being a product manager who could not
stop being an engineer, and the eventual handoff into Oracle's
purview.  When I let DBSQL fall dormant after I left Oracle in
2011, I genuinely thought the project was done.

DBSQL 0.4.0 shipped in January 2026.  This post is about why I
came back, what is different now, and what I think the niche is
this time around.

## what I shelved in 2011

The original DBSQL pitch was simple.  SQLite had won the
embedded-SQL market.  Berkeley DB had real durability and real
replication that SQLite did not, and was small enough to live
inside the same kinds of applications.  Slot a SQL92 layer onto
BDB and you have an "embedded SQL with replication" story that
SQLite was not yet trying to tell.

The SQLite that swallowed our market was not the SQLite of 2026.
It had no full-text search.  It had no JSON support.  It did not
ship encryption.  Its locking model was the file-level locking
that LMDB and the BDB family had spent twenty years arguing was
inadequate.  *In that world*, "BDB underneath, SQL on top" was a
real product distinction.

It is not that distinction any more.  SQLite ships
[FTS5](https://www.sqlite.org/fts5.html), JSON1, R-Tree, sessions,
WAL-mode, encryption (via SEE), and a whole ecosystem of
extensions.  For *embedded SQL*, SQLite is not just the right
tool — it is the only tool whose decisions other people end up
copying anyway.

So why come back.

## what changed about the world

Three things that did not exist in 2011 changed the calculus.

First, the [Sleepycat license](https://www.oracle.com/database/technologies/related/berkeleydb-public-license.html)
is unchanged but the AGPL has stopped being scary.  Many of the
applications that wanted "embedded SQL with replication" in 2011
would not touch the Sleepycat license because they could not
defensibly satisfy the source-distribution clause.  In 2026 the
shape of "open core plus commercial" has stabilised; the people
who would not touch a Sleepycat-licensed library in 2011 are
running AGPL code in production today and not losing sleep over
it.  The license is still strong copyleft, but the audience that
panicked when they saw it has moved.

Second, *Berkeley DB itself* is in a stranger place than it was
in 2011.  Oracle has been quiet about it for years.  The community
fork ([libdb](https://github.com/yhirose/libdb), various
distribution maintainers) keeps the lights on.  Meanwhile,
Berkeley DB's transactional, replicating, multi-version btree is
arguably *more interesting* in 2026 than it was in 2011, because
the rest of the open-source storage ecosystem has converged on
LSM trees and forgotten what page-level transactional durability
costs and what it buys you.  A small SQL92 engine that
demonstrates BDB's durability story is a useful artifact in a way
it would not have been when the durability story was the
default.

Third, I started writing
[`bdb-rs`](https://codeberg.org/gregburd/bdb-rs) — a Berkeley DB
in Rust, on a clean re-imagining rather than a port.  The first
real client of bdb-rs is going to want a SQL face on top of it,
because that is the embedded-database story most applications
still want, and DBSQL is the SQL face I have already debugged.
DBSQL 0.4.0 still talks to libdb, but the design points the work
needs to land are the design points that will let it talk to
bdb-rs when bdb-rs is ready.

## what 0.4.0 is actually doing

0.4.0 is small.  It is a re-baselined build system (autotools
plus a Nix flake), a re-baselined test suite, a sweep through
the codebase to remove dead conditional compilation paths, and
a list of changes that were clearly broken in 2011 and which I
am only now getting around to fixing.  It is the version where
I am admitting publicly that I am working on this again rather
than poking at it on flight legs.

Things that are explicitly *not* in 0.4.0:

  - SQL features beyond what 0.3 had.  No window functions, no
    CTEs that we did not already support, no `MERGE`.
  - JSON.  This will land, but it is post-0.5.
  - A vector type.  No.
  - LLM integration.  Definitely no.

Things that are implicitly in the roadmap:

  - bdb-rs as an alternative storage backend, behind a build-time
    selector.
  - Full-text search through trigram indexing, because that is
    where my work in [`pg_tre`](https://codeberg.org/gregburd/pg_tre)
    landed and I would rather not maintain two separate trigram
    code paths.
  - Replication that is exposed as a SQL feature.  BDB has the
    primitives; DBSQL never made them visible to the SQL layer
    in a way that was useful.

## who is this for, honestly

This is the question I owe.  In 2011 the audience was "anyone
who needs embedded SQL with real durability and replication," and
that audience was real.  In 2026 the answer is narrower:

  - **Embedded systems where SQLite's licensing or footprint
    does not fit.**  This is a small number of cases, but they
    exist.
  - **Applications that already use BDB for non-SQL data and
    want to share storage and transactions with a SQL face.**
    Niche, but real, and used to be the original Sleepycat
    customer profile.
  - **Me.**  I want to keep the engineering muscle for "small
    SQL engine on top of an embedded transactional KV" warm.
    DBSQL is the project that lets me do that without having
    to build a whole new SQL parser from scratch.

The third reason is the honest one.  The first two are
defensible.  All three are sufficient for me to keep working on
it in the open.

## the back-link

If you want the long version of how DBSQL got started, the
[2023 post](/posts/dbsql) covers the Sleepycat years.  This post
is the bridge between "shelved at 2011" and "0.4.0 shipped at
2026," and it is mostly here so I can stop being asked the same
five questions on the mailing list.
