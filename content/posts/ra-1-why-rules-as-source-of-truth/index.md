+++
title = "Ra, part 1: rules as the source of truth"
date = "2026-07-06"
draft = true
description = "Why a query optimizer's transformation rules deserve to be literate, formal, and testable in the open."
[taxonomies]
tags = ["ra","query-optimization","literate-programming","series:ra"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

Most query optimizers smear their rules across thousands of lines of
imperative code in the planner. Ra inverts that: each transformation is a
literate `.rra` file with formal algebra, preconditions, cost model, and
tests. The codebase becomes searchable, formally checkable, and
contributable without learning a planner-internal DSL.

## outline

- [ ] The optimization-rules-as-data argument (Cascades, Volcano, prior art).
- [ ] Knuth's literate programming + Markdown → `.rra` files. How the tooling
      extracts both code and docs from one source.
- [ ] Five categories and why each matters: logical, hardware (GPU/FPGA/SIMD),
      distributed, multi-model, physical.
- [ ] A worked rule end-to-end: projection pushdown is canonical and tiny;
      walk through the .rra file from header to test cases.
- [ ] The bet: 1,387 rules and growing. Why this is the right granularity.

## source material

- `~/ws/ra/README.md`, `~/ws/ra/AGENTS.md`, `~/ws/ra/CLAUDE.md`.
- `~/ws/ra/rules/` — pick one rule to walk through.
- `~/ws/ra/agent/` — tooling.

## open questions for me to answer

- Which single rule do I want to be the "first impression" reader takeaway?
- How much of the 1,387 number do I attribute to PostgreSQL vs. literature
  vs. my own additions? Be specific.
