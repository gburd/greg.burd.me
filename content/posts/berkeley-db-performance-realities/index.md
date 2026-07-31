+++
title = "Berkeley DB performance realities"
date = "2026-08-14"
draft = false
description = "The revived engine is 16x slower than WiredTiger on in-cache reads at high thread counts, and it regresses across NUMA sockets. Here is why, what is already fixed, and the plan for the rest."
[taxonomies]
tags = ["berkeley-db","performance","storage","concurrency","benchmarking"]
+++

The [first](/posts/reviving-berkeley-db/) two
[posts](/posts/how-do-you-trust-a-30-year-old-storage-engine/) in this
series were about getting Berkeley DB back on a permissive license with
a modern build, and about the testing that decides whether you can
trust it with data.  This one is about the thing that keeps me up at
night, which is that on the workloads that matter most, it is currently
slow, and I want to be honest about how slow before I talk about fixing
it.

## the measurement

I benchmarked the revived engine against WiredTiger — the storage
engine underneath MongoDB, and a fair modern point of comparison — on a
two-socket bare-metal box: 128 vCPUs, two NUMA nodes, a terabyte of
RAM, local NVMe in RAID0.  Same harness, same YCSB-style workloads,
data on real NVMe rather than tmpfs, cache sized from half the working
set up to 1.5x.  The results are not pretty.

On purely in-cache reads — the easiest workload there is, everything in
the buffer pool, no I/O — Berkeley DB peaks around **280K ops/sec at 8
threads and then goes *backwards*, down to about 53K ops/sec at 128
threads.**  WiredTiger does about **1.36M ops/sec at 16 threads and
holds it out to 128**.  That is roughly a **16x** gap at the top, and
the shape is the real problem: Berkeley DB negatively scales.  Adding
cores makes it slower.

On a Zipfian hot-key workload — a few keys getting most of the traffic,
which is what real caches look like — it is worse, past 40x.  On cold
reads that force eviction from NVMe, 5x to 28x depending on threads.
Writes, read-modify-write, and bulk load are 5x to 12x slower.  And
across NUMA sockets the engine doesn't just fail to scale, it
**regresses 41%** versus pinning everything to a single node.

There is one bright spot and one trap.  The bright spot: single-socket,
low-thread-count, Berkeley DB is competitive.  The trap: the default
API pattern of sharing one `DB` handle across threads is about a 7x
penalty versus a handle per thread, and it is the pattern most existing
code uses.

## why it negatively scales

Negative scaling is always the same story: threads fighting over shared
cache lines.  The more cores you add, the more coherency traffic you
generate keeping those lines in sync, until you are spending all your
time bouncing cache lines between sockets instead of doing work.

In Berkeley DB the hot shared lines are in the buffer pool.  Every
single read of a page — including the root and internal B-tree pages
that *every* query touches — does three writes to shared memory: it
atomically bumps the buffer's pin count, it takes a read latch on the
buffer, and it writes the buffer's priority field to update the LRU
position.  Three shared-memory writes per page read, on the pages every
thread reads, on a two-socket machine.  That is a coherency firestorm.
The lock manager's partitions, which are supposed to spread contention,
are not fine-grained enough at 128 threads, so hot keys serialize
there too.  And every shared region — buffer pool, lock table, log,
transaction table — lives on one NUMA node, so half your threads are
paying remote-memory latency for every access.

None of this is a bug.  It is a design tuned for the machines of the
late 1990s, where you had a handful of cores and one memory domain, and
where an atomic increment was cheap because there was nobody to
contend with.

## what is already fixed

I have started at the top of that list, because the buffer pool is on
every read path and therefore worth the most.

The first change deleted two of the three shared writes.  The LRU
priority field — that per-read write to shared memory, plus a periodic
O(cache-size) sweep to renormalize it — is gone, replaced with a
two-bit hot/cool/cold state and a referenced bit living in the
buffer's existing flags word.  This is the classic clock/second-chance
eviction trick, and besides removing a shared write per read it makes
the cache scan-resistant: a big sequential scan no longer evicts your
hot working set.

The second change caches a private, per-handle copy of the B-tree root
page and validates it against the real page with a lock-free
log-sequence-number check.  When the root hasn't changed — which is
almost always — the descent starts without touching the shared root
page at all.  That measured **+12% to +21%** on cached reads at 4 to 24
threads on a smaller box.  I also built the more aggressive version that
shadows deeper internal pages too, measured it carefully, and found it
was a wash: the deeper internals are under 1% of the read-path cost, so
the extra machinery bought nothing.  That negative result is worth as
much as the positive one — it told me where *not* to spend effort.

## the plan for the rest

The sequence from here, roughly in order of expected payoff:

  - **Latch-free buffer-header lookup.**  Replace the read latch on the
    buffer hash bucket and the per-page lock with an optimistic,
    seqlock-style read that only falls back to locking when a page is
    actually changing underneath it.  This kills the last of the three
    shared writes on the read path.

  - **Group commit and parallel logging.**  Right now every commit
    takes a single global log-region mutex and does its own `fsync`.
    Batching the `fsync` across concurrent committers and pipelining
    log-sequence-number assignment shortens the one lock that every
    write serializes on.

  - **A modern lock manager.**  NUMA-local partitions, latch-free read
    and intention locks, so hot keys stop serializing.

  - **Concurrent sharded eviction and non-stalling checkpoints.**
    Multiple background eviction workers instead of eviction blocking
    on a synchronous page flush in the foreground.

  - **Cache-line-aware layout.**  Pad and align the hot fields —
    mutexes, buffer headers, counters — so unrelated threads stop
    false-sharing a cache line, and shard the statistics counters
    per-CPU.

  - **Async I/O and prefetch** via `io_uring`, `kqueue`, and IOCP
    behind a portable abstraction, so eviction and read-ahead stop
    stalling on synchronous I/O.

  - **NUMA-aware, per-node sharded regions.**  Partition the buffer
    pool per NUMA node and place each region on local memory.  This is
    the multiplier, and it comes *last* — deliberately.  Making the
    per-core fast path cheap first means the NUMA work has less
    contention to distribute; doing it in the other order just spreads
    a slow path across more memory domains.

Further out there is an adaptive LSM access method and some
single-process tricks — LeanStore-style pointer swizzling for resident
pages, epoch-based reclamation for optimistic readers — but those are
research, not schedule.

## why publish the bad numbers

Because the alternative is worse.  A revived database project that only
publishes the workloads where it wins is not a serious project.  The
16x gap on in-cache reads and the 41% NUMA regression are the honest
starting line, they are measured on a real machine with a real
competitor, and they are the reason the roadmap is ordered the way it
is.  The B-tree, the recovery, and the durability are sound — the two
earlier posts are about that — and none of the contention above is
fundamental.  It is 1990s assumptions about hardware baked into
hot-path code, and hardware assumptions are the most fixable kind of
slow.

The roadmap, the benchmark harness, and the design notes are all in the
open at <https://github.com/berkeleydb/libdb>.  If you like making
databases scale on many-core hardware, this is a target-rich
environment.
