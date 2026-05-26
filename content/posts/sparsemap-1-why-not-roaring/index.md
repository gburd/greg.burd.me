+++
title = "sparsemap, part 1: why not just use Roaring?"
date = "2026-06-01"
draft = true
description = "Roaring Bitmaps are excellent. They are also not the right tool for every bitmap problem. Here is one shape they leave on the table."
[taxonomies]
tags = ["sparsemap","bitmaps","postgres","series:sparsemap"]
+++

Almost every time I show somebody [`sparsemap`](https://codeberg.org/gregburd/sparsemap),
the first question is "why not just use [Roaring](https://roaringbitmap.org/)?"
It is a fair question.  Roaring is excellent.  Production-tested,
mathematically grounded, available in every language anyone uses, and
backed by a small library of papers that explain exactly why it
behaves the way it does.  When somebody asks me about a bitmap
problem and the universe is large and the density is mixed and they
need a library yesterday, the right answer is almost always "use
Roaring."

This post is about the cases where the right answer is not "use
Roaring."

## the textbook bitmap problem in one paragraph

A bitmap is the right data structure when you have a small universe
of values and want to ask set-membership questions in O(1) per bit.
This breaks down in two ways.  If the universe is large — say 32-bit
integers — a dense bitmap is 512 MB regardless of how many bits are
actually set.  If the universe is small but the data are sparse, the
storage is dominated by zeros that you do not care about and that
have to be scanned anyway.  Real workloads tend to drift to one or
both of these failure modes.

## what Roaring does about that

Roaring partitions a 32-bit universe into 65 536-element chunks and
picks, per chunk, one of three container types: a sorted array
(when the chunk has few set bits), a dense bitmap (when the chunk is
crowded enough that arrays cost more than the bitmap), or an RLE
container (when the chunk has long runs).  The container type is
chosen at insertion time and converted on the fly when the
density crosses a threshold.

This works well in the common case and great in the very common
case.  The papers ([Chambi et al., 2014](https://arxiv.org/abs/1402.6407);
[Lemire et al., 2018](https://arxiv.org/abs/1709.07821)) show
quantitatively where it pays off, which is most realistic workloads
for most realistic data.

## what Roaring asks of you

Three things, in my experience.

First, the *three-way container dispatch* costs a branch and a
type-tag check on every operation.  In a hot inner loop — an index
scan, a visibility-map probe, a per-tuple bit test inside a
heap-recheck — that branch is sometimes the difference between
predictable performance and a performance cliff.  It is a small
cost.  It is real.

Second, the *array-of-shorts container* is fast for sparse chunks
but the *binary-search-on-insert* path tail-pessimises bursts of
ordered inserts, which is the access pattern most posting-list
builders actually have.  You can work around this with explicit
batched-insert APIs, but those APIs are different from the
"add this bit" interface that motivated using a bitmap in the
first place.

Third, the *dense bitmap container* is 8 KB regardless of bit
count, which means a chunk with 512 set bits and a chunk with
65 535 set bits store identically.  This is correct given the
design — the dense container exists for the case where the
density would defeat the array — but the choice of when to flip
to dense is global rather than informed by the *shape* of the
density (long runs vs. uniform mid-density vs. clustered).

## the workload that motivated sparsemap

I write database extensions.  In databases, bitmaps show up in
specific places: visibility maps, transaction-id sets, posting
lists in inverted indexes, dirty-page bitmaps in the buffer
manager, the bitmap-heap-scan TID set, the trigram postings inside
[`pg_tre`](https://codeberg.org/gregburd/pg_tre).  Each of those
places has a bias.  Visibility maps and posting lists tend to have
*long runs of contiguous set bits* because the rows that satisfy
the predicate are clustered on disk, because the rows were inserted
in order and never updated, or because the index sorts by a key
that correlates with insertion order.

Roaring's RLE container handles long runs, but only after the
container has been promoted to RLE, and only as one of three
behaviours that compete for the dispatch.  My workload spent a lot
of time in the RLE case and was paying for the existence of the
other two.

## what sparsemap does instead

Two encodings, no run-time dispatch:

  - **Sparse encoding** stores a 64-bit descriptor and only the
    sub-vectors that contain a *mix* of set and unset bits.
    Uniform vectors (all-zero or all-one) take zero payload.
  - **RLE encoding** stores a single 64-bit descriptor for a
    contiguous run of set bits.  A 2 097 152 000-bit run takes 8
    bytes.

Best case: 16 KB of consecutive set bits in 8 bytes.  Worst case
(random bits, no run structure, no uniform sub-vectors): identical
to a raw bitmap plus 8 bytes of descriptor overhead.  That second
sentence is the one I want you to remember.  *The pathological
sparsemap chunk is no worse than the bitmap you would have stored
anyway.*  There is no path where sparsemap costs you more than 8
bytes per 16 KB chunk.

The dispatch cost is one descriptor decode at the chunk boundary,
and after that the inner loop is a single branchless walk through
the descriptor's vector codes.  No three-way switch.  No
container-type-tag check.  No promotion.

## when this matters and when it does not

Use Roaring when:

  - You need a battle-tested library with implementations in
    every language, and your workload is mixed-density without a
    strong run bias.
  - The bitmap is large enough that the three-container dispatch
    cost amortises across millions of operations per query.
  - You want set-algebra (AND/OR/XOR/ANDNOT) at scale and have
    not measured your hot path.

Use sparsemap when:

  - The bitmap lives inside a hot inner loop where you can see the
    branch in your perf top.
  - Your bitmaps tend to have long runs because the *generator* of
    the bits clusters them — disk-ordered scans, posting lists,
    transaction-id sets.
  - You want a worst-case guarantee that the encoding never costs
    you more than one descriptor per chunk over a raw bitmap.

This is not a competition.  Both libraries are MIT-licensed.  Both
solve a real problem.  They solve slightly different problems.

The next post in the series walks through the descriptor format
and the RLE encoding in enough detail to read a `xxd` dump of a
real chunk.  The third post walks through how `pg_tre` uses
sparsemap as the trigram postings layer in its three-tier filter
funnel, and why postings lists hit sparsemap's best case more
often than the literature suggests.
