# 1. Modernize Logging Solution

Date: 2023-01-24

## Status

Accepted

## Context

Debugging issues encountered by users on production builds of Firefox for iOS is currently inefficient and unreliable. Our existing logging setup provides minimal visibility into user actions or application state leading up to a crash or bug. Logs are:
- Scattered across three separate log files (browser, sync, keychain).
- Produced through seven different mechanisms (XCGLogger, os_log, NSLog, print, and Sentry logs, among others).
- Noisy and inconsistent, often lacking actionable information about user actions or app flow.
- Difficult to retrieve, requiring users to manually share logs via a complex debug process.
- Unsupported, as the primary library (XCGLogger) is no longer maintained.

Additionally, our reliance on Sentry and Xcode crash reports limits visibility:
- Sentry only receives fatal-level logs due to rate limits.
- Xcode crash reports are delayed by 1–2 days post-release.
- Neither system provides contextual breadcrumbs for non-crash events or hangs.

Given upcoming large-scale refactors and the need for greater production observability, we must modernize our logging infrastructure to be comprehensive, privacy-safe, and actionable.

## Decision

We will modernize Firefox iOS logging by introducing a new local logging abstraction layer built on top of [SwiftyBeaver](https://github.com/SwiftyBeaver/SwiftyBeaver), with selective Sentry integration for critical and aggregated logs. Sentry will receive breadcrumbs so we can debug the current context when we have a crash.

This approach focuses first on improving local log quality, consistency, and accessibility. Once local reliability and structure are established, the team can explore partial cloud ingestion for Beta/Nightly builds if we wish.

## Consequences

### Positive
- Unified, modern, and privacy-safe logging across the app.
- Consistent log levels, categories, and formatting improve readability and searchability.
- Reduces technical debt by removing XCGLogger and consolidating disparate logging systems.

### Negative
- Privacy risk if new logging guidelines are not strictly followed.
- No access to logs remotely, apart than users sending us their log files or through breadcrumbs in Sentry.

## References
- [Logging investigation](https://docs.google.com/document/d/1mF7cJN0JdLD8lVCs3t1_4QT9TodrCniYZvo8Gsi6nv8/edit?usp=sharing)
- [Logging strategy](https://github.com/mozilla-mobile/firefox-ios/wiki/Logging-Strategy)
- [SwiftyBeaver](https://github.com/SwiftyBeaver/SwiftyBeaver)