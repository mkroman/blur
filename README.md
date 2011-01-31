Blur
====
Blur is “just“ another IRC-library written in Ruby.

There is a bunch of other well-written, well-running IRC libraries made for
Ruby, but for me, they don't quite qut it as **the** library I wanted to use for
my IRC services, and thus, Blur was born.

Blur's predecessor was known as Pulse, the main difference in the two pretty
much just is that Blur is non-blocking and have multi-network support.

Features
--------
  * Non-blocking (no threading)
  * Multi-network support
  * Extensible with scripts (during runtime, too)
  * SSL support (buggy as hell, though)

Documentation
-------------
If you've looked through the source code of Blur, you might've guessed I'm not
the biggest fan of documentation, I prefer self-documenting code (albeit
Blur's code can be a bit weird).

As of now, there is no documentation *whatsoever*. Although I will try to provide some
sort of documentation in the near future, but I can't promise anything.

Known Issues
------------
  1. When Blur is connected through a secure network it tends to block a long
     before it starts processing some data, this can cause it to time out.
  2. There is quite a lot of name collisions in Blur, for instance, in scripts
     theres a reference to the main client, which is a class variable defined
     in that script, named `@client`.
