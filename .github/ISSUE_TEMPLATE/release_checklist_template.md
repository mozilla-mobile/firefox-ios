---
name: Release checklist
about: Keep track of the release activities
title: vXX.X Release Checklist
labels: ''
assignees: ''

---
Soft freeze:
Hard freeze:

## Soft Freeze Items
- [ ] Update Version Number in code (Eng task, use `update_version.sh`)
- [ ] Update `Client/Info.plist` MozWhatsNewTopic (Eng task)
- [ ] Create version specific Sentry project
- [ ] Update SENTRY_DSN secret in Bitrise (per release)
- [ ] Add Bitrise trigger for release branch

### Soft Freeze Optional
These items should be completed as soon as possible, preferrably on soft code
freeze day. Due to timing issues, they may not be available until hard code
freeze, and must be completed on hard freeze.

- [ ] Ensure string export was completed for L10N (if needed)
- [ ] Check for [security advisories](https://github.com/mozilla-mobile/firefox-ios/wiki/Release-Build-Checklist/#security-advisories)
- [ ] File P.I. request

## Hard Freeze Items

- [ ] Tag release in GitHub (Eng task)
    - [ ] Link to commit diff between versions
    - [ ] Add volunteer contributions
- [ ] Release Notes updated
- [ ] Get App Store screenshots and all locales if necessary
- [ ] Submit build to Apple
- [ ] Release with 7-day rollout

See [Release build checklist wiki](https://github.com/mozilla-mobile/firefox-ios/wiki/Release-Build-Checklist-Details) for more detailed instructions.
