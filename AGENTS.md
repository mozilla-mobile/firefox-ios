## Global instructions

- When refactoring existing code, check relevant files for existing tests and update them if necessary.
- When adding new code, prefer to write easily mockable and testable code, and include tests where applicable.
- Limit the amount of comments you put in the code to a strict minimum. You should almost never add comments, except sometimes on non-trivial code, function definitions if the arguments aren't self-explanatory, and class definitions and their members.
- Do not remove existing comments unless they are directly related to what you are changing.

## Working Principles

1. Ask, don't assume. If something's unclear, ask before writing a line of code, minimizing silent guesses about intent, architecture, or requirements.
2. Provide the simplest solution first, and implement the minimum amount of code change for that to work. No abstractions or refactors that haven't been requested.
3. Don't touch unrelated code, and if a file isn't part of the current task, leave it.
4. Flag uncertainty explicitly or if you're not confident, say so before proceeding as confidence without certainty causes more damage than admitting a gap.

## Repository Structure

This is a monorepo containing three main projects:

- `firefox-ios/` - Firefox for iOS (main app, scheme: `Fennec`)
- `focus-ios/` - Firefox Focus for iOS (scheme: `Focus`)
- `BrowserKit/` - Shared Swift Package mostly used in Firefox

## Common Commands

### Build & Test

```bash
# Build for testing (Firefox)
fxios test
```

### JavaScript User Scripts

Needed to be ran whenever we make JavaScript changes.

```bash
npm run build   # production build
npm run dev     # watch mode with source maps
```

### Linting

SwiftLint runs automatically via Xcode build phases on the Client target. Install via `brew install swiftlint`. Configuration is in `.swiftlint.yml`.
SwiftLint also runs whenever code is pushed to the remote, using hooks.

### Pull requests

Pull requests needs to be opened with the provided `PULL_REQUEST_TEMPLATE`. Update relevant section.
GitHub ticket number can be found at the bottom of the JIRA ticket.

## Runbooks

- **Xcode version upgrade.** When bumping the Xcode version used by CI/local builds, follow [docs/xcode-upgrade.md](docs/xcode-upgrade.md).
