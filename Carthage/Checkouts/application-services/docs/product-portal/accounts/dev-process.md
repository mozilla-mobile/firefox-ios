---
id: dev-process
title: Development Process
sidebar_label: Development Process
---

We develop and deploy on a two-week iteration cycle.  Every two weeks we
cut a release "train" that goes through deployment to stage and into production.

* [Product planning](#product-planning)
* [Issue management](#issue-management)
  * [Milestones](#milestones)
  * [Waffle columns](#waffle-columns)
  * [Other labels](#other-labels)
  * [Bug triage](#bug-triage)
* [Checkin meetings](#checkin-meetings)
  * [Mondays at 08:30](#mondays-at-08-30)
  * [Mondays at 12:30](#mondays-at-12-30)
  * [Mondays at 13:00](#mondays-at-13-00)
  * [Tuesdays at 13:30](#tuesdays-at-13-30)
* [Code review](#code-review)
  * [Review Checklist](#review-checklist)
* [Tagging releases](#tagging-releases)
  * [What if the merge messes up the changelog?](#what-if-the-merge-messes-up-the-changelog)
  * [What if I already pushed a fix to `master` and it needs to be uplifted to an earlier train?](#what-if-i-already-pushed-a-fix-to-master-and-it-needs-to-be-uplifted-to-an-earlier-train)
  * [What if there are two separate train branches containing parallel updates?](#what-if-there-are-two-separate-train-branches-containing-parallel-updates)
* [Security issues](#security-issues)
  * [Filing security issues](#filing-security-issues)
  * [Making a private point-release](#making-a-private-point-release)

## Product Planning

Product-level feature planning is managed
in an AirTable board
alongside other work
for the Application Services team:

* [The app-services airtable board](https://airtable.com/tbl8uNZikl6DGUEUI/)

## Issue management

Most of our work takes place on [GitHub](https://github.com/mozilla/fxa).
We use labels and milestones to keep things organised.

Issue status is reflected by the following:

* The milestone indicates *when* we are working on this issue.
* The issue itself will have updates indicating *what* the next action is.
* The assignee, if any, indicates *who* is responsible for that action.

### Milestones

When we start working on a new sprint,
we create a corresponding
[milestone in github](https://github.com/mozilla/fxa/milestones)
and fill it with issues that should be closed in that sprint.

### Labels

We use labels to help categorize and identify issues. The label taxonomy is:

##### Bug Type/Status:
* **status:unconfirmed**
* **status:bug**
* **status:enhancement**
* **status:wontfix**
* **status:invalid**
* **status:duplicate**
* **Status:worksforme**
* **status:blocker**

##### Categories:
* **code quality**
* **perf**
* **security**
* **documentation**

##### Contributors:
* **good first issue**
* **help wanted**
* **help wanted (taken)** Since you can't assign an issue to someone who isn't in the organization

##### Skill labels should accompany any good first issue label:
* **skill:css**
* **skill:html**
* **skill:js**
* **skill:rust**
* **skill:database**

##### Blocked on another person/team/decision:
* **needs:discussion** There is an open question blocking this issue from moving forward
* **needs:legal**
* **needs:ops**
* **needs:product** Any product questions including missing content or copy
* **needs:qa**
* **needs:security**
* **needs:visuals**  UI is in place but doesn’t look right
* **needs:ux** Questions about flow, or user experience

##### Priority labels are based on [Bugzilla's triage process](https://mozilla.github.io/bug-handling/triage-bugzilla):
* **p1**
* **p2**
* **p3**
* **p5**

##### Project Tracking:
* **Epic** ZenHub uses this to track epics and we're exploring using ZenHub


### Bug Triage

We triage issues every week in our meetings.  Depending on the size of our
backlog, we may schedule other meetings focused solely on triaging older
issues.


## Checkin Meetings

The team meets regularly to stay in sync about development status and ensure
nothing is falling through the cracks.  During meetings we take notes and
afterward we send a summary of each meeting to an appropriate mailing list.

Please see our [project calendar](https://www.google.com/calendar/embed?src=mozilla.com_urbkla6jvphpk1t8adi5c12kic%40group.calendar.google.com) for details.

## Code Review

This project is production Mozilla code and subject to our [engineering practices and quality standards](https://developer.mozilla.org/docs/Mozilla/Developer_guide/Committing_Rules_and_Responsibilities).  Every patch must be [reviewed](https://developer.mozilla.org/docs/Code_Review_FAQ) by an owner or peer of the [Firefox Accounts module](https://wiki.mozilla.org/Modules/Other#Firefox_Accounts).

### Review Checklist

Here are some handy questions and things to consider when reviewing code for Firefox Accounts:

* How will we tell if this change is successful?
    * If it's fixing a bug, have we introduced tests to ensure the bug stays fixed?
    * If it's a feature, do we have metrics to tell whether it's providing value?
    * Should it be A/B tested to check whether it's a good idea at all?
* Did test coverage increase, or at least stay the same?
    * We need a pretty good reason to merge code that decreases test coverage...
    * If it's hard to answer this question, consider adding a test that tests the test coverage.
* Does it introduce new user-facing strings?
    * These strings will need to go through our localization process.  Check that the
      templates in which they're defined are covered by our string extraction scripts.
    * The code must be merged before the string-extraction date for that development cycle.
* Does it store user-provided data?
    * The validation rules should be explicit, documented, and clearly enforced before storage.
* Does it display user-controlled data?
    * It must be appropriately escaped, e.g. htmlescaped before being inserted into web content.
* Does it involve a database schema migration?
    * The changes must be backwards-compatible with the previous deployed version.  This means
      that you can't do something like `ALTER TABLE CHANGE COLUMN` in a single deployment, but
      must split it into two: one to add the new column and start using it, and second to
      drop the now-unused old column.
    * Does it contain any long-running statements that might lock tables during deployment?
    * Can the changes be rolled back without data loss or a service outage?
    * Has the canonical db schema been kept in sync with the patch files?
    * Once merged, please file an Ops bug to track deployment in stage and production.
* Does it alter the public API of a service?
    * Ensure that the chage is backwards compatible.
    * Ensure that it's documented appropriately in the API description.
    * Note whether we should announce it on one or more developer mailing lists.
* Does it add new metrics or logging?
    * Make sure they're documented for future reference.
* Does it conform to the prevailing style of the codebase?
    * If it introduces new files, ensure they're covered by the linter.
    * If you notice a stylistic issue that was *not* detected by the linter,
      consider updating the linter.
* For fixes that are patching a train,
  has the PR been opened against the correct train branch?
    * If the PR is against `master`,
      it is likely that it will mess up
      our change logs and the git history
      when merged.
    * If no appropriate train branch exists,
      one can be created at the appropriate point in history
      and pushed.
      After the patch has been tagged (see below),
      the train branch can then be merged to `master`.
      Commits should not be cherry-picked
      between train branches and `master`.

## Tagging releases

The release process is being [documented and reviewed](https://docs.google.com/document/d/1lAK-Wvmr7xPsVHIDVFhG5RlQKQQL1Z4NlhyCPLLq4-U/edit?ts=5cb8ba2d).  We'll update this official documentation when the details are sorted out.


### What if the merge messes up the changelog?

After merging but before pushing,
you should check the changelog to make sure
that the expected versions are listed
and they're in the right order.
If any are missing or the order is wrong,
manually edit the changelog
so that it makes sense,
using the commit summaries from `git log --graph --oneline`
to fill in any blanks as necessary.
Then `git add` those changes
and squash them into the preceding merge commit
using `git commit --amend`.
Now you can push
and the merged changelog will make sense.

### What if I already pushed a fix to `master` and it needs to be uplifted to an earlier train?

In this case,
it's okay to use `git cherry-pick`
because that's the only way to get the fix
into the earlier train.
However, after tagging and pushing the earlier release,
you should still merge the train branch back to `master`
so that future changelogs include the new release.

### What if there are two separate train branches containing parallel updates?

In this case,
the easiest way to keep the changelogs complete
and in the appropriate version order,
is to:

1. Merge from the earlier train branch
   into the later one.
   [Fix up the changelog](#what-if-the-merge-messes-up-the-changelog)
   if it needs it
   and then push the train branch.

2. Now merge from the later train branch
   into `master`.
   Again,
   remember to fix up the changelog before pushing
   if required.

## Security issues

Since most of our work happens in the open,
we need special procedures
for dealing with security-sensitive issues
that must be fixed in production
before being made visible to the public.

We use private bugzilla bugs
for tracking security-related issues,
because this allows us to manage visibility
for other stakeholders at Mozilla
while maintaining confidentiality.

We use private github repos
for developing security fixes
and tagging security-related releases.

### Filing security issues

If you believe you have found
a security-sensitive issue
with any part of the Firefox Accounts service,
please file it as confidential security bug
in Bugzilla via this link:

* [File a security-sensitive FxA bug](https://bugzilla.mozilla.org/enter_bug.cgi?product=Cloud%20Services&component=Server:%20Firefox%20Accounts&groups=cloud-services-security)

The Firefox Accounts service
is part of Mozilla's [bug bounty program](https://www.mozilla.org/security/bug-bounty/),
which provides additional guidelines
on [reporting security bugs](https://www.mozilla.org/security/bug-bounty/faq-webapp/#bug-reporting).

### Making a private point-release

We maintain the following private github repos
that can be used for making security-related point-releases

* https://github.com/mozilla/fxa-content-server-private
* https://github.com/mozilla/fxa-auth-server-private
* https://github.com/mozilla/fxa-auth-db-mysql-private
* https://github.com/mozilla/fxa-customs-server-private
* https://github.com/mozilla/fxa-js-client-private

The recommended procedure for doing so is:

* Check out the private repo, independently from your normal working repo:
  * `git clone git@github.com:mozilla/fxa-auth-server-private`
  * `cd fxa-auth-server-private`
  * N.B: Do not add it
    as a remote on your normal working repo,
    because this increases the risk
    of pushing a private fix to the public repo
    by mistake.
* Add the corresponding public repo as a remote named "public",
  and ensure it's up-to-date:
  * `git remote add public git@github.com:mozilla/fxa-auth-server`
  * `git fetch public`
* Check out the latest release branch and push it to the private repo:
  * `git checkout public/train-XYZ`
  * `git push origin train-XYZ`
* Develop your fix against this as a new branch in the private repo:
  * `git checkout -b train-XYZ-my-security-fix`
  * `git commit -a`
  * git push -u origin train-XYZ-my-security-fix`
* Submit and review the fix as a PR in the private repo,
  targetting the `train-XYZ` branch.
* Tag a point release in the private repo, following the [steps above](#tagging-releases):
  * `git checkout train-XYZ; git pull  # ensure we have the merged PR`
  * `grunt version:patch`
  * `git push`
* Push the tag in order to trigger a CircleCI build:
  * `git push origin v1.XYZ.N`
  * N.B: Do not use `git push --tags`
    as this will not correctly trigger
    the CircleCI build.
* File an issue on the public repo
  as a reminder to uplift the fix
  once it has been deployed to production.

Once the fix has been deployed
and is safe to reveal publicly,
it can be merged back into the public repo
by doing the following:

* Push the private train branch to the public repo,
  as a new branch:
  * `git push public train-XYZ:train-XYZ-uplift`
* Open a PR in the public repo,
  targeting the public `train-XYZ` branch,
  for review and merge.
* Push the tag to the public repo:
  * `git push public v1.XYZ.N`
* Merge the `train-XYZ` branch to master
  following the [usual steps](#tagging-releases).
