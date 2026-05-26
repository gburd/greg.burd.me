+++
title = "bdb-rs: Berkeley DB in Rust, status report"
date = "2026-09-14"
draft = true
description = "What's portable, what isn't, and the FFI patterns that survive translation from C to Rust."
[taxonomies]
tags = ["bdb","berkeley-db","rust","ffi","databases"]
+++

**Status: draft, scaffolded by an agent. Prose to be written by me.**

## thesis

Berkeley DB in Rust. Why now, what's portable, what isn't, and the FFI /
ownership patterns that survive translation. Btree and hash port well; the
transactional surface is the hard part.

## outline

- [ ] Public goals (cite `~/src/bdb-rs/`).
- [ ] Btree and hash: which page-format choices port directly, which need
      reimagining for Rust ownership.
- [ ] The transactional surface: why this is the hard part, not the storage
      layout.
- [ ] FFI patterns that survive: opaque handles, `&mut` discipline, Drop
      ordering.
- [ ] What's intentionally not being ported (replication for now).
- [ ] License-boundary care: what I am and am not doing relative to upstream
      Oracle BDB.

## source material

- `~/src/bdb-rs/` — the port.
- `~/src/libdb/` — the C library reference.

## open questions for me to answer

- License boundary: I worked at Sleepycat / Oracle on BDB. Get the
  attribution and license language airtight before publishing.
