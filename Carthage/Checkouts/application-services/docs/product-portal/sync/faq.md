---
title: Frequently Asked Questions
sidebar_label: FAQ
---

### When do syncs occur?

-   Sync uses a timer for regularly scheduled syncs. The time between
    syncs varies in some conditions (eg, it is increased when the device
    is idle) but in general, a single-device account syncs once per
    hour, where multi-device accounts sync once every 10 minutes.
-   In addition, Sync maintains a "score" and syncs when reaches a
    threshold, with different types of data contributing a different
    score. For example, a bookmark, password and addon change causes a
    large score increment, so a Sync will start on every bookmark,
    password or addon change. However, new history and tab entries cause
    a smaller increment so a Sync is not performed every time the user
    visits a new page.
-   Syncs always happen immediately when the user presses the “Sync Now”
    button in the hamburger menu.

**Server states**

-   Server can send status codes (503) to "backoff" the Sync interval to
    a server-specified value in the unlikely event of infrastructure
    issues affecting the service.

### How much data syncs?

**First Sync, or the unusual case of the user being moved to a new Sync
server**

-   In this case we fetch all items on the server and apply them locally
    if they don’t already exist. After fetching all items we also look
    for local items that are not on the server and upload these missing
    items - although in the case of “history” we only upload the last 30
    days of visits.

**Subsequent Syncs:**

-   Sync stores the “last modified” timestamp sent by the server, and
    only fetches new items the server reports has changed since that
    timestamp. Thus, it is not uncommon for a Sync to ask the server for
    new items and be told there are none.
-   The client also keeps track of which items have changed locally
    since the last Sync (eg, new bookmarks, new history visits, etc) and
    uploads these entries to the server.

### When can users lose data?

In general, for a user to lose all their Sync data, 2 events must happen
at the same time:

-   The copy of the data on the server is lost
-   The copy of the data on each of their devices is lost

If either of these events happens by itself, Sync will generally recover
correctly:

-   If the server data is lost, it will be repopulated the next time a
    client Syncs.
-   If a client is lost, a new client can be connected to the Sync
    account and the data from the server will be pulled down.

Note that the server data will be lost in 2 main scenarios:

-   The encryption used by Sync means that if a user’s password is reset
    (not simply changed), then the data on the server is unable to be
    decrypted. While the data isn’t actually “lost” in this case, it
    might as well be.
-   Due to an infrastructure issue with the Sync servers, the user was
    moved to a different Sync server with no data, in the expectation
    that a client will soon Sync and re-upload the data.

While the above considerations mean that in most cases Sync will recover
from either a client or server loss, there are a couple of edge-cases
that makes this unreliable for some users.

-   Single device users who have “lost” their only existing device and
    reset their password - in this case the data is lost on the server
    and the only device with a copy of the data no longer exists.
-   Single device users who have “lost” their only existing device, and
    are unlucky enough that this corresponds to when an infrastructure
    issue means they have been moved to a different server.
-   As above, but for multi-device users who have lost all their
    existing devices.

As a first sync can often take a long time to complete, we believe that
some users will also perceive their data as being lost after
reconnecting their device but before Sync has dragged it all down to the
new device.

Note that work is underway to try and reduce these bad scenarios:

-   We are considering giving users the choice of using a slightly
    different encryption scheme that will not lose all their data in the
    case of a password reset in exchange for slightly less security of
    their data (ie, mozilla will then hold a key capable of decrypting
    their data). The big challenge here is around UX - how to we
    succinctly explain the tradeoffs and offer that choice so the user
    can make an informed choice?
-   We are working on the server infrastructure so the failure of a
    single Sync server will not lose the data - so the data is carried
    across to the new Sync server for that user.

### When will client upload or fetch all data?

-   Server node is moved or lost, or user reset their password such that
    the existing data can not be decrypted.
-   New device is added and will fetch all data, and upload any local
    data not already on the server.

What are known situations where a client could corrupt data? The main
cause of “corruption” is when a change made locally on a device is not
uploaded to the server. Depending in the data, the perceived level of
corruption differs.

-   For most data, this just appears to the user as though Sync hasn’t
    got the complete data - for example, a history entry or password may
    not appear on all devices. In general, the user perceives the data
    as “missing” rather than “corrupt”
-   For bookmarks in particular, the issue is more complex - for
    example, if a single item for a bookmark folder is missing but the
    bookmarks within that folder do exist, Sync can’t reliably replicate
    the bookmarks tree. In general it will then place these child
    bookmarks in the “unfiled bookmarks” folder. The user will often
    perceive this as real corruption as not only are items missing, but
    the tree structure for items that do exist is wrong.

Unfortunately there are a number of cases where Sync will fail to detect
a local change, and thus will not upload that change to the server.
These include:

-   User adds/removes item before sync has initialized at startup.
-   User makes changes during a sync.
-   Client network interrupted during upload of data meaning only
    partial data is on the server. While this is likely to be fixed by
    the next Sync of this client, there is a possibility other devices
    will Sync in the meantime and apply this partial data.

### Can a client control sync policies?

Currently client server data is merged (deleted items explicitly
marked). Giving user control presents a complex decision which is
difficult to explain outcomes to users.

With sync 1.1 there were options that applied to the first Sync:

-   Merge client data
-   Overwrite server data
-   Overwrite client data

There are also preferences the user can set to adjust the timer delay
and other obscure configuration options.

### Can a user backup to a snapshot of data?

Not currently, but this is a feature that could be added. Like some of
the above, a key challenge here is UX and giving the user enough
information and choice that they can make an informed decision about the
implications of their choice. For example, if the user chooses to
restore from a backup, are we sure they are aware the change will affect
all their devices and not just the current device? Is it possible that
only this local client is in a bad state, and that the copy of the data
on the server is in a good state and should be reapplied to this device
without impacting other devices?

