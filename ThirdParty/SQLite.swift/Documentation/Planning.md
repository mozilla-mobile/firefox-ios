# SQLite.swift Planning

This document captures both near term steps (aka Roadmap) and feature requests.
The goal is to add some visibility and guidance for future additions and Pull Requests, as well as to keep the Issues list clear of enhancement requests so that bugs are more visible.

## Roadmap

_Lists agreed upon next steps in approximate priority order._

## Feature Requests

_A gathering point for ideas for new features. In general, the corresponding issue will be closed once it is added here, with the assumption that it will be referred to when it comes time to add the corresponding feature._

### Features

 * encapsulate ATTACH DATABASE / DETACH DATABASE as methods, per [#30](https://github.com/stephencelis/SQLite.swift/issues/30)
 * provide separate threads for update vs read, so updates don't block reads, per [#236](https://github.com/stephencelis/SQLite.swift/issues/236)
 * expose triggers, per [#164](https://github.com/stephencelis/SQLite.swift/issues/164)

## Suspended Feature Requests

_Features that are not actively being considered, perhaps because of no clean type-safe way to implement them with the current Swift, or bugs, or just general uncertainty._

 * provide a mechanism for INSERT INTO multiple values, per [#168](https://github.com/stephencelis/SQLite.swift/issues/168)
