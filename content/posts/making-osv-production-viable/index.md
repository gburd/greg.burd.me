+++
title = "making OSv production-viable: the changes and the trade-offs"
date = "2026-09-04"
draft = false
description = "A rundown of the work bringing the OSv unikernel toward production — OpenZFS, io_uring, multiqueue block I/O, aarch64 — why each mattered, what it cost, and how OSv sits next to the other live unikernels."
[taxonomies]
tags = ["osv","unikernel","storage","performance"]
+++

[OSv](https://github.com/cloudius-systems/osv) is a unikernel: a single
unmodified Linux application, linked with a small kernel into one
address space, booted directly on a hypervisor as a microVM.  No user/
kernel boundary, no processes, no containers — one app, one VM, ring 0.
That design buys you a tiny image, a fast boot, and system calls that
are function calls, and it costs you isolation between the app and the
kernel, which you delegate to the hypervisor.

It is a good idea that has spent a decade being *almost* production-
ready.  The gaps were never the concept; they were the boring
infrastructure — a filesystem from 2014, no modern async I/O, block I/O
that serialized on a single queue, and an aarch64 port that trailed
x86.  This post is a rundown of the work closing those gaps, why each
piece mattered, what it traded away, and where OSv sits against the
other unikernels still breathing.

## OpenZFS instead of a decade-old ZFS

The single largest change replaces the BSD-ZFS port from around 2014 —
the only filesystem option — with upstream OpenZFS 2.4.3, selectable at
build time.  This is 24,000 lines of vendored OpenZFS plus a patch
series bridging it to the OSv platform layer through a Solaris
Porting Layer shim.

Why: the old port was frozen a decade behind upstream.  It had no TRIM,
no encryption, no Direct I/O, no deduplication, no distributed-parity
DRAID.  Modern OpenZFS is actively maintained and has all of it.  For a
unikernel that wants to hold real data — databases, stateful
microservices — copy-on-write snapshots and end-to-end checksums that
catch silent corruption are not optional.

The trade-off is honest and it is memory.  OpenZFS's adaptive
replacement cache has a real baseline footprint, versus a simple
filesystem's near-nothing, and its transaction-group commit model
batches writes into windows that add latency variance.  So OSv also
gained an optional ext2/3/4 module with real `fsync` and sequential
read-ahead, for the read-mostly or memory-constrained deployments where
ZFS's guarantees aren't worth its overhead.  You pick per workload:
ZFS when you need integrity and snapshots, ext4 when you need small and
predictable.

## async and parallel I/O

Two changes attack the I/O path, which is where a unikernel's low-
overhead promise either shows up or doesn't.

The first is `io_uring`.  OSv now implements the Linux `io_uring` ABI —
the submission and completion queues, the read/write/poll/timeout
opcodes, completion-queue backlog, cancellable polls.  Modern async
runtimes and PostgreSQL's async I/O want `io_uring`; without it, they
either don't run or fall back to a syscall per operation.  And a
unikernel is arguably the *best* place to implement `io_uring`, because
there is no user/kernel security boundary to cross — the ring is just
shared memory between the app and the kernel that are already in the
same address space.

The second is multiqueue virtio-block with TRIM.  Before, all block I/O
went through one virtio ring, and on a multi-vCPU guest the threads
fought over its lock.  Now each vCPU steers to its own queue, each
queue gets its own MSI-X interrupt vector, and the ring-lock
serialization is gone.  The remaining bottleneck — a single completion
thread draining all the queues — is a known architectural limit and
the next thing to fix.  Alongside it, `BIO_DISCARD` plumbed through the
block layer and wired to ZFS's TRIM lets thin-provisioned and SSD
backends actually reclaim freed space.

The cost of both is complexity.  `io_uring` is a genuine state machine
with multiple completion paths; multiqueue adds per-queue locking and
state.  Synchronous single-queue I/O still exists for the apps that
don't need more, so you only pay the complexity when you use it.

## the page-cache bridge, and a data-loss bug

A quieter but important change routes `mmap` page faults through OSv's
own page cache instead of directly hitting the ZFS ARC, adding
sequential read-ahead and batched writeback with correct `fsync`
flushing.  This is the kind of work that doesn't demo well and matters
enormously, because it is on the durability path.

It also fixed a real data-loss bug: the dirty-bit handling promoted
page-table entries in a way that could leave stale writable TLB
entries, so the fix reworked it into a two-phase clear-dirty /
flush sequence.  A separate multi-iov bug in the ZFS I/O path was
corrupting reads and costing a 3x throughput regression until it was
found — the sort of bug that only surfaces when you benchmark against
a real workload and see the numbers are wrong.

## aarch64 to parity, on Graviton

The aarch64 port is now feature-equal with x86-64, which for cloud
means it runs on AWS Graviton.  That took a pile of unglamorous fixes:
building the AWS ENA network driver for aarch64, gating the OpenZFS
cryptographic assembly (the ICP routines, the SHA-512 SIMD) so it
compiles on ARM at all, gating architecture-specific atomics headers so
ZFS userspace builds, and raising the ARM generic-timer frequency
ceiling to fix timing in tight spin loops.  None of it is exciting.
All of it is the difference between "supports aarch64" on a slide and
actually booting on a Graviton instance.

## the numbers I'd stand behind

OSv boots fast and small — on the order of single-digit to tens of
milliseconds on Firecracker depending on filesystem, and an 11 MB
image for a minimal app — which is the whole reason to use a unikernel
for dense microVM or serverless deployments.

On the honest side: OSv still lags Linux on disk-I/O-intensive
workloads, and the tracked cause is coarse-grained VFS locking around
read and write.  The ZFS filesystem benchmark in the tree shows RAMFS
several times faster than ZFS on random small I/O, which is the
expected cost of integrity and the transaction-group model, not a bug.
A distributed-block driver for the Crucible replicated-storage protocol
passes its I/O tests over a three-replica cluster with per-block hash
validation, though a ZFS-on-Crucible pool-creation hang is still
blocking it from being finished.  I'd rather name that than imply it's
done.

## where OSv sits among unikernels

The unikernel space sorts roughly by one question: does your app have
to be rewritten?

[MirageOS](https://mirage.io/) says yes — you write in OCaml, and in
return you get sub-megabyte images and type safety that eliminates
whole bug classes.  [IncludeOS](https://www.includeos.org/) is C++,
small and real-time-friendly, also not Linux-binary-compatible.
[Rumpkernel](https://github.com/rumpkernel) reuses NetBSD drivers as
components and runs about a megabyte, but with a smaller ecosystem and
older ZFS.  Those are all bets that the efficiency of a purpose-built
image is worth giving up your existing binaries and toolchain.

OSv takes the other bet: **run unmodified Linux binaries.**  You bring
your existing JVM service, your Python batch job, your Rust or Go
server, compiled exactly as you'd compile it for Linux, and it runs —
because OSv provides the Linux ABI through glibc/musl and the Linux
syscall surface.  You pay for that with a larger kernel than the
minimalists (a few megabytes, versus their sub-megabyte) and with the
unikernel's fundamental constraint: one address space, so an app bug
can corrupt the kernel, and there is no in-VM isolation between two
apps.  That rules OSv out of hostile multi-tenancy — you put one app
per VM and lean on the hypervisor for isolation — and rules it *in* for
fast-booting single-app microservices where you'd rather not rewrite
your service in OCaml to save four megabytes.

Kata Containers, worth mentioning, isn't really in this comparison:
it's a full Linux in a lightweight VM, multi-tenant-safe, and
correspondingly larger and slower to boot.  It's the choice when you
need real isolation more than you need small and fast.

## the summary

The work above — OpenZFS, `io_uring`, multiqueue block I/O with TRIM,
the page-cache bridge, aarch64-to-parity on Graviton — is not new
features so much as closing the distance between "interesting research
unikernel" and "you could run a database on this."  Each piece traded
complexity or footprint for a capability production actually requires,
and each is honest about what it cost.  The gaps that remain — VFS
locking, the single block-completion thread, the Crucible pool hang —
are named, not hidden.  The tree is at
<https://github.com/cloudius-systems/osv> and the fork with this work
is on [Codeberg](https://codeberg.org/gregburd/osv).
