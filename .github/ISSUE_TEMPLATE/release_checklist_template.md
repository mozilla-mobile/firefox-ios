---
name: Release checklist
about: Keep track of the release activities
title: vXX.X Release Checklist
labels: ''
assignees: ''

---

- [ ] Check for [security advisories](https://github.com/mozilla-mobile/firefox-ios/wiki/Release-Build-Checklist/#security-advisories) 
- [ ] Update Version Number in code (Eng task)
- [ ] Update `Client/Info.plist` MozWhatsNewTopic (Eng task)
- [ ] Tag release in GitHub (Eng task)
- [ ] Create version specific Sentry project
- [ ] Setup Sentry keys in BuddyBuild (per release)
- [ ] File P.I. request
- [ ] Release Notes updated
- [ ] Submit build to Apple (Select YES to IDFA, 'Attribute this app installation to a previously served advertisement')
- [ ] Release with 7-day rollout 

See [Release build checklist wiki](https://github.com/mozilla-mobile/firefox-ios/wiki/Release-Build-Checklist) for more detailed instructions.
