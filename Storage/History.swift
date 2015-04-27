/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

public typealias GUID = String

/**
 * The base history protocol for front-end code.
 *
 * Note that the implementation of these methods might be complicated if
 * the implementing class also implements SyncableHistory -- for example,
 * `clear` might or might not need to set a bunch of flags to upload deletions.
 */
public protocol BrowserHistory {
    func clear(complete: (success: Bool) -> Void)
    func get(options: QueryOptions?, complete: (data: Cursor) -> Void)
    func addVisit(visit: Visit, complete: (success: Bool) -> Void)
}

/**
 * The interface that history storage needs to provide in order to be
 * synced by a `HistorySynchronizer`.
 */
public protocol SyncableHistory {
    func ensurePlaceWithURL(url: String, hasGUID guid: GUID) -> Deferred<Result<()>>
    func changeGUID(old: GUID, new: GUID) -> Deferred<Result<()>>

    func insertOrReplaceRemoteVisits(visits: [Visit], forGUID guid: GUID) -> Deferred<Result<()>>
    func insertOrUpdatePlaceWithURL(url: String, title: String, guid: GUID) -> Deferred<Result<GUID>>
}