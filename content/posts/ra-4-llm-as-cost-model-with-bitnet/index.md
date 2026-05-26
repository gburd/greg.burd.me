+++
title = "Ra, part 4: an LLM cost model in 1.58 bits"
date = "2026-07-27"
draft = true
description = "Why a tiny ternary-quantized model is a defensible replacement for hand-tuned planner cost constants."
[taxonomies]
tags = ["ra","llm","bitnet","cost-model","query-optimization","series:ra"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

Cost models are the worst part of any optimizer — hand-tuned constants that
go stale the moment the workload changes. Ra trains a small quantized LLM
(BitNet 1.58-bit) to predict relative cost from the e-graph state and the
current statistics. Continual learning closes the loop: execution feedback
updates the model online. This post argues why that's defensible and where
it falls down.

## outline

- [ ] Why hand-tuned cost models fail in practice.
- [ ] Why a learned model, why now: small models, cheap inference, free
      training data from your own executor.
- [ ] BitNet specifically: ternary {-1, 0, +1} weights, 1.58 bits per weight,
      why that's exactly the latency/memory budget I had.
- [ ] The training signal: predicted vs. observed cost ratio, stratified by
      operator type.
- [ ] Continual learning loop: feedback collection, training cadence, drift
      detection, rollback.
- [ ] Failure modes I accept and failure modes I don't. Guardrails.

## source material

- `~/ws/ra/crates/ra-cost-model/` — implementation.
- BitNet paper(s) — get the citations right.
- `~/ws/ra/agent/` — guardrails and online-learning state.

## open questions for me to answer

- Show one side-by-side: hand-tuned cost model vs. learned model on a real
  workload. Which queries does each get wrong?
- The "why not bigger model" question. Why 1.58 bits and not 4, not 8?
