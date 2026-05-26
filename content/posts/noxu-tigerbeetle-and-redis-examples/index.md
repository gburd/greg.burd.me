+++
title = "Noxu DB: an embedded transactional KV store, with TigerBeetle and Redis flavored examples"
date = "2026-05-26"
draft = true
description = "An embedded ACID key-value engine in Rust, plus example workloads that mimic TigerBeetle ledger semantics and Redis cache semantics in one harness."
[taxonomies]
tags = ["noxu","databases","rust","embedded","tigerbeetle","redis"]
+++

[Noxu DB](https://codeberg.org/gregburd/noxu) is the embedded transactional
key-value engine that I have wanted to write for years, and now have.
B+tree on disk.  Append-only write-ahead log with checkpointing.  Record-
level locking with deadlock detection.  Flexible Paxos-based master-replica
replication.  ARC and CART eviction next to LRU and CLOCK.  Apache 2.0 or
MIT, your pick.  Roughly nineteen Cargo crates, almost all with `unsafe`
forbidden, the exceptions documented inline.

It is not a server.  It is a library that you link into your application,
much like Berkeley DB or LMDB or RocksDB.  I am explicit about that because
there are days when "embedded" is a marketing word and I want it to mean
the thing it used to mean.

This post is about why the *examples* matter as much as the engine.  Noxu
ships three reference workloads in `examples/`:

  - `cash` — a TigerBeetle-flavoured double-entry ledger.
  - `cask` — a Redis-flavoured key-value cache.
  - `ftdb` — a small full-text indexer.

Three workloads, one harness, comparable numbers.  This is the thing that
no other benchmark suite I know of will give you.

## why three examples that look so different

The argument goes like this.  Most database benchmarks pick one workload
shape and live there.  TPC-C is a transactional retail-ish OLTP shape.
YCSB is a Zipfian point-read shape.  HammerDB is TPC-C plus TPC-H plus
some MariaDB targeting.  Each is internally consistent.  None of them
will tell you whether a system that is good at one shape is good at
another, because nothing in their methodology asks the same engine to
serve both shapes back to back.

That answer matters.  Real applications do not get to pick one shape.
A single product service is doing inventory updates *and* serving a hot
cache *and* full-text search over the catalog, against the same
underlying store, in the same process.  A benchmark that asks how the
engine does on one of those tells you a third of what you wanted to
know.

## `cash`: the ledger shape

TigerBeetle's contribution, as I read it, is to insist that financial
double-entry is a separate workload class.  Multi-account atomicity is
the property: a transfer that debits A and credits B has to apply both
sides atomically or neither.  The append-only ledger is the storage
shape: rows are immutable once written, audit reads dominate the read
mix, hot keys (current balances) get hammered concurrently, and the
working set of "account" rows is many orders of magnitude smaller than
the working set of "transfer" rows.

`cash` mimics those properties on top of Noxu.  It uses one database
for accounts and a second database for transfers, both under a single
transaction so that a failed transfer does not leave a partial debit.
It uses Noxu's record-level locking to drive contention through the
"hot account" path the way a real ledger would, and it uses cursor
iteration over the transfer database to model the audit-log read.

The TigerBeetle people have done a much more rigorous job of
characterizing this workload than I am about to.  The `cash` example
is not a competitor to TigerBeetle — TigerBeetle is its own engine
optimised end-to-end for ledgers and runs in a different operational
shape.  `cash` exists so I can ask whether Noxu degrades gracefully
when handed a ledger workload alongside the other two examples in the
same process.

## `cask`: the cache shape

Redis-shaped traffic looks nothing like a ledger.  The working set is
hot.  Reads outnumber writes, but writes are still a non-trivial
fraction.  Eviction matters because the data set never fits in
memory.  Latency is what people measure; throughput is what they
think they are measuring.  The data items are small, mostly under a
kilobyte, and the access distribution is heavily Zipfian.

`cask` exercises the parts of Noxu that the cache workload stresses:
the LRU evictor with a configured memory budget, the BIN-delta write
path that keeps update I/O small, and the cursor-free point-lookup
fast path.  It does not pretend to be a Redis replacement (Redis is
an in-memory engine with persistence as an afterthought; Noxu is a
disk engine with caching).  It does run the workload shape Redis
users actually have, against an engine designed for durability,
which is exactly the comparison that nobody else has set up cleanly.

## `ftdb`: the search shape

The third example is a small full-text indexer that maintains a
posting list per term, with cursor scans over the postings and
intersection at query time.  This is the shape where the lock manager,
the tree-rebalancing path, and the cursor I/O path get exercised
together against a write workload that is bursty rather than steady.

Three examples is enough to tell three different stories about the
same engine without any of the stories being a strawman.

## what comparable means here

"Comparable" is a load-bearing word and I want to define it.  The
three examples share:

  - The same Noxu environment configuration (cache budget, log
    file size, durability policy).
  - The same hardware and OS tuning.
  - The same measurement window (a stabilization period followed
    by a steady-state collection period).
  - The same metric definitions for latency percentiles
    (p50/p95/p99 over 1-second buckets).

What they do *not* share is the workload shape, on purpose.  The
point is not to declare a winner between ledger and cache and search.
The point is to be able to point at a curve and say "the engine
behaves like *this* under ledger contention, like *that* under cache
churn, and like *the other thing* under indexed scans."  Three curves
out of one engine.

## what `cash` and `cask` do not measure

I will say plainly: the `cash` example does not produce a number you
can put next to a TigerBeetle benchmark.  TigerBeetle runs as its own
process, on its own data path, with optimisations that an embedded
KV engine cannot match by design.  The `cask` example does not
produce a number you can put next to a Redis benchmark either, for
similar reasons.  These examples exist to characterise *Noxu*, not
to embarrass Redis or TigerBeetle.

If you want a number that goes "Noxu does X TPS on workload Y" with
the methodology written down, the
[`benches/`](https://codeberg.org/gregburd/noxu/src/branch/main/benches)
directory has those, and the harness keeps growing.

## status

v1.3.0.  Apache 2.0 or MIT.  19 crates, almost all with zero `unsafe`,
exceptions enumerated in the README.  The core engine pulls in a
small set of well-known dependencies (`parking_lot`, `thiserror`,
`bytes`, `crc32fast`, `memmap2`, `lru`); replication and observability
extras pull in more only when their Cargo features are enabled.

Replication wire protocol has no authentication today and must be
deployed across a trusted network boundary.  The May-2026 security
review is documented in
[`docs/src/operations/known-limitations.md`](https://codeberg.org/gregburd/noxu/src/branch/main/docs/src/operations/known-limitations.md).
This is the kind of thing I want to be loud about; "ships
authentication" is on the roadmap and the protocol design is being
worked on in the open.

The repo is at <https://codeberg.org/gregburd/noxu>.  Issues, patches,
and benchmark contributions welcome.
