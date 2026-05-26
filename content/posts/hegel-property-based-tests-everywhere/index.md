+++
title = "Hegel: one PBT engine, every language"
date = "2026-10-19"
draft = true
description = "Hypothesis-quality property tests with shrinking, in any language, via a Unix-socket protocol."
[taxonomies]
tags = ["testing","property-based-testing","hegel","hypothesis"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

Hypothesis is the gold-standard property-based-testing framework but it's
Python. Hegel is a Python (Hypothesis) server speaking to per-language client
libraries (Rust, Go, C, TypeScript) via Unix sockets with CBOR-encoded
payloads. One PBT engine, many languages, with the hard part — shrinking —
implemented once.

## outline

- [ ] The PBT idea in 90 seconds.
- [ ] The "shrinking is the hard part" argument.
- [ ] Why one universal protocol beats five per-language libraries.
- [ ] Protocol shape: CBOR over Unix sockets, what's in a message.
- [ ] Cross-language correctness testing: port C → Rust, run the *same*
      property tests on both, observe divergence.

## source material

- `~/ws/hegel/CLAUDE.md` and `core/`, `rust/`, `go/`, `c/`, `skill/` subtrees.

## open questions for me to answer

- Is Hegel mine or am I a contributor? Get attribution right.
