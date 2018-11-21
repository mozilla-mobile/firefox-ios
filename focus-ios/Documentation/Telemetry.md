> **If there is anything in this document that is not clear, is incorrect, or that requires more detail, please file a request through a [Github](https://github.com/mozilla-mobile/focus/issues) or [Bugzilla](https://bugzilla.mozilla.org/enter_bug.cgi?product=Focus&component=General). Also feel free to submit corrections or additional information.**

> **NOTE: As of v3.3, the Adjust SDK is no longer used for event tracking. It is still, however, used for install tracking in Firefox Focus only (but *NOT* in Firefox Klar).**

Firefox Focus and Firefox Klar use Mozilla's own [Telemetry](https://gecko.readthedocs.io/en/latest/toolkit/components/telemetry/telemetry/index.html) service for anonymous insight into usage of various app features. This event tracking is turned off by default for Firefox Klar (opt-in), but is on by default for Firefox Focus (opt-out).

The app uses Mozilla's own framework linked into Firefox Focus and Firefox Klar and a [data collection service](https://wiki.mozilla.org/Telemetry) run by Mozilla. The framework is open source and MPL 2.0 licensed. It is hosted at [https://github.com/mozilla-mobile/telemetry-ios](https://github.com/mozilla-mobile/telemetry-ios). Firefox Focus and Firefox Klar pull in an unmodified copy of the framework via [Carthage](https://github.com/Carthage/Carthage).

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
  suggestion.yahoo: 13
  listitem.yahoo:   7
  actionbar.yahoo:  4
clientId:           610A1520-4D47-498E-B20F-F3B46216372B
profileDate:        17326
v:                  7
device:             iPad
defaultSearch:      yahoo
locale:             en-US
seq:                1
os:                 iOS
osversion:          10.3
created:            2017-06-09
arch:               arm64
```

These parameters are documented at [https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/data/core-ping.html](https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/data/core-ping.html).

#### Response

If the ping was received successfully, the server responds with an HTTP `200` status code.

### Event Ping

#### Request

```
tz:            -240
seq:           1
os:            iOS
created:       1497026730320
clientId:      2AF1A5A8-29B3-44B0-9653-346B67811E99
osversion:     10.3
settings:
  BlockAds:    true
  BlockSocial: false
},
v:             1
events:
  [ 2147, action, type_query, search_bar   ]
  [ 2213, action, type_url,   search_bar   ]
  [ 2892, action, click,      erase_button ]
locale:        en-US
```

These parameters are documented at [https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/collection/events.html](https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/collection/events.html).

You can find the full list of Event Pings sent by Focus [here](https://github.com/mozilla-mobile/focus-ios/blob/master/Blockzilla/TelemetryIntegration.swift).

#### Response

If the ping was received successfully, the server responds with an HTTP `200` status code.

## Events

The event ping contains a list of events ([see event format on readthedocs.io](https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/collection/events.html)) for the following actions:

### Sessions

| Event                                    | category | method     | object | value  |
|------------------------------------------|----------|------------|--------|--------|
| Start session (App is in the foreground) | action   | foreground | app    |        |
| Stop session (App is in the background)  | action   | background | app    |        |


| Event                                  | category | method                | object          | value         | extras     |
|----------------------------------------|----------|-----------------------|-----------------|---------------|------------|
| URL entered                            | action   | type_url              | search_bar      |               |            |
| Paste and Go                           | action   | click                 | paste_and_go    |               |            |
| Search hint clicked ("Search for ..")  | action   | select_query          | search_bar      |               |            |
| Focus opened from extension            | action   | opened_from_extension | app             |               |            |
| User opened external link from Focus   | action   | open                  | request_handler | external link |            |
| User cancelled opening external link   | action   | cancel                | request_handler | external link |            |
| User clicked a new link on webpage     | action   | click                 | website_link    |               |            |
| Autofill popup is shown                | action   | show                  | autofill        |               |            |
| Autofill performed                     | action   | click                 | autofill        |               |            |
| Submitted with autocompleted URL       | action   | click                 | autofill        |               |			   |
| Request desktop from long press        | action   | click                 | request_desktop |               |            |
| Find in page bar opened                | action   | open                  | find_in_page_bar|               |            | 
| Find next in page                      | action   | click                 | find_next_button|               |            |
| Find previous in page                  | action   | click                 | find_previous_buttom|           |            |
| Find in page bar closed                | action   | close                 | find_in_page_bar|               |            |
| Quick add custom domain tapped         | action   | click                 | quick_add_custom_domain_button  |            |
| Drag from URL bar to another app       | action   | drag                  | search_bar      |               |            |
| Drop a URL onto URL bar                | action   | drop                  | search_bar      |               |            | 
| Erase and open with Siri               | action   | siri                  | erase_and_open  |               |            |
| Open favorite site with Siri           |  action  | siri                  | open_favorite_site |            |            |
| Erase in the background with Siri      | action   | siri                  | erase_in_background |           |            |
| Autocomplete tip displayed               | action   | show       | autocomplete_tip         |
| Tracking protection tip displayed        | action   | show       | tracking_protection_tip  |
| Request desktop tip displayed            | action   | show       | request_desktop_tip      |
| Share tip displayed                      | action   | show       | tracker_stats_share_button                |
| Biometric tip displayed                  | action   | show       | biometric_tip            |
| Siri favorite tip displayed              | action   | show       | siri_favorite_tip        |
| Siri erase tip displayed                 | action   | show       | siri_erase_tip           |
| Biometric tip tapped                     | action   | click      | biometric_tip            |
| Siri favorite tip tapped                 | action   | click      | siri_favorite_tip        |
| Siri erase tip tapped                    | action   | click      | siri_erase_tip           |

### Erasing session

| Event                                  | category | method      | object              | value      | extras  |
|----------------------------------------|----------|-------------|---------------------|------------|---------|
| Erase button clicked                   | action   | click       | erase_button        |            |         |

### Share Sheet

| Event                                       | category | method   | object          | value        | extras   |
|---------------------------------------------|----------|----------|-----------------|--------------|----------|
| Open with Firefox                           | action   | open     | menu            | firefox      |          |
| Open with Safari                            | action   | open     | menu            | default      |          |

### Settings

| Event                          | category | method    | object                  | value | extras               |
|--------------------------------|----------|-----------|-------------------------|-------|--------------------------
| Setting changed                | action   | change    | setting                 | <key> | `{ "to": <value> }`  |
| Opened settings                | action   | click     | settings_button         |       |                      |
| Custom autocomplete URL removed | action   | removed   | custom_domain           |       |                     |
| Custom autocomplete URL added   | action   | change                |custom_domain    |               |
| Custom autocomplete URL reordered | action   | reordered           | custom_domain   |               |

### Tracking Protection

| Event                          | category | method    | object                     | value | extras               |
|--------------------------------|----------|-----------|----------------------------|-------|--------------------------
| Closed T.P. Drawer             | action   | close     | tracking_protection_drawer |       |                      |
| Opened T.P. Drawer             | action   | open      | tracking_protection_drawer |       |                      |
| T.P. Setting Changed           | action   | change    | tracking_protection_toggle |       | `{ "to": <value> }`  |

### Firstrun

| Event                                       | category   | method       | object               | value        |
|---------------------------------------------|------------|--------------|----------------------|--------------|
| Showing a first run page                    | action     | show         | new_onboarding       | `page`*      |
| Skip button pressed                         | action     | click        | new_onboarding       | skip         |
| Finish button pressed                       | action     | click        | new_onboarding       | finish       |
| Show previous first run                     | action     | coin_flip    | previous_first_run   |              |
| Show new onboarding experience              | action     | coin_flip    | ios_onboarding_v1    |              |

(*) Page numbers start at 0.

## Limits

* An event ping will contain up to but no more than 500 events
* No more than 40 pings per type (core/event) are stored on disk for upload at a later time
* No more than 100 pings are sent per day
