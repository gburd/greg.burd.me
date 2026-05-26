+++
title = "benchmarking PostgreSQL on NUMA bare-metal: a concrete protocol"
date = "2027-02-08"
draft = true
description = "End-to-end: instance pick, OS prep, build matrix, pgbench / HammerDB, flamegraphs."
[taxonomies]
tags = ["postgres","benchmarking","numa","performance","tutorial"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

How to benchmark PostgreSQL on NUMA bare-metal correctly. Disable
transparent hugepages. Set the CPU governor to performance. Configure
irqbalance. Pin pgbench. Collect perf. Generate flamegraphs. End-to-end
protocol, no hand-waving.

## outline

- [ ] Why bare-metal and why NUMA matters for buffer-manager and lock work.
- [ ] Instance pick (r8i.metal-96xl or m6i.metal — cite the skill).
- [ ] OS prep checklist (THP, governor, irqbalance, hugepages, mount opts).
- [ ] Build matrix: stock vs. patched, configure flags, build with
      `--enable-debug --enable-cassert` for development runs.
- [ ] pgbench protocol: warmup, scale, duration, repetition.
- [ ] HammerDB TPC-C protocol.
- [ ] Where flamegraphs lie and how to read them anyway.
- [ ] Cleanup and result archival to S3.

## source material

- `~/.kiro/skills/pg-numa-benchmark/` — the skill is the seed.
- Various perf / flamegraph documentation references.

## open questions for me to answer

- Distinguish AWS-specific tuning advice from general advice. The reader
  isn't necessarily on AWS.
- Stick to public benchmarking technique. Do not include any
  AWS-DocumentDB-internal observations or numbers.
