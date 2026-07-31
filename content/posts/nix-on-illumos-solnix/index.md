+++
title = "Nix on illumos: what solnix is and why"
date = "2026-08-28"
draft = false
description = "illumos already has ZFS boot environments and SMF. Nix's generation model maps onto them almost exactly. solnix is the illumos analog of NixOS — early, but the risky parts already work."
[taxonomies]
tags = ["nix","illumos","storage","databases"]
+++

There is a version of the Solaris story where it just ends: Oracle
buys Sun, closes the source, and the interesting parts of the operating
system disappear into a proprietary product nobody outside a few
enterprises ever touches again.  That is not what happened.  Before the
acquisition closed, the OpenSolaris code was out, and
[illumos](https://illumos.org/) has carried it forward ever since — a
living, open-source Solaris-derived kernel and userland with ZFS,
DTrace, zones, SMF, and bhyve, maintained by people who never wanted
those things to die.

The problem illumos has is not technical.  It is that installing and
maintaining one feels like 2010.  You configure it by editing files in
place and hoping you can reconstruct what you did.  Meanwhile the Linux
world has spent a decade learning that you can describe an entire
machine as a single declarative expression, build it reproducibly, and
roll it back atomically when it breaks — the [NixOS](https://nixos.org/)
model.

**[solnix](https://codeberg.org/gregburd/solnix) is the illumos analog
of NixOS.**  It is a distribution of illumos built entirely with the
Nix package manager and the NixOS module system, the way NixOS does it
for Linux and nixbsd does it for the BSDs.  I want to explain why that
pairing is not arbitrary, and then be honest about how far along it is.

## why Nix and illumos fit

The reason this is worth doing rather than clever-for-its-own-sake is
that illumos already has the hard half of what Nix needs, and has had
it for fifteen years.

Nix's whole model rests on immutable, content-addressed builds and a
generational system where every configuration change produces a new
generation you can boot into or roll back from.  On NixOS that
generation machinery is bolted on top of Linux.  On illumos it is
*already there*: ZFS boot environments (`beadm`) give you exactly that
— snapshot the system dataset, apply changes to a new environment,
list them in the boot loader, roll back by booting the old one.  Nix
generations map onto ZFS boot environments almost one-to-one.  You are
not fighting the OS to get atomic upgrades; you are describing, in Nix,
a thing illumos was built to do.

The second fit is subtler and it is the one that made me think this was
actually tractable.  Nix on Linux has to do an ugly dance to make
binaries find their libraries: it builds them, then rewrites the ELF
`RUNPATH` after the fact with `patchelf`, because GNU `ld` won't put
`/nix/store` paths in cleanly.  The Solaris link-editor — a genuinely
different linker from GNU `ld` — bakes `-R` runpath entries directly
into the ELF at link time.  No patchelf, no post-processing.  A binary
built through the store links against the store, natively.  The first
spike proved exactly this: a `hello.c` compiled with the seed
toolchain, linked by the Solaris linker with a store-baked runpath,
resolved libc out of the Nix store on illumos and ran.

And then everything illumos already has — ZFS, DTrace, zones, bhyve,
LX-branded zones for Linux binary compatibility, SMF for service
management — becomes declaratively configurable, without reimplementing
any of it.  That is the pitch: Nix's reproducibility and rollback, on
top of a mature Solaris-derived kernel, for operators who want that
level of control and are tired of the Linux monoculture.

## how you build an OS that can't cross-compile

The hard engineering problem is bootstrapping.  You cannot cross-
compile illumos-gate — the kernel, libc, the linker, the base tools —
from Linux, because the gate's build machinery is itself illumos-
native: it needs `dmake`, CTF, the Solaris `ld`, `elfsign`.  So the
anchor has to be built natively on illumos, and the challenge is
getting Nix to run *there* in the first place.

It does.  Nix builds from source on an OpenIndiana host with three
small illumos-specific patches, running as a single-user daemon with
sandboxing off — illumos has no Linux namespaces, so isolation comes
from zones and privileges instead.  From there the strategy is tiered.
The gate-derived world (libc, kernel, linker, runtime linker, base
tools) is built natively, then sliced into fine-grained Nix
derivations whose ELF runpaths are rewritten into the store with
`elfedit` — no re-linking needed, because the Solaris toolchain put
usable runpaths there to begin with.  Ordinary third-party packages
can cross-compile later, once a cross-gcc targeting `x86_64-solaris`
exists.  And everything gets pushed to a signed binary cache, so where
a package was built stops mattering to the person installing it.

The nixpkgs fork needed for this is small: a patch adding the
`x86_64-solaris` platform, a bintools-wrapper patch that translates GNU
linker flags to Solaris ones (`-rpath` becomes `-R`, `-dynamic-linker`
becomes `-I`), and an overlay for the illumos-specific packages.

## where it actually is

Now the honest part, because a project post that oversells its state is
worthless.  **solnix does not boot a full system on x86_64 yet.**  It
is early — the roadmap calls it Phase 0/1.  What exists is the thing
that de-risks the whole idea: the parts most likely to be impossible
have been shown to be possible.

Concretely, across three architectures, the package build is real and
verified by checking the ELF machine type of every output:

  - **x86_64:** ~7,400 packages built.
  - **aarch64:** ~1,000 packages built — and this is the one that
    boots.  An aarch64 illumos guest (using Rich Lowe's out-of-tree ARM
    port) comes up under QEMU, attaches virtio-block drivers, mounts a
    ZFS root, and reaches the multi-user SMF milestone with a clean
    `svcs`.
  - **SPARCv9:** ~700 packages, revived from bit-rotting in-gate code —
    a hundredfold growth from the six-package seed.

The binary cache is up and serving signed artifacts over an S3-
compatible endpoint, and it refuses to hand you a path whose signature
doesn't verify, which is the property that makes a public cache
trustworthy.

What is not done: a full x86_64 boot to multi-user (aarch64 got there
first, which surprised me too), the complete SMF-from-Nix-modules
integration, and a proper multi-stage native stdenv rather than the
wrap-and-slice shortcut that gets to correctness faster.  The community
site, solnix.io, is designed but not deployed.

## why publish now

Because the interesting claim — that Nix and illumos fit together
cleanly — is already demonstrated, and the demonstration is more
convincing than the roadmap.  Nix runs on illumos.  The Solaris linker
makes the store work without patchelf.  Thousands of packages build for
three architectures, one of which boots to multi-user.  The rest is
work, not risk.  If reproducible builds on top of ZFS, DTrace, and
zones sounds like something you have wanted, the design docs and the
build harness are in the open at
<https://codeberg.org/gregburd/solnix>.
