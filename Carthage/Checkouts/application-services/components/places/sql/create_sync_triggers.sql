-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

-- This file defines triggers for the Sync connection.

--- Pushes uploaded changes back to the local and remote trees. This is more
--- or less equivalent to Desktop's `PlacesSyncUtils.bookmarks.pushChanges`.
CREATE TEMP TRIGGER pushUploadedChanges
AFTER UPDATE OF uploadedAt ON itemsToUpload WHEN NEW.uploadedAt > -1
BEGIN
    -- Reduce the change counter and update the sync status for uploaded items.
    -- If the item was uploaded during the sync, its change counter will still
    -- be > 0 for the next sync.
    UPDATE moz_bookmarks SET
        syncChangeCounter = max(syncChangeCounter - NEW.syncChangeCounter, 0),
        syncStatus = 2 -- SyncStatus::Normal
    WHERE guid = NEW.guid;

    -- Remove uploaded tombstones.
    DELETE FROM moz_bookmarks_deleted
    WHERE guid = NEW.guid;

    -- Write the uploaded item back to the synced bookmarks table, to match
    -- what's on the server now.
    REPLACE INTO moz_bookmarks_synced(guid, parentGuid, serverModified, needsMerge,
                                      validity, isDeleted, kind, dateAdded, title,
                                      placeId, keyword)
    VALUES(NEW.guid, NEW.parentGuid, NEW.uploadedAt, 0,
           1, -- SyncedBookmarkValidity::Valid
           NEW.isDeleted, NEW.kind, NEW.dateAdded, NEW.title,
           NEW.placeId, NEW.keyword);

    -- Update the list of children to reflect what we just uploaded.
    INSERT INTO moz_bookmarks_synced_structure(guid, parentGuid, position)
    SELECT guid, NEW.guid, position
    FROM structureToUpload
    WHERE parentId = NEW.id;

    -- ...And tags, too.
    INSERT INTO moz_bookmarks_synced_tag_relation(itemId, tagId)
    SELECT v.id, (SELECT t.id FROM moz_tags t
                  WHERE t.tag = o.tag)
    FROM tagsToUpload o
    JOIN itemsToUpload u ON u.id = o.id
    JOIN moz_bookmarks_synced v ON v.guid = u.guid
    WHERE o.id = NEW.id;
END;

CREATE TEMP TRIGGER changeGuids
AFTER DELETE ON changeGuidOps
BEGIN
  UPDATE moz_bookmarks SET
    guid = OLD.mergedGuid,
    lastModified = OLD.lastModified,
    syncStatus = IFNULL(OLD.syncStatus, syncStatus)
  WHERE guid = OLD.localGuid;
END;

CREATE TEMP TRIGGER applyNewLocalStructure
AFTER DELETE ON applyNewLocalStructureOps
BEGIN
  UPDATE moz_bookmarks SET
    parent = (SELECT id FROM moz_bookmarks
              WHERE guid = OLD.mergedParentGuid),
    position = OLD.position,
    lastModified = OLD.lastModified
  WHERE guid = OLD.mergedGuid;
END;
