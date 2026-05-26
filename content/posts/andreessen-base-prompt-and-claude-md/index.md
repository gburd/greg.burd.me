+++
title = "the base prompt that fixed my AI assistants"
date = "2027-02-15"
draft = true
description = "Marc Andreessen's anti-sycophancy prompt, adapted across Claude Code, Kiro, and Pi, with the actual prompt."
[taxonomies]
tags = ["ai","prompt-engineering","tools","essays"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

Marc Andreessen wrote about a base prompt for AI assistants that strips
sycophancy and asks for genuine pushback. I now use a version of that
across `~/.claude/CLAUDE.md`, Kiro's steering, and Pi's APPEND_SYSTEM.md.
The prompt is short. The behavior change is large. Why and how, with the
actual prompt as published in my dotfiles.

## outline

- [ ] The original Andreessen post (link).
- [ ] What sycophancy costs you in practice: correctness, calibration,
      time, eventual user mistrust.
- [ ] The prompt that fixes it (paste the actual file contents from
      `~/.kiro/steering/voice.md`).
- [ ] Specific behaviors before vs. after — three concrete examples.
- [ ] Why this generalizes to non-coding work.
- [ ] Caveat: this prompt is not a replacement for verification. It makes
      the assistant more *honest*, not more *correct*.

## source material

- `~/.kiro/steering/voice.md`.
- `~/.claude/CLAUDE.md`.
- Andreessen's original post — find and link.

## open questions for me to answer

- Get the citation right.
