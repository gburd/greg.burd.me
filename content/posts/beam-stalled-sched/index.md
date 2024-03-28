---
title: "Origin Stories: The BEAM's Dirty Schedulers"
date: "2023-10-20"
description: "How I helped to diagnose stalled schedulers, my fix, and the upstream fix."
taxonomies:
  tags: ["projects", "storage", "databases", "sleepycat", "sql"]
extra:
  hero: true
  heroPrompt: ""
---

Between

My code that layers on top of NIFs (async-nif.h) vs "dirty schedulers" and ...

At Basho I was the PE/Architect/IC on storage engines, key/value per-node
indexed storage.  We had a few, LevelDB, HanoiDB, WiredTiger, Bitcask, etc., but
the issue I'll describe only happened with LevelDB.  LevelDB is an LSM k/v
engine put out by Google as some example code that was not very mature but had a
solid idea.  Over the years it has greatly influenced many things and is at the
heart of the RocksDB project now.  That said, back then, it was a new code base.
This code was tied into an Erlang runtime called the BEAM (think JVM for Java)
using a layer called NIF (native implemented functions, think JNI).  The Erlang
BEAM has a fascinating history relative to the JVM; it was developed by Ericsson
(a very large telecom) and runs on custom-embedded hardware.  As such, the
processing boards had known capacity and other characteristics.  These boards
could be swapped out without downtime; they could do all sorts of fun things.
The BEAM on PC server hardware didn't have these demands, but some of that old
code remained in the BEAM and generally didn't cause issues.


One fine day, we had a SEV1 customer event.  A large user with 40+ servers (that
was large back then) running Basho's Riak software and using the LevelDB backend
was experiencing service degradation that was odd to say the least.  Systems,
when restarted, would function as expected; data wasn't going missing, and so
the system was functional.  But, slowly, the CPU cores allocated to the BEAM
would idle rather than process data.  Despite being assigned to the BEAM and the
BEAM having plenty of work to do the cores would stop processing work.  Other
work continued; in fact, the work would pile up on the remaining cores until
they were at 100% utilization and eventually trigger alarms, causing sysadmins
to restart the node, whereupon the cycle repeated.


In engineering, my team, which owned the data storage, started digging.  The
front-end team also did so; no one knew what was causing this issue, so we were
all on high alert.  We quickly found that it was the back-end by substituting in
a different storage layer, HanoiDB and Bitcask, on a few nodes as a test.  Those
nodes remained up; they didn't demonstrate the issue.  The primary difference
between the Bitcask and HanoiDB and LevelDB was that LevelDB had a NIF and
bridged into C code.  I divided the team into two groups, one looking internally
in the LevelDB code for ways it might stall, one looking into how the BEAM
interacted with the NIFs.  The BEAM has a shockingly good amount of diagnostic
tooling (due to its embedded history), making it easy to watch the inner
workings of the schedulers for the work handed to the CPU cores in real-time
under load.  While doing this we noticed that the BEAM would designate a core as
"down" and stop sending new work to it.  Then it would do that to another core,
and another, until you were down to a single core doing as much work as it could
do.  The "schedulers" were "stalling" due to... what?  We didn't yet know.


Erlang language runs on the BEAM and depends on its soft real-time runtime
system for some fantastic features.  As such, "processes" (small code fragments)
are sent to the schedulers and run with a time limit.  Exceed that limit and the
software is rescheduled for later.  With our hybrid Erland/C LevelDB code it
turned out that the ability to reschedule a process was thwarted.  When in the C
portion of the code we'd end up waiting for I/O longer than the allotted time
and this was misinterpreted by the BEAM as "dead core, don't send more work
there, flag this to the sysadmins and request a new board because this one is
damaged.
