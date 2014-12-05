Client
======

This is a work in progress on some early ideas.  Don't get too attached to this code. Tomorrow everything will be different.

Important Note
==============

Because the iOS version of the client-side Firefox Accounts and Firefox Sync code is not in a good state yet, this application currently uses a server-side proxy towards Firefox Sync that allows us to obtain sync data using a *simpler but less secure method* from the iOS app. You can find this proxy project at [moz-syncapi](https://github.com/st3fan/moz-syncapi).

This is a *temporary* solution that we have been using to more easily get to sync data in *test accounts*. It has allowed us to test out some ideas more easily. This proxy is *not meant for production usage* and just a tool for early development that will *go away* when the client-side sync code is more complete.

> We have currently limited access to this proxy to just our development team and testers. That means that you currently cannot login to the iOS app and see your data unless you run your own copy of the proxy sync server.
