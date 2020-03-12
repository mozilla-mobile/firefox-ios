## Metrics collected by Application Services components

Some application-services components collect telemetry using the [Glean SDK](https://mozilla.github.io/glean/).
This directory contains auto-generated documentation for all such metrics.

Products that send telemetry via Glean *must request* a data-review following
[the Firefox Data Collection process](https://wiki.mozilla.org/Firefox/Data_Collection)
before integrating any of the components listed below.

### Components that collect telemetry

* [logins](./logins/metrics.md)
* [places](./places/metrics.md)
