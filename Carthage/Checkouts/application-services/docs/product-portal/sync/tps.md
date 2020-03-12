---
title: TPS
---

TPS is an end to end test for Sync. Its name stands for Testing and
Profiling tool for Sync (which is a misnomer, since it doesn't do any
profiling), and it should not be confused with the [similarly named
tests in Talos](https://wiki.mozilla.org/Buildbot/Talos/Tests#tps).

TPS consists of a Firefox extension of the same name, along with a
Python test runner, both of which live inside `mozilla-central`. The
Python test runner will read a test file (in JavaScript format), setup
one or more Firefox profiles with the necessary extensions and
preferences, then launch Firefox and pass the test file to the
extension. The extension will read the test file and perform a series of
actions specified therein, such as populating a set of bookmarks,
syncing to the Sync server, making bookmark modifications, etc.

A test file may contain an arbitrary number of sections, each involving
the same or different profiles, so that one test file may be used to
test the effect of syncing and modifying a common set of data (from a
single Sync account) over a series of different events and clients.

Set up an environment and run a test
------------------------------------

To run TPS, you should [create a new Firefox
Account](https://accounts.firefox.com/) using a
[restmail.net](http://restmail.net/) email address (Strictly speaking,
restmail isn't required, but it will allow TPS to automatically do
account confirmation steps for you.

> Even if you opt not to use restmail, **do not** use your personal Firefox
> account, as TPS will delete and replace the data in it many times, not to
> mention the first run is very likely to fail, since it expects a clean start.

Note: Be prepared not to use your computer for 15 or so minutes after
starting a full run of TPS, as it will open and close a fairly large
number of Firefox windows. Headless mode makes this easier.

### Steps

1.  Clone `mozilla-central` to get the source code.

    > Choose your flavor:
    > ```bash
    > hg clone hg.mozilla.org/mozilla-central
    > ```
    > or
    > ```bash
    > git clone github.com/mozilla/gecko-dev
    > ```

2.  cd into the TPS folder

    > ```bash
    > cd testing/tps
    > ```

3.  Create the environment

    > I suggest the path to be outside of the m-c source tree:
    > ```bash
    > Python create_venv.py --username=%EMAIL% --password=%PASSWORD% %PATH%
    > ```

4.  Activate the environment

    > ```bash
    > source %PATH%/bin/activate
    > ```

5.  Run some tests

  > Note that the `testfile` option is **not** a path, it should only be the
  > filename from `services/sync/tests/tps/`.
  > ```bash
  > runtps --debug --testfile %TEST_FILE_NAME% --binary %FIREFOX_BINARY_PATH%
  > ```
  > 1.  Additionally, omitting a `--testfile` parameter will cause TPS to
  >     run all tests listed in
  >     `services/sync/tests/tps/all_tests.json`
  > 2.  You can also prefix with `MOZ_HEADLESS=1` to run in [headless
  >     mode](https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Headless_mode) (recommended)

An example on macOS, for headlessly running just the `test_sync.js`
testfile against a locally built Firefox (where the mozconfig set the
objdir to `obj-ff-artifact`):

```bash
MOZ_HEADLESS=1 runtps --debug --testfile test_sync.js --binary obj-ff-artifact/dist/Nightly.app/Contents/MacOS/firefox
```

Running TPS against stage, or dev FxA
-------------------------------------

TPS can be configured using the `$TPS_VENV_PATH/config.json` file. In
particular, it will set preferences from the `"preferences"` property,
and so you can set the `"identity.fxaccounts.autoconfig.uri"` preference
to point to any FxA server you want. For example, a (partial) TPS config
for testing against stage might look like:

```js
{
  // ...
  "fx_account": {
    "username": "foobar@restmail.net",
    "password": "hunter2"
  },
  "preferences": {
    // use "https://stable.dev.lcip.org" for dev instead of stage
    "identity.fxaccounts.autoconfig.uri": "https://accounts.stage.mozaws.net"
    // possibly more preferences...
  },
  // ...
}
```

Note that in this example, the `foobar@restmail.net` account must be
registered on stage, otherwise authentication will fail (and the whole
test will fail as well.  You can sign up for an FxA account on stage or
dev by creating an FxA account after adding
the `identity.fxaccounts.autoconfig.uri` preference (with the
appropriate value) to `about:config`. Additionally, note that the config
file must parse as valid JSON, and so you can't have comments in it
(sorry, I know this is annoying). One alternative is to put underscores
before the "disabled" preferences, e.g.
`"_identity.fxaccounts.autoconfig.uri": "..."`.

Writing TPS tests
-----------------

Each TPS test is run as a series of "phases". A phase runs in some
Firefox profile, and contains some set of actions to perform or check on
that profile. Phases have an N to M relationship with profiles, where N
\>= M (there can never be more phases than profiles). Typically there
are two profiles used, but any number of profiles could be used in
theory (other than 0).

After the phases run, two additional "cleanup" phases are run, to
unregister the devices with FxA. This is an implementation detail, but
if you work with TPS for any amount of time you will almost certainly
see `cleanup-profile1` or similar in the logs. That's what that phase is
doing, it does any necessary cleanup for the phase, primarially
unregistering the device associated with that profile.

TPS tests tend to be broken down into three sections, in the following
order (we'll cover these out of order, for the sake of simplicity)

1.  Phase declarations (mandatory).
2.  Data definitions/asset list (optional, but all current tests have
    them).
3.  Phase implementation (mandatory)

It's worth noting that some parts of TPS assume that it can read the
number off the end of the phase or profile to get to the next one, so
try to stick to the convention established in the other tests. Yes, this
is cludgey, but it's effective enough and nobody has changed it.

### Phase Declarations

These map the phases to profiles. Both Python and JavaScript read them
in. They ***must*** look like:

```js
var phases = { "phase1": "profile1", "phase2": "profile2", "phase3": "profile1" };
```

Between `{` and `}` it must be ***strict JSON***. e.g. quoted keys, no
trailing parentheses, etc. The Python test runner will be parsing it with
an unforgiving call to `json.loads`, so anything other than strict JSON
will fail.

You can use as many profiles or phases as you need, but every phase you
define later must be declared here, or it will not be run by the Python
test runner. Any phases declared here but not implemented later will
cause the test to fail when it hits that phase.

### Asset lists

A test file will contain one or more asset lists, which are lists of
bookmarks, passwords, or other types of browser data that are relevant
to Sync. The format of these asset lists vary somwhat depending on asset
type.

#### Bookmarks

A bookmark asset list is an object with one or more key-value pairs.
Each key is the full path for the array of contents specified in the
key's value. For example:

    var bookmarks_after_second_modify = {
      "menu": [
        { uri: "http://www.getfirefox.com/",
          title: "Get Firefox"
        }
      ],
      "menu/foldera": [
        { uri: "http://mozilla.com",
          title: "Mozilla"
        },
      ]
    };

This describes two bookmarks, one in the "menu" folder, and the other in
the "folder1" subfolder of "menu".

All bookmark paths must begin with one of the following:

-   `menu`: the normal bookmarks menu
-   `toolbar`: the bookmarks toolbar
-   `tags`: the tags root folder
-   `unfiled`: the "Other Bookmarks" folder
-   `mobile`: the "Mobile Bookmarks" folder
-   `places`: the places root folder (`menu`, `toolbar`, `tags`, `unfiled`,
    and `mobile` are all children of this)

Subfolders are preceded with forward slashes, so "menu/folder1" denotes
that "folder1" is a subfolder of "menu". TPS does not support forward
slashes as part of a folder name.

##### Folder contents

The contents for a folder are given as an array of objects, representing
various bookmark types, described below.

###### Bookmark objects

Valid properties are:

-   `uri`: the bookmark uri. Required.
-   `title`: the bookmark title. Optional. Defaults to
    the bookmark uri.
-   `tags`: an array of tags for the bookmark. Optional.
-   `keyword`: the keyword for the bookmark. Optional.
-   `after`: the title of the bookmark item expected to
    be found **after** this bookmark; used only in `verify`
    and `modify` actions.
-   `before`: the title of the bookmark item expected to
    be found **before** this bookmark; used only in `verify`
    and `modify` actions.
-   `changes`: an object containing new properties to be
    set for this bookmark when this asset list is used in a
    `modify` action. The properties for this object
    include the `uri, title, tags, keyword` properties above,
    plus two additional properties:
    -   `location`: the full path of the folder that the
        bookmark should be moved to
    -   `position`: the title of the existing bookmark
        item, in the current folder, where this bookmark should be moved
        to (i.e., this bookmark would be inserted into the bookmark list
        at the position of the named bookmark, causing that bookmark to
        be positioned below the current one)

Example:

```js
{ uri: "http://www.google.com",
  title: "Google",
  tags: [ "google", "computers", "misc" ]
}
```

###### Livemark objects

Valid properties are:

-   `livemark`: the livemark name. Required.
-   `siteURI`: the livemark's uri. Optional.
-   `feedURI`: the livemark's feed uri. Required.
-   `after`: the title of the bookmark item expected to
    be found **after** this livemark; used only in `verify`
    and `modify` actions.
-   `before`: the title of the bookmark item expected to
    be found **before** this livemark; used only in `verify`
    and `modify` actions.
-   `changes`: an object containing new properties to be
    set for this livemark when this asset list is used in a
    `modify` action. The properties for this object
    include the `livemark, siteURI, feedURI` properties
    above, plus two additional properties:
    -   `location`: the full path of the folder that the
        livemark should be moved to
    -   `position`: the title of the existing bookmark
        item, in the current folder, where this livemark should be moved
        to (i.e., this livemark would be inserted into the bookmark list
        at the position of the named bookmark, causing that bookmark to
        be positioned below the current one)

Example:

```js
{ livemark: "LivemarkOne",
  feedUri: "http://rss.wunderground.com/blog/JeffMasters/rss.xml",
  siteUri: "http://www.wunderground.com/blog/JeffMasters/show.html"
}
```

###### Folder objects

Valid properties are:

-   `folder`: the folder's name. Required.
-   `after`: the title of the bookmark item expected to
    be found **after** this folder; used only in `verify` and
    `modify` actions.
-   `before`: the title of the bookmark item expected to
    be found **before** this folder; used only in `verify`
    and `modify` actions.
-   `changes`: an object containing new properties to be
    set for this folder when this asset list is used in a
    `modify` action. The properties for this object
    include the `folder`, plus two additional properties:
    -   `location`: the full path of the folder that this
        folder should be moved to
    -   `position`: the title of the existing bookmark
        item, in the current folder, where this folder should be moved
        to (i.e., this folder would be inserted into the bookmark list
        at the position of the named bookmark, causing that bookmark to
        be positioned below this folder)

Example:

```js
{ folder: "folderb",
  changes: {
    location: "menu/foldera",
    folder: "Folder B"
  }
}
```

###### Separator objects

Valid properties are:

-   `separator: true`, always set for separators
-   `before`: the title of the bookmark item expected to
    be found **before** this separator; used only in `verify`
    and `modify` actions.
-   `changes`: an object containing new properties to be
    set for this separator when this asset list is used in a
    `modify` action. The properties for this object are:
    -   `location`: the full path of the folder that this
        separator should be moved to
    -   `position`: the title of the existing bookmark
        item, in the current folder, where this separator should be
        moved to (i.e., this separator would be inserted into the
        bookmark list at the position of the named bookmark, causing
        that bookmark to be positioned below this separator)

Example:

```js
{
  separator: true
}
```

##### Bookmark lists and phase actions

Following are the functions you can use in phase actions related to
bookmarks:

-   `Bookmarks.add` - The bookmark items in the list are added to the end
    of their parent folder in the specified order. That is, the first
    item is appended to its parent folder, then the second, and so
    forth. `after` and `before` properties are ignored.
-   `Bookmarks.verify` - The bookmark items in the list are verified to be
    present. Within each folder, the second item in the list is assumed
    to be immediately after the first item, and so forth. If the second
    item in a given folder is not directly after the first item in that
    folder, it's an error. `after` and `before` properties, if specified,
    are also used to verify an item's position. However, because TPS verifies
    that bookmark items appear in the order that they are given in the asset
    list, `after` and `before` are not very useful except in verifying the
    position of the first item in the list.
-   `Bookmarks.verifyNot` - The bookmark items in the list are verified
    **not** to be present.
-   `Bookmarks.modify` - The `changes` properties of the bookmark items are
    applied, after the items have been verified to exist. If a `location`
    property exists inside the `changes` object, it is applied before the
    `position` property. If `location` is specified without `position`, then
    the bookmark is moved to the end of the specified folder. If `position` is
    specified without `location`, then the bookmark is moved to the specified
    position within the current folder.
-   `Bookmarks.delete` - The bookmarks in this list are deleted from the
    browser.

#### Passwords

A password asset list is an array of objects, each representing a stored
password. For example:

```js
var password_list = [
  { hostname: "http://www.example.com",
    submitURL: "http://login.example.com",
    username: "joe",
    password: "SeCrEt123",
    usernameField: "uname",
    passwordField: "pword",
    changes: {
      password: "zippity-do-dah"
    }
  },
  { hostname: "http://www.example.com",
    realm: "login",
    username: "joe",
    password: "secretlogin"
  }
];
```

Each object has the following properties:

-   `hostname`: the hostname for the password. Required.
-   `submitURL`: the submit URL for the password.
    Optional. Used for passwords in form fields.
-   `realm`: the http realm for the password. Optional.
    Used for http authentication passwords.
-   `username`: required.
-   `password`: required.
-   `usernameField`: the username field for a form
    password. Optional.
-   `passwordField`: the password field for a form
    password. Optional.
-   `changes`: an object containing any of the above
    properties, which are applied during a `modify`
    action. Optional.

##### Password lists and phase actions

Following are the functions that can be used in phase actions related to
passwords:

-   `Passwords.add`
-   `Passwords.delete`
-   `Passwords.modify`
-   `Passwords.verify`
-   `Passwords.verifyNot`

#### History

There are two types of history asset lists, one used for
adding/modiyfing/verifying history, and the other for deleting history.

The history list used for operations other than delete has the following
properties:

-   `uri`: required.
-   `title`: optional. The page title for this uri.
-   `visits`: required. An array of objects representing
    visits to the page, each object has the following properties:
    -   `type`: required. An integer value from one of
        the history visit [transition types](https://dxr.mozilla.org/mozilla-central/rev/d2966246905102b36ef5221b0e3cbccf7ea15a86/toolkit/components/places/nsINavHistoryService.idl#1181-1233).
    -   `date`: required. An integer representing when
        the visit took place, expressed in hours from the present. For
        example, 0 is now, -24 is 24 hours in the past.

For example:

```js
var history_initial = [
  { uri: "http://www.google.com/",
    title: "Google",
    visits: [
      { type: 1, date: 0 },
      { type: 2, date: -1 }
    ]
  },
  { uri: "http://www.cnn.com/",
    title: "CNN",
    visits: [
      { type: 1, date: -1 },
      { type: 2, date: -36 }
    ]
  },
];
```

The history list used for deletions looks different. It's an array of
objects, each of which represents a type of history to delete. There are
three different types:

-   to delete all references to a specific page from history, use an
    object with a `uri` property
-   to delete all references to all pages from a specific host, use an
    object with a `host` property
-   to delete all history in a certain time period, use an object with
    `begin` and `end` properties, which
    should have integer values that express time since the present in
    hours (see `date` above)

For example:

```js
var history_to_delete = [
  { uri: "http://www.cnn.com/" },
  { begin: -24,
    end: -1 },
  { host: "www.google.com" }
];
```

##### History lists and phase actions

History lists cannot be modified, they can only be added, deleted, and
verified, using the following functions:

-   `History.add`
-   `History.delete`
-   `History.verify`
-   `History.verifyNot`

#### Tabs

A tabs asset list is an array of objects with the following keys:

- `uri`: the uri of the tab, required.
- `title`: the title of the tab, optional. If specified, only used during `verify` actions.
- `profile`: the name of the profile the tab belongs to. Required for `verify` actions.

For example:

```js
var tabs1 = [  
  { uri: "http://hg.mozilla.org/automation/crossweave/raw-file/2d9aca9585b6/pages/page1.html",
    title: "Crossweave Test Page 1",
    profile: "profile1"
  },
  { uri: "data:text/html,<html><head><title>Hello</title></head><body>Hello</body></html>",
    title: "Hello",
    profile: "profile1"
  }
];
```

##### Tab lists and phase actions

Tabs cannot be modified or deleted, only added or verified with the
following functions:

- `Tabs.add` - opens the specified tabs in the browser window.
- `Tabs.verify` - verifies that the specified tabs can be found in the specified profile.
- `Tabs.verifyNot` - verifies that the specified tabs cannot be found in the specified profile.

There are a [handful of static pages in the tree](https://dxr.mozilla.org/mozilla-central/source/testing/tps/pages) which can be used for tab testing, and `data:` URLs can be used as well.

See [`test_tabs.js`](https://dxr.mozilla.org/mozilla-central/rev/681eb7dfa324dd50403c382888929ea8b8b11b00/services/sync/tests/tps/test_tabs.js) for an example.

#### Form Data

A form data asset list is an array of objects, each with the following
properties:

-   `fieldname`: required.
-   `value`: required.
-   `date`: the date the form data was used, expressed in
    hours from the present, so 0 means now, and -24 means 24 hours ago.
    Optional, defaults to 0.

For example:

```js
var formdata1 = [
  { fieldname: "testing",
    value: "success",
    date: -1
  },
  { fieldname: "testing",
    value: "failure",
    date: -2
  },
  { fieldname: "username",
    value: "joe"
  }
];
```

##### Form Data lists and phase actions

You can use the following functions in phase actions for formdata lists:

-   `Formdata.add`
-   `Formdata.delete`
-   `Formdata.verify`
-   `Formdata.verifyNot`

See [`test_formdata.js`](https://dxr.mozilla.org/mozilla-central/rev/681eb7dfa324dd50403c382888929ea8b8b11b00/services/sync/tests/tps/test_formdata.js) for an example.

##### Notes

-   Sync currently does not sync form data dates, so the `date` field is ignored when performing
`verify` and `verify-not` actions. See [bug 552531](https://bugzilla.mozilla.org/show_bug.cgi?id=552531).

#### Prefs

A prefs asset list is an array of objects with name and value keys,
representing browser preferences. For example:

```js
var prefs1 = [
  { name: "browser.startup.homepage",
    value: "http://www.getfirefox.com"
  },
  { name: "browser.urlbar.maxRichResults",
    value: 20
  },
  { name: "browser.tabs.autoHide",
    value: true
  }
];
```

##### Pref lists and phase actions

The only actions supported for preference asset lists are
`modify` and `verify`:

-   `Prefs.modify`
-   `Prefs.verify`

Sync only syncs certain preferences. To find the list of valid
preferences, open `about:config`, and search for the
`services.sync.prefs.sync.` prefix.

For a more detailed test example, see [`test_prefs.js`](https://dxr.mozilla.org/mozilla-central/rev/681eb7dfa324dd50403c382888929ea8b8b11b00/services/sync/tests/tps/test_prefs.js]).

### Test Phases

The phase blocks are where the action happens! They tell TPS what to do.
Each phase block contains the name of a phase, and a list of actions.
TPS iterates through the phase blocks in alphanumeric order, and for
each phase, it does the following:

1.  Launches Firefox with the profile from the `phases` object that
    corresponds to this test phase.
2.  Performs the specified actions in sequence.
3.  Determines if the phase passed or failed; if it passed, it continues
    to the next phase block and repeats the process.

A phase is defined by calling the `Phase` function with the name of the
phase and a list of actions to perform:

```js
Phase('phase1', [
  [Bookmarks.add, bookmarks_initial],
  [Passwords.add, passwords_initial],
  [History.add, history_initial],
  [Sync, SYNC_WIPE_SERVER],
]);
```

Each action is an array, the first member of which is a function
reference to call, the other members of which are parameters to pass to
the function.  Each type of asset list has a number of built-in
functions you can call, described in the asset lists above; there
are also some additional built-in functions.

### Built-in functions

**`Sync(options)`**

Initiates a Sync operation.  If no options are passed, a default sync
operation is performed.  Otherwise, a special sync can be performed if
one of the following are passed:  `SYNC_WIPE_SERVER`,
`SYNC_WIPE_CLIENT`, `SYNC_RESET_CLIENT`. This will cause TPS to set the
`firstSync` pref to the relevant value before syncing, so that the
described action will take place

**`Logger.logInfo(msg)`**

Logs the given message to the TPS log.

**`Logger.AssertTrue(condition, msg)`**

Asserts that condition is true, otherwise an exception is thrown and the
test fails.

**`Logger.AssertEqual(val1, val2, msg)`**

Asserts that `val1` is equal to `val2`, otherwise an exception is thrown and
the test fails.

### Custom functions

You can also write your own functions to be called as actions.  For
example, consider the first action in the phase above:

```js
[Bookmarks.add, bookmarks_initial]
```

You could rewrite this as a custom function so as to add some custom
logging:

```js
[async () => {
  Logger.logInfo("adding bookmarks_initial");
  await Bookmarks.add(bookmarks_initial);
}]
```

Note that this is probably best used for debugging, and new tests that
want custom behavior should add it to the TPS add-on so that other tests
can use it.

### Example Test

Here's an example TPS test to tie it all together.

```js
// Phase declarations
var phases = { "phase1": "profile1",
               "phase2": "profile2",
               "phase3": "profile1" };

// Asset list

// the initial list of bookmarks to be added to the browser
var bookmarks_initial = {
  "menu": [
    { uri: "http://www.google.com",
      title "google.com",
      changes: {
        // These properties are ignored by calls other than Bookmarks.modify
        title: "Google"
      }
    },
    { folder: "foldera" },
    { folder: "folderb" }
  ],
  "menu/foldera": [
    { uri: "http://www.yahoo.com",
      title: "testing Yahoo",
      changes: {
        location: "menu/folderb"
      }
    }
  ]
};

// The state of bookmarks after the first 'modify' action has been performed
// on them. Note that it's equivalent to what you get after applying the properties
// from "changes"
var bookmarks_after_first_modify = {
  "menu": [
    { uri: "http://www.google.com",
      title "Google"
    },
    { folder: "foldera" },
    { folder: "folderb" }
  ],
  "menu/folderb": [
    { uri: "http://www.yahoo.com",
      title: "testing Yahoo"
    }
  ]
};

// Phase implementation

Phase('phase1', [
  [Bookmarks.add, bookmarks_initial],
  [Sync, SYNC_WIPE_SERVER]
]);

Phase('phase2', [
  [Sync],
  [Bookmarks.verify, bookmarks_initial],
  [Bookmarks.modify, bookmarks_initial],
  [Bookmarks.verify, bookmarks_after_first_modify],
  [Sync]
]);

Phase('phase3', [
  [Sync],
  [Bookmarks.verify, bookmarks_after_first_modify]
]);
```

The effects of this test file will be:

1.  Firefox is launched with `profile1`, the TPS extension adds the two
    bookmarks specified in the `bookmarks_initial` array, then they are
    synced to the Sync server. The `SYNC_WIPE_SERVER` argument causes
    TPS to set the `firstSync="wipeServer"` pref before syncing, in case
    the Sync account already contains data (this is typically
    unnecessary, and done largely as an example). Firefox closes.
2.  Firefox is launched with `profile2`, and all data is synced from the
    Sync server. The TPS extension verifies that all bookmarks in the
    `bookmarks_initial` list are present. Then it modifies those
    bookmarks by applying the "changes" property to each of them. E.g.,
    the title of the first bookmark is changed from "google.com" to
    "Google". Next, the changes are synced to the Sync server. Finally,
    Firefox closes.
3.  Firefox is launched with `profile1` again, and data is synced from the
    Sync server. The TPS extension verifies that the bookmarks in
    `bookmarks_after_first_modify` list are present; i.e., all the
    changes performed in `profile2` have successfully been synced to
    `profile1`. Lastly, Firefox closes and the tests ends.
4.  (Implementation detail) Two final cleanup phases are run to wipe the
    server state and unregister devices.

Troubleshooting and debugging tips for writing and running TPS tests
--------------------------------------------------------------------

1.  TPS evaluates the whole file in every phase, so any syntax error(s)
    in the file will get reported in phase 1, even though the error may
    not be in phase 1 itself.
2.  Inspect `about:sync-log`. Every sync should have a log and every item
    synced should have a record.
3.  Run `runtps` with `--debug`. This will enable much more verbose
    logging in all engines.
4.  Check the `tps.log` file written out after TPS runs. It will include
    log output written by the Python driver, which includes information
    about where the temporary profiles it uses are stored.
5.  Run `test_sync.js`. This test generally validates your TPS setup and
    does a light test of a few engines.
6.  Comment out the `goQuitApplication()` calls in
    `services/sync/tps/extensions/tps/resource/tps.jsm` (remember to undo
    this later!).
    1.  You will have to manually quit the browser at each phase, but
        you will be able to inspect the browser state manually.
    2.  Using this technique in conjunction with
        [About Sync](https://addons.mozilla.org/en-US/firefox/addon/about-sync/)
        is helpful. (Note that the Python test runner will generally
        still kill Firefox after a TPS test runs for 5 or so minutes, so
        it's often helpful to kill the Python test runner outright, and
        then use About Sync in a different instance of the browser).

7.  A TPS failure may not point directly to the problem. For example,
    1.  Most errors involving bookmarks look like "Places Item not found
        in expected index", which could mean a number of issues. The
        other engines are similarly unhelpful, and will likely fail if
        there's any problem, without really indicating what the problem
        is.
    2.  It's common for the phase after the problem to be the one
        reporting errors (e.g., if one phase doesn't upload what it
        should, we won't notice until the next phase).

8.  TPS runs one "cleanup" phase for each profile (even for failed
    tests), which means most tests have two cleanup phases. This has two
    side effects:
    1.  You usually need to scroll up a bit in the log past the end of
        the test to find the actual failure.
    2.  When one of the cleanup phases fails (often possible if Firefox
        crashes or TPS hangs), there's no guarantee that the data was
        properly cleaned up, and so the next TPS test you run may fail
        due to the leftover data. This means **you may want to run a TPS
        test twice** to see if it really failed, or it just started with
        garbage.

9. Feel free to ask for help with setting up and running TPS in the
    `#sync` IRC channel!
