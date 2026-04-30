# 9. Feature Flags Refactor

Date: 2026-04-29

## Status

Accepted

## Context

The previous feature flag system has begun to show limitations that are impacting
development, from a developer ergonomics as well as a unit testing point of view. In
particular:

- There seemed to be confusion in regards to when to use specific `buildOnly`, `buildAndUser`
  and `userOnly` tags for checks.
- Testing features behind feature flags was confusing and messy, resulting in three
  different ways in which tests were implemented.
- Testing features in UI tests was difficult because the feature flag system was coupled
  to the Nimbus sysem in problematic way for the build.

A new feature flag system implementation was proposed and accepted, and has been completed
as of 2026-04-26.

The primary forces influencing this decision are:

- The need for **long-term maintainability** of tests that involve feature flags.
- The need for easily testing features behind feature flags in **both unit and UI tests**
- The need to **more clearly communicate intent** when using feature flags in the codebase

## Decision

A proposal was put forward, and accepted, for how to improve the feature flag system. The
new system has several key improvements/features over the older system:

- Separates areas of responsibility into separate components (core feature flags, feature
  flags from a backend, and user preferences in regards to feature flags)
- This separation allows us to abstract what backend is used by adding a layer between
  our implementation and whatever backend is currently acting as a remote source of truth.
- This separation further allows significantly easier testing of features behind feature
  flags by providing the ability to mock not only the backend layer, but also both the
  feature flag provider and the user feature preference layer.

## Consequences

**Positive outcomes:**

- Intent of what we're checking in the codebase for each flag check is clear
- Simplified testing setup ensures better coverage for feature flags
- Simplified interfaces mean less developer confusion about usage and testing

**Negative or neutral outcomes:**

- Team members will need to learn new patterns for using and testing feature flags
- Current tests that are not following this pattern must be updated
