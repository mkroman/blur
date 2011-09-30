Blur
====
Blur is an event-driven IRC-framework written in and for Ruby.

There are a bunch of other well-written, well-running IRC libraries made for
Ruby, but for me, they don't quite cut it as **the** library I wanted to use for
my IRC services. That's how Blur came to be.

Blur scales. A lot.

When I stresstested the library on my network, I ended up throttling my VDSL
connection before Blur even broke a sweat - albeit I only have 20/2.

I managed to connect with 5000 clones before it couldn't resolve the hostname
anymore, while this is an excellent feature, I would not suggest doing it.

Features
--------
  * SSL/TLS encryption
  * Connect to multiple networks
  * FiSH (channel-wide) encryptions
  * Non-blocking connections (no threading)
  * Extensible with scripts, (re)loadable during runtime
  * Modular, makes it a piece of cake to extend its IRC-capability

Future Plans
------------
  * DCC File-transfers
  * DH1080 Key-Exchange
  * ISupport implementation
  * Better event-handling in scripts