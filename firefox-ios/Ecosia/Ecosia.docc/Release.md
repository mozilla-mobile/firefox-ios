# Release notes & publishing — Ecosia iOS

Overview

Release notes are authored in fastlane metadata and synced to Transifex for translation. The team uses Confluence for the full release checklist.

Update release notes (en-US)

1. Branch from `main`.
2. Edit `fastlane/metadata/en-US/release_notes.txt`.
3. Open a PR and merge (Squash & Merge).
4. The Transifex integration will create/update translations and a PR with translated release notes.
5. Merge the translated PR. A GitHub Actions workflow uploads release notes to App Store Connect.

Manual upload (if needed)

```bash
bundle exec fastlane deliver --app-version <version>
```

Notes

- Ensure an active version exists in App Store Connect before uploading notes.