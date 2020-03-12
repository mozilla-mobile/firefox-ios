-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

-- This file defines temp tables and views for the Sync connection.

CREATE TEMP TABLE changeGuidOps(
    localGuid TEXT PRIMARY KEY,
    mergedGuid TEXT UNIQUE NOT NULL,
    syncStatus INTEGER,
    level INTEGER NOT NULL,
    lastModified INTEGER NOT NULL -- In milliseconds.
) WITHOUT ROWID;

CREATE TEMP TABLE itemsToApply(
    mergedGuid TEXT PRIMARY KEY,
    localId INTEGER UNIQUE,
    remoteId INTEGER UNIQUE NOT NULL,
    remoteGuid TEXT UNIQUE NOT NULL,
    newLevel INTEGER NOT NULL,
    newKind INTEGER NOT NULL,
    localDateAdded INTEGER, -- In milliseconds.
    remoteDateAdded INTEGER NOT NULL, -- In milliseconds.
    lastModified INTEGER NOT NULL, -- In milliseconds.
    oldTitle TEXT,
    newTitle TEXT,
    oldPlaceId INTEGER,
    newPlaceId INTEGER
);

CREATE INDEX existingItems ON itemsToApply(localId) WHERE localId NOT NULL;

CREATE INDEX oldPlaceIds ON itemsToApply(newKind, oldPlaceId);

CREATE INDEX newPlaceIds ON itemsToApply(newKind, newPlaceId);

CREATE TEMP TABLE applyNewLocalStructureOps(
    mergedGuid TEXT PRIMARY KEY,
    mergedParentGuid TEXT NOT NULL,
    position INTEGER NOT NULL,
    level INTEGER NOT NULL,
    lastModified INTEGER NOT NULL -- In milliseconds.
) WITHOUT ROWID;

-- Stores locally changed items staged for upload.
CREATE TEMP TABLE itemsToUpload(
    id INTEGER PRIMARY KEY,
    guid TEXT UNIQUE NOT NULL,
    syncChangeCounter INTEGER NOT NULL,
    -- The server modified time for the uploaded record. This is *not* a
    -- ServerTimestamp.
    uploadedAt INTEGER NOT NULL DEFAULT -1,
    isDeleted BOOLEAN NOT NULL DEFAULT 0,
    parentGuid TEXT,
    parentTitle TEXT,
    dateAdded INTEGER, -- In milliseconds.
    kind INTEGER,
    title TEXT,
    placeId INTEGER,
    url TEXT,
    keyword TEXT,
    position INTEGER
);

CREATE TEMP TABLE structureToUpload(
    guid TEXT PRIMARY KEY,
    parentId INTEGER NOT NULL REFERENCES itemsToUpload(id)
                              ON DELETE CASCADE,
    position INTEGER NOT NULL
) WITHOUT ROWID;

CREATE TEMP TABLE tagsToUpload(
    id INTEGER REFERENCES itemsToUpload(id)
               ON DELETE CASCADE,
    tag TEXT,
    PRIMARY KEY(id, tag)
) WITHOUT ROWID;
