---
title: "free list"
date: "2023-10-20"
description: "the free-list of pages is hard to manage"
taxonomies:
  tags: ["projects", "storage", "databases"]
extra:
  hero: true
  heroPrompt: ""
---

Memory allocators, page-backed databases, and more all manage what's known as
the "free list" of pages available for (re)use.  There are subtle issues with
managing this information.  I just finished re-writing this in LMDB, so I'll
capture some lessons learned and talk about the implementation here in hopes
that it helps someone else solve this (or similar) problem in the future.  Also
it's cathartic, this was hard.
