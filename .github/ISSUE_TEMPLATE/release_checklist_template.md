---
name: Release checklist
about: Keep track of the release activities
title: vXX.X Release Checklist
labels: ''
assignees: ''

---
/date

The following lists the actions to be taken by developers. For the full list of action taken by both release management and the developer team, please look at the documentation [here](https://github.com/mozilla-mobile/firefox-ios/wiki/Release-Checklist).

## Soft Freeze Items

- [ ]  Once release management has created the release branch, notify the team to aim new PRs at the updated fix version by updating the `Current PR Version` topic in the #ios-watercooler channel.
- [ ]  Back ports bug fixes commits towards the release branch. Make sure to mark any tickets you [back port](https://github.com/mozilla-mobile/firefox-ios/wiki/Release-Checklist/_edit#back-port) with the proper `fix version` field in the Jira ticket, and mention any particularities QA need to be careful about when testing. 
- [ ]  Update the PI request. Release management won't update the PI request with comments on what was back ported, so make sure you update the PI request with the latest information as well. Note that builds are preplanned each week to happen on Tuesday, Thursday and Sunday.
- [ ]  Update Security Advisories if needed (see Security Advisories [page](https://github.com/mozilla-mobile/firefox-ios/wiki/Security-Advisories).

### Notes for Hotfixes/Dot releases/Rapid releases

For hotfixes, dot releases or rapid releases release management can handle the PI request updates since the number of back ports are normally low. 

## Hard Freeze Items

- [ ]  Fix Release Blockers raised by the QA team. As QA regression tests, they'll open GitHub issues. Watch for new issues and ask Product which could be release blockers. After QA is done testing, you'll get a test report email indicating if the build is green/red. If it's red, there will be a list of critical issues that need to be addressed and back ported. See section about [back ports](https://github.com/mozilla-mobile/firefox-ios/wiki/Release-Checklist/_edit#back-port) for more information.
- [ ]  Monitor crash rate through Xcode and Sentry.
