---
title: "dbsql"
date: "2023-10-20"
description: "dbsql: Berkeley DB + SQLite"
taxonomies:
  tags: ["projects", "storage", "databases", "sleepycat", "sql"]
extra:
  hero: true
  heroPrompt: "An image extracted from an IBM whitepaper illustrating a database
  system as a software cylinder containing stored data while to the right online
  users toil away at desks and to the left automated batch systems perform
  routine data manipulation tasks."
---

Between 2002 and 2011 I worked for Sleepycat Software (acquired in 2006 by
Oracle Corporation).  When I joined Sleepycat we authored Berkeley DB (aka "BDB"
and installed on most UNIX systems at `/usr/lib/db.a`), and Berkeley DB XML (an
XQuery/XPath storage layer on top of BDB).  I was an engineer, but also tasked
with "product management," which could mean any number of things but for me at
that time, it was about attempting to match a software product with market
demands.  It was clear that [SQLite](https://sqlite.org) would eat our lunch in
the market of an "embeddable database engine" (and it did! but that's a story
for a different post).  So, as any good engineer would, I set about to fix this
myself single-handedly while living aboard a sailboat in Boston Harbor,
on Commercial Wharf, during the Winter of 2007.

Margo Seltzer and Keith Bostic are amazing programmers and thoughtful people.
What I saw in the Berkeley DB code was a model for beautiful C code.  Code that
would compile as ANSI C and K&R.  Code that had tooling for ensuring
consistency. Code that I admired and learned a great deal from over the years.

Dr Richard Hipp has a different style for C programming, one that is just as
good as anyone else's.  One that fits him, but is entirely different from what
I'd seen in Berkeley DB, *BSD, or even GNU projects like GCC.  That's something
interesting about C progrmming -- style is up to the programmer, the compiler is
ambiguous to human differences of opinion related to style.

I wanted Sleepycat to have a SQL layer on top of Berkeley DB, but I wanted to do
it in a way that Keith and Margo and the rest of the team would admire and be
willing to add to the set of supported products we offered to our customers.  An
answer to everyone asking, "where's your SQL API"?

So, I translated/rewrote(?) all the code line by line from one style to another.
I changed naming conventions.  I added supporting scripts.  I changed the build
system to Autoconf.  Day and night, weekends, whenever I toiled away in the boat
pushing myself to remold something into something else but operationally the
same.  And I did it.  I created [dbsql](https://git.burd.me/greg/dbsql), a
complete re-write of SQLite on top of Berkeley DB but and in the style more akin
to Berkeley DB programmers yet entirely the same functionality as SQLite.

"What makes it better, certainly you didn't just do this because you liked the
coding style of Sleepycat more than SQLite, tell me there's more to this
insanity!?" -- said everyone at this point.

Yes, yes there is.  Back then SQLite's storage layer was... well, it was early
days.  These days it's great, for purpose, but still lacks a lot of the features
of Berkeley DB and transactions were early days for SQLite.  With Berkeley DB
it's easy to BEGIN TXN, do lots of work over, COMMIT TXN or ABORT TXN and have
it work.  Which is a tricky thing to get right.  Also, Berkeley DB isn't just a
[BTREE](https://carlosproal.com/ir/papers/p121-comer.pdf) it is also a hash
table (HASH), a record set (RECNO), and a queue (QUEUE).  So I had plans to use
those where it made sense.  So, there's a lot of tools in the tool box, mature
tools, tested tools, and things I'd like to show off under the covers of
something complex like a RDBMS.  Sure, it's true that MySQL had (has?) a
Berkeley DB storage engine mapping, but with INNODB it was hardly used.  But
there was at least one existence proof showing that BDB+SQL worked.

On top of that, there is the "High Availability", or replication feature of
Berkeley DB, the major feature of 4.x.  3.x was transactions, 4.x was
single-master, multi-replica replication of log records between nodes.  Real
PAXOS leader election and all sorts of other goodness.  At that time in
Sleepycat's history we had a number of real customers (Google, Steam, etc.)
using our HA feature making it bullet proof.  So, in my mind not only was the
BTREE better and I'd have fun using features of BDB but there was a way forward
for a distributed SQL server -- a rare item at that time.  Exciting, to say the
least.  Was it perfect?  No.  But, it had legs and so I committed myself to
making it something we could consider selling.

Long story short, while Margo and Keith fully appreciated my work and the idea
they found fault in my approach.  They doubted the idea.  It wilted, and died
"on the vine" and such is history.  We, Sleepycat, acquired by Oracle had new
priorties.  Eventually at Oracle I connected with the Oracle Lite team and
learned about their obligations to companies and governments and their distain
for their own codebase.  I offered up a new idea, well really an old idea
remade.  I brokered a deal with SQLite via Dr. Hipp to build way that Berkeley
DB could be a storage engine for it much like MySQL.  SQLite wouldn't change
much, it would have an abstract storage layer and Berkely DB would be an engine
for SQLite.  And that looked good, but had no market appeal from within Oracle.
So that died as well.

Now, nearly 20 years later, SQLite is insanely popular and has been actively
developed and updated.  What I say about SQLite in this article has to do with
the version of that code back in 2009, not today.  [A lot has happened within
the SQLite
codebase](https://github.com/sqlite/sqlite/compare/master@%7B9/3/2009%7D...master)
- over 5,000 commits - since that crazy Winter on my Hans Christian 42.  What's
clear is that we, Sleepycat, made a mistake.  We should have gone all in on a
"SQL API" years ago.  I'm not sure we'd have won out against SQLite had we
done that, our corporate personality was different than their's and maybe that
was their greatest strength.  They adapted, they focused on customer needs and
kept it simple.  And they won.

But this post is about my win.  My work that Winter was awesome.  I am proud of
it.  I hope someone else spots it and learns something, or finds it useful, or
just reaches out to say hi.
