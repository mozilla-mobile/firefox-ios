/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Deferred

public class IgnoredSiteError: MaybeErrorType {
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
    func addLocalVisit(_ visit: SiteVisit) -> Success
    func clearHistory() -> Success
    func removeHistory(forURL url: String) -> Success
    func removeSiteFromTopSites(_ site: Site) -> Success

    func getSitesByFrecency(withHistoryLimit limit: Int) -> Deferred<Maybe<Cursor<Site>>>
    func getSitesByFrecency(withHistoryLimit limit: Int, whereURLContains filter: String) -> Deferred<Maybe<Cursor<Site>>>
    func getSitesByFrecency(withHistoryLimit limit: Int, bookmarksLimit: Int, whereURLContains filter: String) -> Deferred<Maybe<Cursor<Site>>>
    func getSitesByLastVisit(withLimit limit: Int) -> Deferred<Maybe<Cursor<Site>>>

    func getTopSites(withLimit limit: Int) -> Deferred<Maybe<Cursor<Site>>>
    func setTopSitesNeedsInvalidation()
    func updateTopSitesCacheIfInvalidated() -> Deferred<Maybe<Bool>>
    func setTopSitesCacheSize(_ size: Int32)
    func clearTopSitesCache() -> Success
    func refreshTopSitesCache() -> Success
    func areTopSitesDirty(withLimit limit: Int) -> Deferred<Maybe<Bool>>
}

/**
 * The interface that history storage needs to provide in order to be
 * synced by a `HistorySynchronizer`.
 */
public protocol SyncableHistory: AccountRemovalDelegate {
    /**
     * Make sure that the local place with the provided URL has the provided GUID.
     * Succeeds if no place exists with that URL.
     */
    func ensurePlace(withURL url: String, hasGUID guid: GUID) -> Success

    /**
     * Delete the place with the provided GUID, and all of its visits. Succeeds if the GUID is unknown.
     */
    func delete(byGUID guid: GUID, deletedAt: Timestamp) -> Success

    func storeRemoteVisits(_ visits: [Visit], forGUID guid: GUID) -> Success
    func insertOrUpdatePlace(_ place: Place, modified: Timestamp) -> Deferred<Maybe<GUID>>

    func getModifiedHistoryToUpload() -> Deferred<Maybe<[(Place, [Visit])]>>
    func getDeletedHistoryToUpload() -> Deferred<Maybe<[GUID]>>

    /**
     * Chains through the provided timestamp.
     */
    func markAsSynchronized(_: [GUID], modified: Timestamp) -> Deferred<Maybe<Timestamp>>
    func markAsDeleted(_ guids: [GUID]) -> Success

    func doneApplyingRecordsAfterDownload() -> Success
    func doneUpdatingMetadataAfterUpload() -> Success

    /**
     * For inspecting whether we're an active participant in history sync.
     */
    func hasSyncedHistory() -> Deferred<Maybe<Bool>>
}

// TODO: integrate Site with this.

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
