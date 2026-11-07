---
name: firefox-coordinators
description: Firefox for iOS coordinator and router navigation conventions.
---

# Firefox coordinators

Coordinators own navigation flows and select who handles a `Route`. Routers perform push, pop, presentation, and dismissal. See `adr/0002-coordinators-for-navigation.md`.

Trace `canHandle`, `handle`, and `savedRoute` when changing routes. Child coordinators retain active flows; preserve their removal and `isDismissible` behavior.
