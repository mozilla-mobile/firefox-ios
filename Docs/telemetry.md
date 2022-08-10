**NOTE:** We have switched to using Glean to record telemetry and new documentation is in [the wiki](https://github.com/mozilla-mobile/firefox-ios/wiki/Adding-Glean-Telemetry-Events).

# Mozilla's Telemetry Service Pings

> **NOTE:** If there is anything in this document that is not clear, is incorrect, or that requires more detail, please file a request through [Bugzilla](https://bugzilla.mozilla.org/enter_bug.cgi?product=Firefox%20for%20iOS&component=Telemetry). Also feel free to submit corrections or additional information.

Firefox for iOS uses Mozilla's own [Telemetry](https://wiki.mozilla.org/Firefox/Data_Collection) service for anonymous insight into usage of various app features. This event tracking is turned on by default for Firefox for iOS (opt-out).

The app uses Mozilla's own framework linked into Firefox for iOS and a [data collection service](https://wiki.mozilla.org/Telemetry) run by Mozilla. The framework is open source and MPL 2.0 licensed. It is hosted at [https://github.com/mozilla-mobile/telemetry-ios](https://github.com/mozilla-mobile/telemetry-ios). Firefox for iOS pulls in an unmodified copy of the framework via [Carthage](https://github.com/Carthage/Carthage).

<sup>Example of bug to add telemetry: https://bugzilla.mozilla.org/show_bug.cgi?id=1455672</sup>

## Telemetry Pings

The Telemetry framework collects and sends two types of pings to Mozilla's Telemetry backend:

* A *Core Ping* with basic system info and usage times.
* An *Event Ping* with details about user preferences and UI actions with timestamps relative to the app start time.

The messages are also documented below in more detail of what is sent in each HTTP request. All messages are posted to a secure endpoint at `https://incoming.telemetry.mozilla.org`. They are all `application/json` HTTP `POST` requests. Details about the HTTP edge server can be found at [https://wiki.mozilla.org/CloudServices/DataPipeline/HTTPEdgeServerSpecification](https://wiki.mozilla.org/CloudServices/DataPipeline/HTTPEdgeServerSpecification).

### Core Ping

#### Request

```
tz:                 -240
sessions:           1
durations:          1
searches:
  suggestion.google: 13
  listitem.google:   7
  actionbar.google:  4
clientId:           610A1520-4D47-498E-B20F-F3B46216372B
profileDate:        17326
v:                  7
device:             iPad
defaultSearch:      google
locale:             en-US
seq:                1
os:                 iOS
osversion:          11.1
created:            2017-12-12
arch:               arm64
```

These parameters are documented at [https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/data/core-ping.html](https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/data/core-ping.html).

#### Response

If the ping was received successfully, the server responds with an HTTP `200` status code.

#### Additional items added to the Core Ping

- defaultMailClient

The defaultMailClient field contains the URL scheme of the mail client that the user wants to use for mailto: links. It is used to measure usage of this feature, to see how effective feature promotion campaigns are and to report back to third-party mail clients what percentage of users is using their client. Duration: There is no intent to remove this field.

- defaultNewTabExperience

The defaultNewTabExperience field contains the name of the view that the user wants to see on new tabs. For example History, Homepage or Blank. It is used to measure usage of this feature, to see how effective feature promotion campaigns are and to establish a baseline number for when we introduce the new Activity Stream features. Duration: There is no intent to remove this field.

- openTabCount

The number of tabs the user had open during a unique session.

### Event Ping

#### Request

```
tz:            -240
seq:           1
os:            iOS
created:       1497026730320
clientId:      2AF1A5A8-29B3-44B0-9653-346B67811E99
osversion:     11.2
settings:
  BlockAds:    true
  BlockSocial: false
},
v:             1
events:
  [ 2147, action, type_query, search_bar   ]
  [ 2213, action, type_url,   search_bar   ]
locale:        en-US
```

These parameters are documented at [https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/collection/events.html](https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/collection/events.html).

You can find the full list of Event Pings sent by Focus [here](https://github.com/mozilla-mobile/focus-ios/blob/master/Blockzilla/TelemetryIntegration.swift).

#### Response

If the ping was received successfully, the server responds with an HTTP `200` status code.

## Events

The event ping contains a list of events ([see event format on readthedocs.io](https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/collection/events.html)) for the following actions:

### App Lifecycle

| Event                               | category | method     | object | value  |
|-------------------------------------|----------|------------|--------|--------|
| App is foregrounded (session start) | action   | foreground | app    |        |
| App is backgrounded (session end)   | action   | background | app    |        |

### Bookmarks

| Event                                             | category | method                | object            | value                 | extras                      |
|---------------------------------------------------|----------|-----------------------|-------------------|-----------------------|-----------------------------|
| View Bookmarks list from Home Panel tab button    | action   | view                  | bookmarks-panel   | home-panel-tab-button |                             |
| View Bookmarks list from App Menu                 | action   | view                  | bookmarks-panel   | app-menu              |                             |
| Add Bookmark from Page Action Menu                | action   | add                   | bookmark          | page-action-menu      |                             |
| Add Bookmark from Share Menu                      | action   | add                   | bookmark          | share-menu            |                             |
| Add Bookmark from Activity Stream context menu    | action   | add                   | bookmark          | activity-stream       |                             |
| Delete Bookmark from Page Action Menu             | action   | delete                | bookmark          | page-action-menu      |                             |
| Delete Bookmark from Activity Stream context menu | action   | delete                | bookmark          | activity-stream       |                             |
| Delete Bookmark from Home Panel via long-press    | action   | delete                | bookmark          | bookmarks-panel       | { "gesture": "long-press" } |
| Delete Bookmark from Home Panel via swipe         | action   | delete                | bookmark          | bookmarks-panel       | { "gesture": "swipe" }      |
| Open Bookmark from Awesomebar search results      | action   | open                  | bookmark          | awesomebar-results    |                             |
| Open Bookmark from Home Panel                     | action   | open                  | bookmark          | bookmarks-panel       |                             |

### Reader Mode

| Event                                          | category | method                | object                   | value               | extras     |
|------------------------------------------------|----------|-----------------------|--------------------------|---------------------|------------|
| Open Reader Mode                               | action   | tap                   | reader-mode-open-button  |                     |            |
| Leave Reader Mode                              | action   | tap                   | reader-mode-close-button |                     |            |

### Reading List

| Event                                          | category | method                | object            | value               | extras     |
|------------------------------------------------|----------|-----------------------|-------------------|---------------------|------------|
| Add item to Reading List from Toolbar          | action   | add                   | reading-list-item | reader-mode-toolbar |            |
| Add item to Reading List from Share Extension  | action   | add                   | reading-list-item | share-extension     |            |
| Add item to Reading List from Page Action Menu | action   | add                   | reading-list-item | page-action-menu    |            |
| Open item from Reading List                    | action   | open                  | reading-list-item |                     |            |
| Delete item from Reading List from Toolbar     | action   | delete                | reading-list-item | reader-mode-toolbar |            |
| Delete item from Reading List from Home Panel  | action   | delete                | reading-list-item | reading-list-panel  |            |
| Mark Item As Read                              | action   | tap                   | reading-list-item | mark-as-read        |            |
| Mark Item As Unread                            | action   | tap                   | reading-list-item | mark-as-unread      |            |

### Settings

| Event                          | category | method    | object                  | value | extras               |
|--------------------------------|----------|-----------|-------------------------|-------|----------------------|
| Setting changed                | action   | change    | setting                 | <key> | { "to": (value) }    | 

### QR Codes

| Event                          | category | method    | object                  |
|--------------------------------|----------|-----------|-------------------------|
| URL-based QR code scanned      | action   | scan      | qr-code-url             |
| Non-URL-based QR code scanned  | action   | scan      | qr-code-text            |


### App Share Extension

| Event                          | category | method    | object                  |
|--------------------------------|----------|-----------|-------------------------|
| Send to device tapped    | app-extension-action   | send-to-device    |  "url"  |
| Open in Firefox tapped (URL) | app-extension-action   | application-open-url    | "url" |
| Open in Firefox tapped (search text) | app-extension-action   | application-open-url    | "searchText" |
| Bookmark this page tapped | app-extension-action   | bookmark-this-page   | "url"  |
| Add to reading list tapped | app-extension-action   | add-to-reading-list    | "url"  |
| Load in Background tapped | app-extension-action   | load-in-background    | "url"  |

"url" is an object code, literally "url", not an URL itself.


### Data Management

| Event                                             | category | method                | object            | value                 | extras                      |
|---------------------------------------------------|----------|-----------------------|-------------------|-----------------------|-----------------------------|
| Tapping Website Data in Data Management Menu   | action   | tap                  | website-data-button   |  |                             |
| Tapping on the Search Bar in Website Data                 | action   | tap                  | search-website-data   |               |                             |
| Tapping on 'Clear All Website Data' button in Website Data                | action   | tap                   | clear-website-data-button          |       |                             |


### New Tab Settings

| Event                                             | category | method                | object            | value                 | extras                      |
|---------------------------------------------------|----------|-----------------------|-------------------|-----------------------|-----------------------------|
| Tapping Top Sites button in New Tab Settings    | action   | tap                  | show-top-sites-button   |  |                             |
| Tapping Blank Page button in New Tab Settings                | action   | tap                  | show-blank-page-button   |               |                             |
| Tapping Bookmarks button in New Tab Settings                | action   | tap                   | show-bookmarks-button         |       |                             |
| Tapping History button in New Tab Settings                | action   | tap                   | show-history-button          |       |                             |
| Tapping Homepage button in New Tab Settings                | action   | tap                   | show-homepage-button          |       |                             |

### Translation

| Event                                                               | category | method    | object  | value            | extras                                            |
|---------------------------------------------------------------------|----------|-----------|---------|------------------|---------------------------------------------------|
| Prompt to translate tab to user's native language                   | prompt   | translate | tab     | -n/a-            | "from": (value), "to": (value)                      |
| Accept offer to translate tab                                       | action   | translate | tab     | -n/a-            | "from": (value), "to": (value), "action": "accept"  |
| Decline offer to translate tab                                      | action   | translate | tab     | -n/a-            | "from": (value), "to": (value), "action": "decline" |
| Toggle setting off to offer to translate tabs to user's native language | action   | change    | setting | show-translation | "to": "off"                           |
| Toggle setting on to offer to translate tabs to user's native language  | action   | change    | setting | show-translation | "to": "on"                            |

### Private Mode

| Event                                                               | category | method    | object  | value            | extras                                            |
|---------------------------------------------------------------------|----------|-----------|---------|------------------|---------------------------------------------------|
| Add tab                  | action   | add | tab     | "normal-tab" or "private-tab"           | -n/a-                     |
| Private mode button toggled      | action   | tap | private-browsing-button | -n/a-          | -n/a-                     |

### Tracking Protection

| Event                                                               | category | method    | object  | value            | extras                                            |
|---------------------------------------------------------------------|----------|-----------|---------|------------------|---------------------------------------------------|
| Whitelist site                  | action   | add | tracking-protection-whitelist     | -n/a-   | -n/a-                     |
| Change tracking protection strength   | action   | change   | setting | profile.prefkey.trackingprotection.strength  | "basic" or "strict"                                                |
| Open tracking protection menu   | action   | click   | tracking-protection-menu | -n/a-  | -n/a-  |    

### Tabs

| Event                                                               | category | method    | object  | value            | extras                                            |
|---------------------------------------------------------------------|----------|-----------|---------|------------------|---------------------------------------------------|
| When tab is closed                 | action   | close | tab     | -n/a-   | -n/a-                     |
| Tab search clicked   | action   | press   | tab-search | -n/a-  | -n/a-                                                |
| Click on existing tab   | action   | press   | tab | -n/a-  | -n/a-  | 
| Tab view button is pressed | action | press | tab-toolbar | tab-view | -n/a- |
               

### Tab Tray

| Event                                                               | category | method    | object  | value            | extras                                            |
|---------------------------------------------------------------------|----------|-----------|---------|------------------|---------------------------------------------------|
| Allow user to search or add url from tab tray search button  | action   | tap | start-search-button | -n/a-          | -n/a-                     |

### Url Bar  

| Event                                                               | category | method    | object  | value            | extras                                            |
|---------------------------------------------------------------------|----------|-----------|---------|------------------|---------------------------------------------------|
| Allow user to open a new tab from the url bar and when in landscape mode  | action   | tap | add-new-tab-button | -n/a-          | -n/a-                     |


## Limits

* An event ping will not be sent until at least 3 events are recorded
* An event ping will contain up to but no more than 500 events
* No more than 40 pings per type (core/event) are stored on disk for upload at a later time
* No more than 100 pings are sent per day
