---
id: file-desktop-bug
title: Filing a Desktop bug
---

We always appreciate it when users let us know about problems they’re
experiencing with Sync because it means we can improve it! Here are some
guidelines on how to file a good Sync bug:

### Get the Sync log on the machine you’re having problems

1.  In the Firefox address bar, type `about:sync-log` and press
    Enter. A list of Sync logs should appear.
2.  Find the last log file entry in the list and click on it. It should
    be called something like `error-sync-1307991874508.log`.
3.  Save it to a file on disk so you can upload to the bug later.
4.  If the list in step 2 is empty or only contains outdated logs (you
    can tell by the dates), go to `about:config`, find the
    `services.sync.log.appender.file.logOnSuccess` preference, set it
    to true, and sync again. Then repeat these steps (although the
    filename will now be called something like
    `success-sync-1307991874508.log`).

### Get detailed Sync logs

Occasionally you may be asked to provide detailed logs (aka "Trace
logs").

> **Note that these logs may include personal information**, such
> as the URLs of tabs you have open or that you have bookmarked. If this
> level of detail concerns you, please ask in the bug that it be changed
> to "Mozilla Confidential" *before* you upload the logs. This will ensure
> that only Mozilla employees have access to this data.

The easiest way to get these logs is via the [About Sync
addon](https://addons.mozilla.org/en-US/firefox/addon/about-sync/). You
should:

-   Install the above addon.
-   Enter `about:sync` into your address bar.
-   At the top of the `about:sync` page, change the
    `Level of messages written by Sync engines` setting to `Trace` and
    `Level of messages written to about:sync-logs log files` to `Trace`.
-   Just below those settings, check the option
    `Create log files even on success?`
-   Reproduce your issue (e.g., force a new sync)
-   Grab the log files - near the top of the `about:sync` page, use
    either the `download a combined summary` (preferred) or
    `download them as a zip file` links, which will download a file to
    your Downloads directory.
-   Attach this file to a bug.

### File a bug

1.  Even if you’ve found an existing bug that may look like the one
    you’re experiencing, do not add your comments to it. Please always
    [file a new
    bug](https://bugzilla.mozilla.org/enter_bug.cgi?product=Firefox&component=Sync),
    we will dupe it appropriately once we’ve determined the root issue.
    If you want, you can clone the existing bug or make a
    cross-reference to it in the summary.
2.  Attach the log file(s) you saved earlier to the bug by uploading an
    attachment. Do not copy & paste the text into the comment field, it
    won’t hold enough text!

We’re hoping to automate much of this in upcoming versions of Firefox,
so that a Sync problem can automatically be reported to us, or at least
with just a few clicks. In the meantime, the [About Sync
addon](https://addons.mozilla.org/en-US/firefox/addon/about-sync/)
offers a facility for creating a .zip file with all your Sync logs which
might be helpful.

### Other/Advanced information

#### Capturing logs from stdout

In unusual cases, such as Firefox crashing during a sync, Firefox may
not manage to save the logs to a file, so it may be necessary to grab
logs from stdout. This is a fairly advanced operation, so please don't
feel bad if you are unable to grab these logs. The steps you should
follow are:

1.  Use `about:config` to set the following properties:
    -   `browser.dom.window.dump.enabled = true`
    -   `services.sync.log.appender.dump = Trace`
    -   `services.sync.log.logger.engine = Trace`
    -   `services.sync.log.logger = Trace`
    > Note that all the above preferences should already exist - they
    > just have different default values.

2.  Quit Firefox and ensure no other Firefox instances are running.

3.  Determine where Firefox is installed on your system.
    > * On Windows, it's most likely in `C:\Program Files\Mozilla Firefox`.
    > * On macOS, it's probably in `/Applications/Firefox.app`.
    > * If you are running Linux, hopefully you already know how to locate this.

4.  Open a command line.
    > * On Windows, you should be able to find a `Command Prompt` icon in your
        start menu.
    > * On macOS, you can use `/Applications/Utilities/Terminal.app`.

5.  Execute the following command:
    > * On Windows:
        `"c:\Program Files\Mozilla Firefox\Firefox.exe" -console 2>&1 > c:\temp\firefox-log.txt`
    > * On Mac:
        `/Applications/Firefox.app/Contents/MacOS/firefox-bin 2>&1 > /tmp/firefox-log.txt`
    > * Note that in both cases you may need to adjust some paths
        accordingly - both the path to the binary and the path where you
        want the log file written.

6.  Reproduce your problem, then exit Firefox.

7.  The log file specified above (ie, `c:\temp\firefox-log.txt` or
    `/tmp/firefox-log.txt` in the above examples) should contain the log
    output.

### Credits

Thanks to [philiKON](https://mozillians.org/en-US/u/philiKON/) for his earlier
work on Sync itself and for the initial version of this text.
