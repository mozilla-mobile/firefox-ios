/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = Logger.syncLogger

extension MergedSQLiteBookmarks: AccountRemovalDelegate {
    public func onRemovedAccount() -> Success {
        return self.local.onRemovedAccount() >>> self.buffer.onRemovedAccount
    }
}

extension MergedSQLiteBookmarks: ResettableSyncStorage {
    public func resetClient() -> Success {
        return self.local.resetClient() >>> self.buffer.resetClient
    }
}

extension SQLiteBookmarkBufferStorage: AccountRemovalDelegate {
    public func onRemovedAccount() -> Success {
        return self.resetClient()
    }
}

extension SQLiteBookmarkBufferStorage: ResettableSyncStorage {
    /**
     * Our buffer is simply a copy of server contents. That means we should
     * be very willing to drop it and re-populate it from the server whenever we might
     * be out of sync. See Bug 1212431 Comment 2.
     */
    public func resetClient() -> Success {
        return self.wipeBookmarks()
    }

    public func wipeBookmarks() -> Success {
        return self.db.run([
            "DELETE FROM \(TableBookmarksBufferStructure)",
            "DELETE FROM \(TableBookmarksBuffer)",
        ])
    }
}

extension SQLiteBookmarks {
    /**
     * If a synced record is deleted locally, but hasn't been synced to the server,
     * then `preserveDeletions=true` will result in that deletion being kept.
     *
     * During a reset, we'll redownload all server records. If we don't keep the
     * local deletion, then when we re-process the (non-deleted) server counterpart
     * to the now-missing local record, it'll be reinserted: the user's deletion will
     * be undone.
     *
     * Right now we don't preserve deletions when removing the Firefox Account, but
     * we could do so if we were willing to trade local database space to handle this
     * possible situation.
     */
    private func collapseMirrorIntoLocal(preservingDeletions: Bool) -> Success {
        // As implemented, this won't work correctly without ON DELETE CASCADE.
        assert(SwiftData.EnableForeignKeys)

        // 1. Wait until we commit to complain about constraint violations.
        let deferForeignKeys =
        "PRAGMA defer_foreign_keys = ON"

        // 2. Drop anything from local that's deleted. We don't need to track the
        //    deletion now. Optional: keep them around if they're non-uploaded changes.
        let removeLocalDeletions =
        "DELETE FROM \(TableBookmarksLocal) WHERE is_deleted IS 1 " +
            (preservingDeletions ? "AND sync_status IS NOT \(SyncStatus.Changed.rawValue)" : "")

        // 3. Mark everything in local as New.
        let markLocalAsNew =
        "UPDATE \(TableBookmarksLocal) SET sync_status = \(SyncStatus.new.rawValue)"

        // 4. Insert into local anything not overridden left in mirror.
        //    Note that we use the server modified time as our substitute local modified time.
        //    This will provide an ounce of conflict avoidance if the user re-links the same
        //    account at a later date.
        let copyMirrorContents =
        "INSERT OR IGNORE INTO \(TableBookmarksLocal) " +
        "(sync_status, local_modified, " +
        " guid, type, bmkUri, title, parentid, parentName, feedUri, siteUri, pos," +
        " description, tags, keyword, folderName, queryId, faviconID) " +
        "SELECT " +
        "\(SyncStatus.new.rawValue) AS sync_status, " +
        "server_modified AS local_modified, " +
        "guid, type, bmkUri, title, parentid, parentName, " +
        "feedUri, siteUri, pos, description, tags, keyword, folderName, queryId, faviconID " +
        "FROM \(TableBookmarksMirror) WHERE is_overridden IS 0"

        // 5.(pre) I have a database right in front of me that violates an assumption: a full
        // bookmarksMirrorStructure and an empty bookmarksMirror. Clean up, just in case.
        let removeOverriddenStructure =
        "DELETE FROM \(TableBookmarksMirrorStructure) WHERE parent IN (SELECT guid FROM \(TableBookmarksMirror) WHERE is_overridden IS 1)"

        // 5. Insert into localStructure anything left in mirrorStructure.
        //    This won't copy the structure of any folders that were already overridden --
        //    we already deleted those, and the deletions cascaded.
        let copyMirrorStructure =
        "INSERT INTO \(TableBookmarksLocalStructure) SELECT * FROM \(TableBookmarksMirrorStructure)"

        // 6. Blank the mirror.
        let removeMirrorStructure =
        "DELETE FROM \(TableBookmarksMirrorStructure)"

        let removeMirrorContents =
        "DELETE FROM \(TableBookmarksMirror)"

        return db.run([
            deferForeignKeys,
            removeLocalDeletions,
            markLocalAsNew,
            copyMirrorContents,
            removeOverriddenStructure,
            copyMirrorStructure,
            removeMirrorStructure,
            removeMirrorContents,
        ])
    }
}
extension SQLiteBookmarks: AccountRemovalDelegate {
    public func onRemovedAccount() -> Success {
        return self.collapseMirrorIntoLocal(preservingDeletions: false)
    }
}

extension SQLiteBookmarks: ResettableSyncStorage {
    public func resetClient() -> Success {
        // Flip flags to prompt a re-sync.
        //
        // We copy the mirror to local, preserving local changes, apart from
        // deletions of records that were never synced.
        //
        // Records that match the server record that we'll redownload will be
        // marked as Synced and won't be reuploaded.
        //
        // Records that are present locally but aren't on the server will be
        // uploaded.
        //
        return self.collapseMirrorIntoLocal(preservingDeletions: true)
    }
}
