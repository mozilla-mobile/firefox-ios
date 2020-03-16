---
title: Canned Bug Responses
---

This page contains some canned responses the Sync team may use when replying to
new bug reports.

Often it will be necessary to tweak the comments.

## Closing bugs when there's been no needinfo response

Thanks again for reporting this issue, but we are unable to determine
the cause of the problem without the requested information. If you are
able to provide this information, please just add a comment in this bug
with that information and we'll get back to you as soon as we can, but
in the meantime we are closing this bug so we can focus on the issues
which we can address.

## Desktop

Note that the [bug filing guide for Desktop](sync/file-desktop-bug.md) contains
instructions for extracting logs etc. In general, we should probably
improve this page rather than going into more detail in the canned
responses below.

### When it's a known dupe

We're sorry to hear you are having this problem. We've seen a number of
reports like this, but we are unable to determine exactly what causes
it. In the meantime I'm closing this as a duplicate of the bug where we
are tracking this work and please accept our apologies for the problems
you are having.

### When an error log is expected

We're sorry to hear you are having this problem, but thanks very much
for taking the time to make this report. We aren't sure what is causing
this issue, but Sync does keep some logs which may help us find the
problem. Instructions for how to locate and attach the logs can be found
at [\<https://mozilla.github.io/application-services/docs/sync/file-desktop-bug.html\>](sync/file-desktop-bug.md) -
please follow those instructions and attach the sync logs to this bug.

Again, thanks for the report and thanks for your help in finding these
kinds of issues.

### When success logs are probably necessary

We're sorry to hear you are having this problem, but thanks very much
for taking the time to make this report. We aren't sure what is causing
this issue, but Sync does keep some logs which may help us find the
problem. Instructions for how to locate and attach the logs can be found
at [\<https://mozilla.github.io/application-services/docs/sync/file-desktop-bug.html\>](sync/file-desktop-bug.md) -
and in particular, follow the instructions for enabling "success" logs,
then reproduce your issue (eg, perform a new sync), and attach any new
logs which then appear.

### When detailed (i.e., "Trace") logs are probably necessary

We're sorry to hear you are having this problem, but thanks very much
for taking the time to make this report. We aren't sure what is causing
this issue. Sync does keep some logs which may help us find the problem
but in this case it appears we need more detailed logs than Sync
provides by default. Instructions for how to provide these detailed logs
can be found at
[\<https://mozilla.github.io/application-services/docs/sync/file-desktop-bug.html#get-detailed-sync-logs\>](sync/file-desktop-bug.md#get-detailed-sync-logs).
Once you've done that, please attach the logs as described on that page.

### When `about:sync` is probably needed to help

Thanks for the report. To help us determine the cause of this issue,
could you please install the about-sync addon from
<https://addons.mozilla.org/en-US/firefox/addon/about-sync/>. This addon
will let you view all of the data stored on the Sync servers.

For this particular issue, please [... - hard to make this canned yet -
eg, "select the 'passwords' collection, find the login and check the
password is what you expect]

Again, thanks for the report and thanks for your help in finding the
root cause of this problem.

## Android

Note that ["How to file a good Android Sync bug"](
http://160.twinql.com/how-to-file-a-good-android-sync-bug)
contains some instructions - but we should probably copy that content
here like we did for desktop.

## New contributors/good-first-bug

### Appears to not know where to start

Thanks for your interest in helping make Firefox awesome! The first step
is to follow the guide at
<https://developer.mozilla.org/en-US/docs/Mozilla/Developer_guide/Introduction>
to learn how to build Firefox. Once you have done this you will have all
of the files needed in a local checkout and it will be some of these
files that will need to be changed. Please let us know in thus bug when
you have got a Firefox build running locally and we'll give you some
additional pointers for how to solve this bug.

