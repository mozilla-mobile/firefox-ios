## Places! Yeah, Places...

### Before using this component

Products sending telemetry and using this component *must request* a data-review following
[this process](https://wiki.mozilla.org/Firefox/Data_Collection).
This component provides data collection using the [Glean SDK](https://mozilla.github.io/glean/book/index.html).
The list of metrics being collected is available in the [metrics documentation](../../docs/metrics/places/metrics.md).

### Introduction

The general idea is to be like a rusty desktop Places.

So, instead of:

    let visits = [{date: ..., transitition: ...}];
    let place = {url: "http...", title: ..., visits};
    PlacesUtils.history.insert(place);

It's more:

    let visits = vec![Visit { date, transition: ...} ];
    let place = Place { url, title: ..., visits };
    places::api::history::insert(db, place);

The short-term goal is to demonstrate a "port" of:

1. ```PlacesUtils.history.insert(...);```
2. ```UnifiedComplete.something("example.co")``` -> auto-complete result.

However, it's very incomplete - schema is a poor copy/paste of desktop, no temp tables, no triggers, no...

# Notes about desktop's implementation of the above:

* seems to prefer a guid over a url - however, this appears completely unused
  except by code supporting sync - the logical API for real consumers is via
  a URL, so we largely ignore GUIDs for now.

specifically, the following "scratchpad" code:

    let referrer = null;
    let transition = PlacesUtils.history.TRANSITION_LINK;
    let date = new Date();
    let pageInfo = {
      title: "Title",
      visits: [
        {transition, referrer, date },
      ],
       url: "https://example.com",
     };
     let result = await PlacesUtils.history.insert(pageInfo);

Ends up in ```History::UpdatePlaces()``` with the following ```visitData```:

    visitData =
        placeId 0   __int64
        guid ""
        visitId 0   __int64
        spec   "{url}
        revHost {value}
        hidden  false   bool
        shouldUpdateHidden  true    bool
        typed   false   bool
        transitionType  1   unsigned int
        visitTime   1537270492849000    __int64
        frecency    -1  int
        lastVisitId 0   __int64
        lastVisitTime   0   __int64
        visitCount  0   unsigned int
        title   {title}   nsTString<char16_t>
        referrerSpec   ""
        referrerVisitId 0   __int64
        titleChanged    false   bool
        shouldUpdateFrecency    true    bool
        useFrecencyRedirectBonus    false   bool

ends up calling ```FetchPageInfo()``` - takes ```visitdata``` and updates it - desktop updates ```visitData``` in-place - rust probably wants different structs for each operation

then: updates .typed, .hidden, hacks to avoid "maybe unhide"?

then: ```DoDatabaseInserts()```:

    if not new: updatePlace() else: insertPlace()
    addVisit()
    if autocomplete: UpdateFrecency()
