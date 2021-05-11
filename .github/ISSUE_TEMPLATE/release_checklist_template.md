---
name: Release checklist
about: Keep track of the release activities
title: vXX.X Release Checklist
labels: ''
assignees: ''

---
Soft freeze:   
Hard freeze: 

Branch setup, steps typically done when creating new version branch:
- [ ] Update Version Number in code (Eng task, use `update_version.sh`)
- [ ] Update `Client/Info.plist` MozWhatsNewTopic (Eng task)
- [ ] Create version specific Sentry project
- [ ] Update SENTRY_DSN secret in Bitrise (per release)
- [ ] Add Bitrise trigger for release branch 
---
- [ ] Ensure string export was completed for L10N (if needed)
- [ ] Check for [security advisories](https://github.com/mozilla-mobile/firefox-ios/wiki/Release-Build-Checklist/#security-advisories) 
- [ ] Tag release in GitHub (Eng task)
    - [ ] Link to commit diff between versions
    - [ ] Add volunteer contributions
- [ ] File P.I. request
- [ ] Release Notes updated
- [ ] Submit build to Apple
- [ ] Get App Store screenshots and all locales if necessary
- [ ] Release with 7-day rollout

See [Release build checklist wiki](https://github.com/mozilla-mobile/firefox-ios/wiki/Release-Build-Checklist) for more detailed instructions.
