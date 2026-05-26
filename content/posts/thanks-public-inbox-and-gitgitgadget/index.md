+++
title = "thanks public-inbox; hello GitGitGadget"
date = "2027-01-18"
draft = true
description = "A thank-you for the mailing-list-as-data primitive, and a heads-up that I'm bringing patch threading to agora."
[taxonomies]
tags = ["postgres","public-inbox","gitgitgadget","agora","mailing-lists"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

A genuine thank-you to the public-inbox project for making mailing-list-as-
data tractable, and a heads-up to GitGitGadget that I plan to incorporate
parts of their workflow into agora — patches as first-class objects threaded
against their pgsql-hackers discussion.

## outline

- [ ] What public-inbox does that is uniquely valuable.
- [ ] How agora consumes public-inbox v2 archives today.
- [ ] What GitGitGadget gets right about patch-review UX (PRs as threads,
      comments as replies, format-patch round-trip).
- [ ] Concrete agora roadmap: PR-as-thread, comments-as-replies, one-click
      format-patch, attribution back to the original mailing-list message-id.
- [ ] How to help if you're on either project.

## source material

- `~/ws/public-inbox/` — local clone for reference.
- Agora's mailing-list ingestion code in `~/ws/pgesq/agora/`.

## open questions for me to answer

- Have I actually emailed the GitGitGadget folks yet? Lead with truth.
