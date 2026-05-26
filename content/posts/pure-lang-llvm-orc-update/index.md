+++
title = "porting Pure Language to current LLVM Orc"
date = "2026-09-28"
draft = true
description = "What Albert Gräf's term-rewriting language teaches you about staying compatible with LLVM."
[taxonomies]
tags = ["pure-lang","llvm","jit","languages"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

Pure is Albert Gräf's term-rewriting language with an LLVM JIT backend.
I updated it to current LLVM Orc. What that took, what stayed the same, and
what the upstream LLVM project breaks every release.

## outline

- [ ] 30-second pitch on Pure (term rewriting + JIT).
- [ ] Where Pure had been stuck (legacy MCJIT).
- [ ] The Orc API generations (v1 → v2 → "ORCv2 but materially different
      again") and what's stable enough to depend on.
- [ ] Migration patterns that survive future LLVM breakage.
- [ ] Honest accounting of what I broke and how.

## source material

- `~/ws/pure-lang/README.md` and the LLVM-related diff.

## open questions for me to answer

- Has the upstream Pure project (Albert) accepted my changes? If yes, link;
  if no, explain the fork status.
