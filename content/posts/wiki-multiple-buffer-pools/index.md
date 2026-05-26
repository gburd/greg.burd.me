+++
title = "multiple buffer pools: partitioning shared_buffers by workload"
date = "2026-11-16"
draft = true
description = "PostgreSQL's clock-sweep is a single policy applied uniformly. Multiple buffer pools let us pick the right replacement algorithm per relation — including ARC, now that the patent has expired."
[taxonomies]
tags = ["postgres","postgres-wiki","buffer-manager","series:postgres-wiki"]
+++

PostgreSQL has used a clock-sweep buffer replacement algorithm since
8.1, when Tom Lane redesigned the buffer manager to remove the
monolithic `BufMgrLock`.  Clock sweep is simple, has low per-
operation overhead, scales well on multi-core systems, and has been
quietly correct for nearly twenty years.

It also cannot tell the difference between a frequently-accessed
index root page and a sequential-scan page that will never be re-
read again, because *one policy is applied uniformly to every page
in `shared_buffers`*.  Robert Haas demonstrated the consequence
[in 2011](https://www.postgresql.org/message-id/CA+TgmoZhXDEanouGJDTnsfhqrt7fe071VJTKxvR7qO=vjt76aQ@mail.gmail.com):
on a workload that dragged a sequential scan through a table, only
96 of the 14 286 buffers belonging to that table were retained in
cache, despite over 37 000 *unused* buffers being available
elsewhere in shared memory.

The patch series I am working on fixes the uniformity assumption.
The mechanism is *named buffer pools*, each with its own
replacement algorithm, sized independently, populated by relations
that opt in via a `buffer_pool` reloption.  The full design is on
the [Multiple Buffer Pools](https://wiki.postgresql.org/wiki/Multiple_Buffer_Pools)
wiki page; this post is the public-facing version.

## the shape of the change

The cluster's `shared_buffers` is partitioned into named pools.
Each pool has:

  - A name (`DEFAULT`, `hot_data`, `analytics`, …).
  - A size, in bytes or buffers.
  - A replacement algorithm, picked from a small ecosystem of
    contrib extensions plus three built-in special-purpose
    routines.
  - Its own background trickle-writer worker for dirty-page
    flushing.

Tables and indexes are routed to a pool via a reloption:

```sql
CREATE TABLE events (
    id      bigserial primary key,
    ts      timestamptz not null,
    payload jsonb
) WITH (buffer_pool = 'hot_data');
```

TOAST overflow data routes to a different pool via
`overflow_buffer_pool`, on the observation that TOAST access
patterns are write-heavy and read-cold and want a different
eviction shape from the main relation.

Pool metadata lives in a new `pg_bufferpool` system catalog and is
recreated automatically on server restart.  Pools are created,
resized (drop-and-recreate), renamed, and dropped via SQL DDL.

## six replacement algorithms ship as contrib

The framework is a thin vtable on top of the existing buffer
manager.  When the `DEFAULT` pool runs clock-sweep — the
configured default — the framework's hot path is one indirect
call per `StrategyGetBuffer`, and the cost of that indirect call
is in the noise on the benchmark sweeps I have run.  The cost of
running an *alternative* algorithm comes from the algorithm's own
bookkeeping, which is exactly the cost you wanted to pay when you
asked for a different algorithm.

The contrib extensions ship the following:

  - **ARC** — Adaptive Replacement Cache (Megiddo and Modha,
    [FAST 2003](https://www.usenix.org/legacy/event/fast03/tech/full_papers/megiddo/megiddo.pdf)).
  - **CAR** — Clock-with-Adaptive-Replacement, the lock-light
    variant (Bansal and Modha, [FAST 2004](https://www.usenix.org/event/fast04/tech/full_papers/bansal/bansal.pdf)).
  - **LIRS** — Low Inter-reference Recency Set (Jiang and Zhang,
    [SIGMETRICS 2002](https://web.cse.ohio-state.edu/hpcs/WWW/HTML/publications/papers/TR-02-6.pdf)).
  - **LIRS2** — also known as RCRD; Jiang's later refinement.
  - **LRU** — yes, plain LRU; for measurement and as a reference
    point.
  - **OSIC** — Once-and-Stale-Insertion-Cost; my own variant
    targeted at mixed read/write workloads where the
    insertion-cost signal is noisy.

Plus three core-built-in routines for special-purpose pools:

  - **KEEP** — never evicts.  For pinning a small hot working
    set in memory.  The page sits there until it is unloaded
    explicitly.
  - **RECYCLE** — one-chance clock sweep that replaces the
    per-backend ring buffers used for sequential scans, VACUUM,
    and bulk writes.  Generalises Tom Lane's 2007
    `BufferAccessStrategy` ring buffers into a shared, named
    pool.
  - **JAM** — accelerated-decay clock tuned for the write-heavy,
    read-few access pattern of TOAST overflow data.

## the ARC question, addressed honestly

Anybody who has been following PostgreSQL's buffer-manager
discussion for more than a few years knows there is a story
about ARC.  In 2003 Jan Wieck implemented ARC for PostgreSQL
7.4/8.0.  In early 2005 the community learned of IBM's pending
patent (US 6 996 676, granted February 2006), and the
implementation was removed.  Tom Lane developed a 2Q replacement
as a bridge, then designed the clock-sweep algorithm that has
been in use since.

The IBM patent family reached its 20-year statutory term on
**February 22, 2024** and has expired.  Sun Microsystems' related
US 7 469 320 — covering work that had been shipping for years
inside ZFS under the CDDL — is similarly out of force.  Ben
Manes, who maintains the [Caffeine](https://github.com/ben-manes/caffeine)
cache library, has long argued that the CDDL ZFS implementation
amounts to authoritative public-domain prior art; that argument
is now bolstered by the patent expiry.  The wiki page has the
full citation trail.

I am not a lawyer.  Reviewers and downstreams should confirm
with their own counsel before relying on that conclusion in
their jurisdiction.  But the patent posture that made ARC
unsafe to ship in PostgreSQL between 2005 and 2023 has changed,
and the community deserves an ARC implementation that has been
designed and tested against the buffer-manager primitives we
actually have today.  The implementation in `contrib/pg_bp_arc`
follows the pseudocode in the FAST 2003 paper and was cross-
checked against Caffeine's reference `ArcPolicy.java`; the
Apache 2.0 attribution is reproduced verbatim per the grant.

## why this matters now

Three forces converge.

First, RAM is large enough that picking the wrong replacement
policy hurts measurably.  When `shared_buffers` was 128 MB,
the working set fit and replacement policy did not matter much.
At 64 GB or 256 GB, the wrong eviction decision evicts pages
that would have been read back ten seconds later.

Second, NUMA matters in 2026 in a way it did not in 2005.  The
buffer-manager work that Tomas Vondra, Jakub Wartak, and
others have shipped over the last year (per-NUMA-node freelists,
NUMA-aware partitioning) only pays off if the *replacement
algorithm* knows which pages are hot enough to keep local.  ARC
and LIRS produce that signal.  Clock-sweep does not.

Third, the workload mix has changed.  A modern Postgres cluster
serves OLTP plus analytics plus TOAST plus indexes plus the
write-ahead log buffers, all from one `shared_buffers`.  The
right policy for "current order" is different from the right
policy for "audit log being scanned by yesterday's report,"
and the ability to put each in its own pool with its own policy
recovers performance that the uniform-policy assumption was
silently leaving on the table.

## status

The branch is `arc` on
[github.com/gburd/postgres](https://github.com/gburd/postgres/tree/arc).
The framework is always-available; the `DEFAULT` pool runs
clock-sweep unless the operator changes `buffer_pool_algorithm`,
so the patch is no-op for users who never touch the new
machinery.  Core regression tests pass (361/361 in `meson test`)
and the build is `pg_indent`-clean, warning-free under
`-Werror`, at every commit boundary.

This is a pre-CommitFest design preview; the mailing-list thread
will follow.  Comments and review on the wiki page or via
pgsql-hackers welcome.  The benchmark harness (Python +
DTrace/bpftrace + HammerDB integration) lives on a companion
`arc-bench` branch and the numbers are not yet in a state I am
willing to publish — that is its own post when they are.
