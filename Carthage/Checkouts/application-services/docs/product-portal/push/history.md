---
id: history
title: History
---

The Push Service was originally developed in Go, utilizing a websocket
connection from [Firefox OS][fxos] to the Push service. It was
deployed in 2013
with the legacy [SimplePush DOM
API](https://developer.mozilla.org/en-US/docs/Web/API/Simple_Push_API) that runs
under [Firefox OS][fxos]. This API only supported incrementing version numbers,
to wake a device so that it could check with an Application Server to determine
what to display.

In 2015 the Push Service was rewritten in Python, and added preliminary
[WebPush][wp] support for carrying data in push messages. The underlying
protocol used between [Firefox][ffx] and the Push Service is an extended
[SimplePush Protocol](design.md#simplepush-protocol) utilizing a websocket protocol that will eventually be
deprecated in favor of a specification compliant [WebPush][wp] HTTP 2.0
protocol.

With the release of [RFC 8030](https://tools.ietf.org/html/rfc8030), Simplepush support was deprecated. 

In 2017, a prototype of the Push connection node was written in Rust with bindings
to a Python extraction of the logic. By early 2018 the connection node logic was
ported entirely to Rust and a [Rust connection node][autopush-rs] was put into production
service. The Rust port drastically lowered CPU usage, and reduced the per-client
memory consumption to slightly less than 10Kb.

[autopush-rs]: https://github.com/mozilla-services/autopush-rs
[wp]: https://webpush-wg.github.io/webpush-protocol/
[fxos]: https://www.mozilla.org/en-US/firefox/os/
[ffx]: https://www.mozilla.org/en-US/firefox/
