+++
title = "AI attribution, CC-for-AI, and US copyright's blind spot"
date = "2027-03-01"
draft = true
description = "IBM's AI Attribution Toolkit, the proposed CC-for-AI framework, and three open-source license puzzles you should be worried about."
[taxonomies]
tags = ["ai","copyright","creative-commons","open-source","license","essays"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

IBM's AI Attribution Toolkit (research.ibm.com/blog/AI-attribution-toolkit
and aiattribution.github.io) proposes a Creative-Commons-style attribution
framework for model-generated content. US copyright law currently does not
recognize copyright in AI-generated work. The implications for open-source
and free/libre software are larger than people are pricing in: training-data
attribution, derivative-work boundaries, and license-incompatibility risk
for projects accepting AI-assisted contributions. Three concrete puzzles,
and a project-level policy you can adopt today.

## outline

- [ ] What the IBM toolkit actually proposes.
- [ ] The CC-for-AI analogy, and where the analogy breaks.
- [ ] US Copyright Office recent guidance — cite specific decisions
      (Thaler v. Perlmutter, Zarya of the Dawn, the 2023 / 2024 / 2025
      registration guidance).
- [ ] Puzzle 1: DCO sign-off when the patch was AI-assisted. Who is the
      committer's "I" representing?
- [ ] Puzzle 2: copyright-aggregating CLAs, and what they aggregate when
      the underlying work isn't copyrightable.
- [ ] Puzzle 3: copyleft propagation — does GPL infect non-copyrightable
      AI output?
- [ ] A pragmatic project-level policy that handles all three without
      pretending the law is settled.

## source material

- <https://research.ibm.com/blog/AI-attribution-toolkit>.
- <https://aiattribution.github.io/>.
- US Copyright Office "Copyright and Artificial Intelligence" reports.

## open questions for me to answer

- I am not a lawyer. Frame as practitioner's read, not legal advice.
- Get the case citations exact before publishing.
