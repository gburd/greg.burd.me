+++
title = "splay-list, part 2: when adaptive rebalancing helps"
date = "2026-06-29"
draft = true
description = "Splay-list adapts tower height to access frequency. When that wins and when it loses."
[taxonomies]
tags = ["skiplist","concurrency","caching","series:skiplist"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

A splay-list adds adaptive rebalancing to a skip-list — recently-accessed
elements migrate toward the top of the tower, cutting per-lookup hop count
for hot keys. Useful when access distribution is highly skewed (caches,
sliding-window top-N, real workload tracebacks). When this helps vs. hurts.

## outline

- [ ] Splay-tree analogy and where the analogy breaks.
- [ ] The skip-list-specific adaptation: which level migrations preserve the
      skip-list invariants.
- [ ] Empirical workload regimes: uniform, Zipf 0.7, Zipf 1.2, sliding window.
- [ ] When *not* to use it: short-lived data, balanced reads, contended
      writes near hot keys (the rebalance itself competes for the cache line).
- [ ] How my implementation flips between modes at compile time.

## source material

- `~/ws/skiplist/include/sl.h` — adaptive flag.
- `~/ws/skiplist/bench/` — workload generators.

## open questions for me to answer

- Did I implement contention-aware backoff on the rebalance step? If yes,
  describe; if no, flag as future work.
