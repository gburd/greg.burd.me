+++
title = "in praise of pcompress"
date = "2026-10-05"
draft = true
description = "Variable-block dedupe, polynomial fingerprinting, MinHash similarity, adaptive compression by file type, all parallel."
[taxonomies]
tags = ["compression","tools","pcompress"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

Moinak Ghosh's pcompress is the kind of tool that should be shipping in
every distro and isn't. Adaptive compression by file type, variable-block
dedupe, polynomial fingerprinting, MinHash similarity, parallel by default.
A walk through what makes it special and why it deserves a v4.x revival.

## outline

- [ ] The adaptive-by-type angle: most archivers are not.
- [ ] Variable Block Deduplication and bsdiff delta compression.
- [ ] The MinHash similarity trick that makes dedupe tractable on dissimilar
      chunks.
- [ ] Parallel pipeline: I/O / compress / dedupe overlapping by default.
- [ ] v4.x modernization (cite `docs/MIGRATION_v4.md`).
- [ ] Why this design ages well even as compression algorithm fashion shifts.

## source material

- `~/src/pcompress/README.md`.
- `~/src/pcompress/docs/`.

## open questions for me to answer

- What is my actual involvement vs. fan-of-the-project? Be precise about
  whether I'm a maintainer or a cheerleader.
