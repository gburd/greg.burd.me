+++
title = "in praise of pcompress"
date = "2026-10-05"
draft = true
description = "Moinak Ghosh's archiver gets compression details right that the rest of the ecosystem still gets wrong. v4.x is the modernization pass it deserves."
[taxonomies]
tags = ["compression","tools","pcompress"]
+++

I have been quietly grateful for [pcompress](https://github.com/moinakg/pcompress)
for more than a decade.  Most people who reach for an archiver
reach for whatever is in the path: `tar` plus `gzip`, `tar` plus
`xz`, increasingly `tar` plus `zstd`.  Those tools are excellent.
They are also, in 2026, doing about a third of the work an
archiver could do, because they treat the bytes as opaque.

pcompress does not.  It looks at the data, picks an algorithm
appropriate to the file type, runs variable-block deduplication
*before* compression, detects similar-but-not-identical chunks
through MinHash and reaches for `bsdiff` delta compression
between them, overlaps I/O with compression as a matter of
course, and produces a single archive that is most of the time
materially smaller than the same input through any single-
algorithm tool.

This post is an unabashed recommendation to use it.  The v4.x
modernization branch is the project waking up after a quiet
stretch and is the right time to look at it again.

## the design that has aged well

Moinak Ghosh built pcompress between 2012 and 2014 around five
ideas, all of which I think are still right:

  1. **Adaptive compression by file type.**  An archive is
     usually heterogeneous.  Source code wants something with
     a context-mixer (PPMD, LZMA), structured binaries want
     LZ4 or Zstandard, JPEGs and audio want format-aware
     filters (PackJPG, WavPack), already-compressed files want
     to be passed through.  pcompress detects the file shape
     and picks accordingly, rather than putting one
     compressor's tradeoffs on every byte.

  2. **Variable-block deduplication via polynomial
     fingerprinting.**  Instead of fixed-size blocks (which
     align poorly with content boundaries), pcompress uses a
     rolling polynomial fingerprint to find content-defined
     chunk boundaries — the same idea behind `rsync`'s
     rolling checksum and the LBFS file system.  Chunks
     correspond to "natural" boundaries in the data.  Identical
     chunks are stored once.

  3. **MinHash similarity for delta compression.**  When two
     chunks are *similar* but not identical (a small edit to a
     large file, two versions of the same database backup),
     pcompress detects the similarity through MinHashing and
     stores the second chunk as a `bsdiff` delta against the
     first.  This is the trick that makes a backup-of-backups
     archive collapse from "linear in number of versions" to
     "roughly linear in unique bytes."

  4. **Overlapped I/O and compression.**  Reads, compression,
     and writes run on separate threads, with a small slab
     allocator dedicated to chunk buffers.  Modern CPUs have
     a lot of cores; modern storage has a lot of latency to
     absorb.  pcompress was written under the assumption that
     both are true and works the threads accordingly.

  5. **Separate the algorithm from the policy.**  The chunker,
     the deduplication layer, the similarity detector, and the
     compressor are all separately swappable.  Adding a new
     algorithm — say, integrating Zstandard — is a matter of
     filling in a small handful of callback slots, not
     understanding the whole pipeline.

That fifth point is the one I want to call out.  Most archivers
(and most compression libraries) entangle their pipeline stages
in ways that make adding a new algorithm a substantial fork.
pcompress treats compression algorithms as plug-ins.  It is
exactly the kind of design that makes a project survive a decade
of new algorithms landing without being rewritten.

## what v4.x has done

The v4.x branch is a modernization pass on a codebase that had
gone quiet around 2017.  The deltas are not glamorous; they are
the deltas you have to ship before anyone else can take the
project seriously again.

Completed:

  - Zstandard integration with proper level mapping and multi-
    threaded compression support.
  - Dependencies (LZ4, libbsc, Zstandard, libarchive, WavPack)
    converted to git submodules so the build is reproducible
    against pinned upstreams; LZMA SDK remains vendored, with
    rationale documented in `docs/DEPENDENCIES.md`.
  - Build system portability: POSIX `sh` scripts, `pkg-config`
    discovery, an honest Nix flake that pins the toolchain.
  - **Zero warnings** from project-owned source code.  Including
    zero OpenSSL deprecation warnings on 3.x.  This is a small
    thing.  This is also the thing that makes integrators trust
    a project.
  - OpenSSL compatibility hardened across 1.1.1, 3.0, and 3.1+.
    Version detection at compile time, deprecation suppression
    where APIs are still usable, hard `#error` if a binary
    compiled against 3.x is dynamically linked against 1.1.x
    at runtime.
  - Platform-agnostic CPU feature detection abstraction
    (`utils/cpu_features.h`) that does the right thing on
    x86_64 (CPUID), aarch64 (HWCAP), and falls back gracefully.
  - Comprehensive developer documentation — `ARCHITECTURE.md`,
    `MIGRATION_v4.md`, `PORTING.md`, `SIMD_OPTIMIZATION.md`,
    `TESTING.md`.  None of this existed in 2017.

In progress:

  - ARM64/NEON optimised code paths for BLAKE2 and xxHash.  The
    scalar fallbacks work; the NEON paths land speedups in the
    2–3× range on the hot inner loops.
  - GitHub Actions CI matrix.
  - Cross-platform validation on macOS and FreeBSD.

What stayed the same: the `.pz` archive format.  An archive
written by pcompress 3.x reads through pcompress 4.x without
ceremony.

## the licensing thing, plainly

pcompress is dual-licensed under LGPLv3 (the main git tree) and
MPLv2 (a separately published tarball, updated periodically).
Some integrated third-party components are LGPL-only and so the
MPLv2 distribution loses those features.  The licensing table in
the README is exhaustive.

This matters because the archiver-as-library is a real use case.
A backup product that wants pcompress's deduplication and delta
machinery wants to link it; LGPL-vs-MPL is the difference between
"yes" and "let me check with legal."  The dual-license posture
is the right answer to that question; I think pcompress is
under-deployed partly because the answer used to be harder to
find.

## what pcompress is and is not

It is the right tool for:

  - Backup archives where the same data appears repeatedly with
    small drift between versions.
  - Mixed-content archives (source plus binaries plus media)
    where one-size-fits-all compression leaves a lot of bytes
    on the table.
  - Workflows that already have multi-core capacity and want to
    use it during archive creation.
  - Anybody who has reached for `tar | gzip | gpg` and wishes
    the resulting archive were 2× or 3× smaller without giving
    up authenticated encryption.

It is the wrong tool for:

  - Streaming compression where you cannot tolerate the chunk-
    boundary detection latency.  Use Zstandard directly.
  - Single-file compression of one well-known format.  If you
    are compressing exactly one PostgreSQL `pg_dump`, the
    overhead of pcompress's heuristics is not earning anything.
  - Byte-for-byte interchange with another tool's archive
    format.  pcompress writes `.pz`, which nothing else reads.

## a small operational note

pcompress's encryption story (AES + Salsa20, Scrypt for password-
based key derivation, HMAC for authentication, unique session keys)
is correctly built and uses well-known primitives.  This sounds
obvious.  In 2026 it is still rarer than it should be in archiver
tools that promise both compression and encryption.  When somebody
asks me "what should I be using to back up this directory tree
across an untrusted channel," pcompress is the answer that does
not require me to caveat the encryption.

## status and where to find it

The v4.x modernization is in active development on
[github.com/moinakg/pcompress](https://github.com/moinakg/pcompress)
and on a working branch under [my own mirror](https://codeberg.org/gregburd/pcompress).
LGPLv3 (or MPLv2 separately).

If you build storage tools, archive products, or backup
infrastructure, this is a project worth your evening.  And if
you are Moinak: thank you for the original design.  Twelve years
on, it still earns its keep.
