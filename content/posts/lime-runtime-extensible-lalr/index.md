+++
title = "Lime: an LALR(1) generator with runtime grammar extensions"
date = "2026-09-21"
draft = true
description = "Why Yacc and Bison's compile-time-only model is a constraint nobody had to accept."
[taxonomies]
tags = ["lime","parsers","compilers","postgres"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

Yacc and Bison generate parsers at compile time. Database engines, language
servers, and extensible query processors need parsers that can evolve at
runtime. Lime is an LALR(1) generator whose output can load and unload
grammar extensions live, with conflict detection and disambiguation
callbacks. The base parser runs at full speed when no extensions are
loaded — the extension machinery has zero overhead until activated.

## outline

- [ ] The runtime-extensibility argument: who needs this and why nobody has
      shipped it.
- [ ] How extension loading works without breaking the base parser:
      table dispatch via a small VM rather than direct goto.
- [ ] SIMD-accelerated tokenization (AVX2/NEON), measured 1.5–2× on the full
      pipeline.
- [ ] Optional LLVM JIT path for action tables.
- [ ] Where pg_tre uses it (regex pattern syntax) and the bigger picture
      (PostgreSQL grammar pluggability).

## source material

- `~/ws/lime/README.md`.
- `~/ws/lime/docs/` — design.

## open questions for me to answer

- Pick a concrete extension example to walk through.
- Cite Earley / GLR alternatives honestly: I picked LALR for performance
  and predictability, not because the alternatives don't exist.
