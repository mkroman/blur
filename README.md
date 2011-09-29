Blur
====
Blur is “just” another IRC-framework written in Ruby.

There are a bunch of other well-written, well-running IRC libraries made for
Ruby, but for me, they don't quite cut it as **the** library I wanted to use for
my IRC services, and thus Blur was born.

Blur's predecessor was known as Pulse. The main difference between them is
that Blur has non-blocking multi-network support.

Features
--------
  * Non-blocking (no threading)
  * Multi-network support
  * Extensible with scripts (during runtime, too)
  * SSL support (don't even bother using blur if this is what you're looking for)