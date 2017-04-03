/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import Deferred
import Shared

/* 
 * A class that adheres to all the requirements for a profile's history property
 * with all of the methods set to fatalError. Use this class if you're looking to
 * mock out parts of the history API
 */
class MockableHistory: BrowserHistory, SyncableHistory, ResettableSyncStorage {
    func getTopSitesWithLimit(_ limit: Int) -> Deferred<Maybe<Cursor<Site>>> { fatalError()}
    func addLocalVisit(_ visit: SiteVisit) -> Success { fatalError() }
    func clearHistory() -> Success { fatalError() }
    func removeHistoryForURL(_ url: String) -> Success { fatalError() }
    func removeSiteFromTopSites(_ site: Site) -> Success { fatalError() }
    func removeHostFromTopSites(_ host: String) -> Success { fatalError() }
    func clearTopSitesCache() -> Success { fatalError() }
    func refreshTopSitesCache() -> Success { fatalError() }
    func getSitesByFrecencyWithHistoryLimit(_ limit: Int) -> Deferred<Maybe<Cursor<Site>>> { fatalError() }
    func getSitesByFrecencyWithHistoryLimit(_ limit: Int, whereURLContains filter: String) -> Deferred<Maybe<Cursor<Site>>> { fatalError() }
    func getSitesByFrecencyWithHistoryLimit(_ limit: Int, bookmarksLimit: Int, whereURLContains filter: String) -> Deferred<Maybe<Cursor<Site>>> { fatalError() }
    func getSitesByLastVisit(_ limit: Int) -> Deferred<Maybe<Cursor<Site>>> { fatalError() }
    func setTopSitesNeedsInvalidation() { fatalError() }
    func updateTopSitesCacheIfInvalidated() -> Deferred<Maybe<Bool>> { fatalError() }
    func setTopSitesCacheSize(_ size: Int32) { fatalError() }
    func areTopSitesDirty(withLimit limit: Int) -> Deferred<Maybe<Bool>> { fatalError() }
    func onRemovedAccount() -> Success { fatalError() }
    func ensurePlaceWithURL(_ url: String, hasGUID guid: GUID) -> Success { fatalError() }
    func deleteByGUID(_ guid: GUID, deletedAt: Timestamp) -> Success { fatalError() }
    func storeRemoteVisits(_ visits: [Visit], forGUID guid: GUID) -> Success { fatalError() }
    func insertOrUpdatePlace(_ place: Place, modified: Timestamp) -> Deferred<Maybe<GUID>> { fatalError() }
    func getModifiedHistoryToUpload() -> Deferred<Maybe<[(Place, [Visit])]>> { fatalError() }
    func getDeletedHistoryToUpload() -> Deferred<Maybe<[GUID]>> { fatalError() }
    func markAsSynchronized(_: [GUID], modified: Timestamp) -> Deferred<Maybe<Timestamp>> { fatalError() }
    func markAsDeleted(_ guids: [GUID]) -> Success { fatalError() }
    func doneApplyingRecordsAfterDownload() -> Success { fatalError() }
    func doneUpdatingMetadataAfterUpload() -> Success { fatalError() }
    func hasSyncedHistory() -> Deferred<Maybe<Bool>> { fatalError() }
    func resetClient() -> Success { fatalError() }
}

