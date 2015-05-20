/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

public class IgnoredSiteError: ErrorType {
    public var description: String {
        return "Ignored site."
    }
}

/**
 * The base history protocol for front-end code.
 *
 * Note that the implementation of these methods might be complicated if
 * the implementing class also implements SyncableHistory -- for example,
 * `clear` might or might not need to set a bunch of flags to upload deletions.
 */
public protocol BrowserHistory {
    func addLocalVisit(visit: SiteVisit) -> Success
    func clearHistory() -> Success
    func removeHistoryForURL(url: String) -> Success

    func getSitesByFrecencyWithLimit(limit: Int) -> Deferred<Result<Cursor<Site>>>
    func getSitesByFrecencyWithLimit(limit: Int, whereURLContains filter: String) -> Deferred<Result<Cursor<Site>>>
    func getSitesByLastVisit(limit: Int) -> Deferred<Result<Cursor<Site>>>
}

/**
 * The interface that history storage needs to provide in order to be
 * synced by a `HistorySynchronizer`.
 */
public protocol SyncableHistory {
    /**
     * Make sure that the local place with the provided URL has the provided GUID.
     * Succeeds if no place exists with that URL.
     */
    func ensurePlaceWithURL(url: String, hasGUID guid: GUID) -> Success

    /**
     * Change any place with the old GUID to the new GUID. Succeeds if the GUID is unknown.
     */
    func changeGUID(old: GUID, new: GUID) -> Success

    /**
     * Delete the place with the provided GUID, and all of its visits. Succeeds if the GUID is unknown.
     */
    func deleteByGUID(guid: GUID, deletedAt: Timestamp) -> Success

    func storeRemoteVisits(visits: [Visit], forGUID guid: GUID) -> Success
    func insertOrUpdatePlace(place: Place, modified: Timestamp) -> Deferred<Result<GUID>>

    func getHistoryToUpload() -> Deferred<Result<[(Place, [Visit])]>>

    /**
     * Chains through the provided timestamp.
     */
    func markAsSynchronized([GUID], modified: Timestamp) -> Deferred<Result<Timestamp>>
}

// TODO: integrate Site with these.

public class Place {
    public let guid: GUID
    public let url: String
    public let title: String

    public init(guid: GUID, url: String, title: String) {
        self.guid = guid
        self.url = url
        self.title = title
    }
}

public class LocalPlace: Place {
    // Local modification time.
    public var modified: Timestamp

    public init(guid: GUID, url: String, title: String, modified: Timestamp) {
        self.modified = modified
        super.init(guid: guid, url: url, title: title)
    }
}

public class RemotePlace: Place {
    // Server timestamp on the record.
    public let modified: Timestamp

    // Remote places are initially unapplied, and this is flipped when we reconcile them.
    public var applied: Bool

    public convenience init(guid: GUID, url: NSURL, title: String, modified: Timestamp) {
        self.init(guid: guid, url: url.absoluteString!, title: title, modified: modified)
    }

    public init(guid: GUID, url: String, title: String, modified: Timestamp) {
        self.applied = false
        self.modified = modified
        super.init(guid: guid, url: url, title: title)
    }
}