# Testing

> Full snapshot testing guide for humans: [Ecosia/Ecosia.docc/SNAPSHOT_TESTING_WIKI.md](../SNAPSHOT_TESTING_WIKI.md)

## Requirements

- **MANDATORY**: Include tests when writing new code or implementing features
- Use Given/When/Then structure with minimal, relevant comments only
- Write unit tests using XCTest for business logic
- Place tests in `firefox-ios/EcosiaTests/` with clear file organization
- Place mocks in `firefox-ios/EcosiaTests/Mocks/`
- Test plan: `firefox-ios/EcosiaTests/UnitTest.xctestplan`

## Unit Tests

- Create testable implementations with injectable dependencies
- For protocol default implementations: verify actual dependencies are called, not mock call counts
- Test all accessibility features and edge cases
- Test performance scenarios and memory usage
- Follow TDD principles where appropriate

## Snapshot Tests

- Use `SnapshotBaseTests` base class with proper theme setup
- Config: `firefox-ios/EcosiaTests/SnapshotTests/snapshot_configuration.json`
- See `Ecosia/Ecosia.docc/SNAPSHOT_TESTING_WIKI.md` for full guide

## Analytics Testing

- `Analytics.shared` must not be reassigned outside tests (SwiftLint custom rule)

## Running Tests

- Run via Xcode: `Cmd+U` with the **EcosiaBeta** scheme
- CI runs tests via GitHub Actions
