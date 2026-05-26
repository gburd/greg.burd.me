+++
title = "NoXu: TigerBeetle and Redis examples in one harness"
date = "2027-01-25"
draft = true
description = "Comparable numbers without comparing apples to oranges, when the workloads are deliberately heterogeneous."
[taxonomies]
tags = ["benchmarking","tigerbeetle","redis","noxu"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

NoXu ships example workloads that mimic TigerBeetle (financial double-entry,
in-memory) and Redis (KV cache). Having both in one harness lets me measure
something that no single benchmark suite does: how a system that's good at
one shape behaves when handed the other shape.

## outline

- [ ] 30-second NoXu pitch.
- [ ] The TigerBeetle example: why double-entry is a separate workload class
      (multi-account atomicity, append-only ledger, contention shape).
- [ ] The Redis example: what real KV cache traffic looks like beyond GET/SET.
- [ ] Comparable numbers without comparing apples to oranges: the metrics
      that mean the same thing in both.
- [ ] What the two examples together let me say about a database under test.

## source material

- NoXu repo path — TODO confirm. I did not find `noxu` in `~/ws` or `~/src`
  during scaffolding. Possibly a private repo or a name I don't have yet.

## open questions for me to answer

- Provide the actual repo URL when public, or describe the project's status.
- Pin the version of TigerBeetle / Redis whose semantics I'm mimicking.
