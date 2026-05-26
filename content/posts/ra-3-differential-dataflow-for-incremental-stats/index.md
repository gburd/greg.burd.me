+++
title = "Ra, part 3: incremental statistics with differential dataflow"
date = "2026-07-20"
draft = true
description = "Maintaining correlation, multivariate, and cardinality estimates as data changes — without re-ANALYZE."
[taxonomies]
tags = ["ra","timely-dataflow","statistics","query-optimization","series:ra"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

Statistics drift. Most optimizers re-collect from scratch on ANALYZE; some
maintain incrementally with bespoke counters. Ra uses differential dataflow
(timely + ddflow) to maintain correlation, multivariate, and cardinality
estimates incrementally as data changes. Why this is the right hammer.

## outline

- [ ] What timely dataflow does that no other framework quite does (multi-
      version timestamps, declarative change-propagation, structural sharing).
- [ ] What differential dataflow adds on top.
- [ ] The estimates Ra maintains incrementally and why each matters for the
      planner.
- [ ] Cost: memory, latency-to-converge, the assumption that updates are
      streamable.
- [ ] Pointer to Frank McSherry's foundational work and the Materialize
      lineage.

## source material

- `~/ws/ra/crates/ra-stats/` — implementation.
- McSherry et al., "Differential dataflow" (CIDR 2013).

## open questions for me to answer

- Have I measured the steady-state memory cost? Worth a number if so.
- Where does this overlap with PostgreSQL's existing extended statistics?
