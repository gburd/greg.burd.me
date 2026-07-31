+++
title = "how do you trust a 30-year-old storage engine?"
date = "2026-08-07"
draft = false
description = "Reviving Berkeley DB meant deciding what quality bar to hold it to. Deterministic simulation, malloc-failure injection, fuzzing, and property-based tests — and the bugs they found."
[taxonomies]
tags = ["berkeley-db","storage","testing","databases"]
+++

In the [first post](/posts/reviving-berkeley-db/) I described forking
Berkeley DB 5.3 back onto a permissive license and giving it a build
system from this decade.  Getting it to compile is the easy part.  The
hard part, and the part that decides whether anyone should put data in
it, is trust.

A storage engine has exactly one job: never lose or corrupt data that
it told you was safe.  Everything else — speed, features, portability —
is negotiable.  That one job is also the hardest thing to test, because
the failures that matter happen at the seams: a write torn in half by a
crash, an `fsync` the kernel lied about, a malloc that fails on the
undo path during recovery.  You do not find those with unit tests that
run on a healthy machine.  So the quality work on the revival is mostly
about deliberately breaking the machine.

## deterministic simulation

The centerpiece is deterministic simulation testing — the same
technique FoundationDB is famous for.  The idea is to run the engine
inside a simulated world where time, I/O, and failures are all
controlled by a seeded pseudo-random generator, so that any run is
exactly reproducible from its seed.  When a scenario finds a bug, you
have the seed, and the seed replays the failure bit-for-bit.

The catalog is 36 scenarios covering the fault classes that actually
cause data loss: torn writes, `EIO` on read or write, `ENOSPC`
mid-transaction, clock skew, and a write-back cache that acknowledges
writes before they hit disk and then drops them on a crash.  Each
scenario checks the invariants that have to hold no matter what broke —
committed transactions survive, uncommitted ones do not, and recovery
is *idempotent*: recover twice and you get a byte-identical database.

To know the framework actually detects failures rather than passing
vacuously, there are nine deliberately planted bugs seeded into the
tree — known-bad code paths the simulator is required to catch.  A test
harness that cannot find bugs you put there on purpose is not testing
anything.  The whole apparatus is off by default and gated behind a
build flag, so the shipped code path is verified to be exactly the code
path that runs without it — zero overhead, no simulation hooks in
production.

## injecting malloc failures

The second technique is narrower and, per line of code, has found more
real bugs than anything else: sweep every allocation in a workload and
make the *N*th one fail.

The driver runs a representative workload — environment create and
destroy, B-tree and hash databases, put/get, cursor walks, transaction
commit and abort, checkpoints, secondary indexes, join cursors, bulk
operations, two-phase-commit prepare — and counts the allocations.
That workload makes **947** allocations.  Then it runs the workload 947
times, failing allocation 1 the first time, allocation 2 the second,
and so on, and classifies each result: clean error return, tolerated,
crash, hang, or dirty state.

The most recent sweep: 947 failure points, 861 clean error returns, 81
tolerated, zero hangs, zero dirty state — and **5 crashes**.  All five
trace to a single root cause: a NULL-dereference in the hash-table
abort/undo path (`__ham_insdel_recover`) when an allocation fails while
opening the undo cursor.  That is a real, pre-existing bug in Berkeley
DB, on the recovery path, exactly the kind of thing that only surfaces
when the machine is already having a bad day.  It is reported as a
finding rather than papered over, because the point of the sweep is to
know precisely where the engine is fragile under memory pressure.
Running the same sweep under AddressSanitizer also turned up leaks on
the out-of-memory paths of `db_create` and `__db_join`.

## fuzzing and property tests

Three libFuzzer harnesses hit the three surfaces that parse untrusted
bytes.  One feeds fuzz bytes into a `.db` file and opens it, exercising
the page parser, the buffer-pool page loader, and cursor traversal.
One overwrites the write-ahead log with fuzz bytes and opens the
environment in recovery, exercising log replay — the code that has to
be paranoid because it runs after something already went wrong.  The
third is a little bytecode interpreter that turns fuzz bytes into
sequences of API calls, so the fuzzer explores put/get/delete, cursor
navigation, and transaction begin/commit/abort orderings.  Each harness
has a real seed corpus and matches the OSS-Fuzz contract, so
continuous fuzzing is a submission away.

On top of that sit property-based tests — currently fifteen property
files — that check algebraic laws the code is supposed to obey rather
than specific input/output pairs.  Log-sequence-number comparison is a
total order (reflexive, antisymmetric, transitive).  The byte-swap
macros are involutions: swap twice and you are back where you started,
at any alignment.  The varint codec round-trips and preserves order.
The prefix-compression codec round-trips.  The recno access method
keeps records contiguous under renumbering.  These are the invariants
that, if they ever break, break everything downstream silently — the
worst kind of bug — so they get checked against thousands of generated
inputs with automatic shrinking to a minimal failing case.

## coverage as a ratchet

None of this means much if large parts of the engine never execute
under test.  The original Berkeley DB test suite is a big Tcl
regression suite, and it is good, but there are whole subsystems it
barely touches.  So there is a coverage-measurement tier whose job is
to find the zero-coverage code and aim tests at it, then ratchet the
number up and never let it fall back.

The wins there are concrete.  The XA two-phase-commit code went from
**0% to about 57%** by driving the transaction manager switch directly
instead of requiring a Tuxedo install.  The on-disk upgrade paths —
the code that rewrites old-format databases, which absolutely must be
correct and almost never runs in a test — went from 0% to the 70–97%
range across the queue, hash, and B-tree upgraders.  The hot-backup API
went from 0% to about 97%.  The async I/O backends (POSIX AIO and
`io_uring`) went from 0% to the low 80s.  Replication, twelve thousand
lines that sat at under 1% coverage, is now in the mid-50s when its
coverage build is enabled.  Every one of those numbers is a subsystem
that used to ship essentially untested and now does not.

## the bar

The quality bar I am holding this to is simple to state and expensive
to meet: **committed data is never lost or corrupted, and recovery is
always idempotent, under any single fault — including the faults that
happen during recovery itself.**  That is a higher bar than "the tests
pass," because the tests passing on a healthy machine tells you almost
nothing about a storage engine.  The techniques above exist precisely
to make the machine unhealthy in controlled, reproducible ways, and to
turn "I think it's fine" into "here is the seed that proves it, and
here are the five places it isn't yet."

The [next post](/posts/berkeley-db-performance-realities/) is the other
half of trust: not correctness, but speed — where Berkeley DB actually
stands against a modern engine, and honestly, it is not a flattering
picture yet.

The repo is at <https://github.com/berkeleydb/libdb>.
