---
name: Release checklist
about: Keep track of the release activities
title: vXX.X Release Checklist
labels: ''
assignees: ''

---
/date

## [Soft Freeze Items](https://github.com/mozilla-mobile/firefox-ios/wiki/Release-Checklist-(Devs)#soft-freeze-steps)

- [ ]  Create version branch
- [ ]  Push version branch to Mozilla's remote
- [ ]  Update Bitrise version in both `main` and release branch
- [ ]  Update versions of .plist with script on release branch
- [ ]  Push release branch to mozilla’s remote
- [ ]  [String import](https://github.com/mozilla-mobile/firefox-ios/wiki/Localization-Process#github-action-import-process) through Github action
- [ ]  Notify the team to aim new PRs at the updated fix version. Send that communication out in a channel with Engineering, QA, Product & Design.

## [Soft Freeze Optional](https://github.com/mozilla-mobile/firefox-ios/wiki/Release-Checklist-(Devs)#optional-on-soft-freeze-day-steps)

These items should be completed as soon as possible, preferably on soft codefreeze day. Due to timing issues, they may not be available until hard codefreeze, and must be completed on hard freeze.

- [ ]  File P.I. request
- [ ]  Check for [security advisories](https://github.com/mozilla-mobile/firefox-ios/wiki/Release-Build-Checklist/#security-advisories)
- [ ]  [String import](https://github.com/mozilla-mobile/firefox-ios/wiki/Localization-Process#github-action-import-process) mid Beta cycle through Github action by pointing to the specific release branch
- [ ]  Send beta build to external beta testers

See [Release build checklist wiki](https://github.com/mozilla-mobile/firefox-ios/wiki/Release-Checklist-(Devs)) for more detailed instructions.

## Hard Freeze Items

- [ ]  Do a final string import to the release branch
- [ ]  Tag release in GitHub (Eng task)
    - [ ]  Link to commit diff between versions
    - [ ]  Add volunteer contributions
- [ ]  Release Notes updated in App Store Connect
- [ ]  Get App Store screenshots and all locales if necessary
- [ ]  Copy translations from SUMO what's new for a given version, into the Release Description.
- [ ]  Submit build to Apple
- [ ]  Release with 7-day rollout
- [ ]  Monitor crash rate through Xcode and Sentry

See [Release build checklist wiki](https://github.com/mozilla-mobile/firefox-ios/wiki/Release-Checklist-(Devs)) for more detailed instructions.
