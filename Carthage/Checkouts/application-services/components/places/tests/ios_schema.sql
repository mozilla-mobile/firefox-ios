
-- Output of iOS `.schema` with unrelated entries filtered out.
CREATE TABLE IF NOT EXISTS "bookmarksBuffer" (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    guid TEXT NOT NULL UNIQUE,
    type TINYINT NOT NULL,
    server_modified INTEGER NOT NULL,
    is_deleted TINYINT NOT NULL DEFAULT 0,
    hasDupe TINYINT NOT NULL DEFAULT 0,
    parentid TEXT,
    parentName TEXT,
    feedUri TEXT,
    siteUri TEXT,
    pos INT,
    title TEXT,
    description TEXT,
    bmkUri TEXT,
    tags TEXT,
    keyword TEXT,
    folderName TEXT,
    queryId TEXT,
    date_added INTEGER,
    CONSTRAINT parentidOrDeleted CHECK (parentid IS NOT NULL OR is_deleted = 1),
    CONSTRAINT parentNameOrDeleted CHECK (parentName IS NOT NULL OR is_deleted = 1)
);

CREATE TABLE IF NOT EXISTS "bookmarksBufferStructure" (
    parent TEXT NOT NULL REFERENCES "bookmarksBuffer"(guid) ON DELETE CASCADE,
    child TEXT NOT NULL,
    idx INTEGER NOT NULL
);

CREATE TABLE bookmarksLocal (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    guid TEXT NOT NULL UNIQUE,
    type TINYINT NOT NULL,
    is_deleted TINYINT NOT NULL DEFAULT 0,
    parentid TEXT,
    parentName TEXT,
    feedUri TEXT,
    siteUri TEXT,
    pos INT,
    title TEXT,
    description TEXT,
    bmkUri TEXT,
    tags TEXT,
    keyword TEXT,
    folderName TEXT,
    queryId TEXT,
    local_modified INTEGER,
    sync_status TINYINT NOT NULL DEFAULT 0, -- NOTE(thom): I added default 0 here so we don't have to specify it.
    faviconID INTEGER, --REFERENCES favicons(id) ON DELETE SET NULL,
    date_added INTEGER,
    CONSTRAINT parentidOrDeleted CHECK (parentid IS NOT NULL OR is_deleted = 1),
    CONSTRAINT parentNameOrDeleted CHECK (parentName IS NOT NULL OR is_deleted = 1)
);

CREATE TABLE bookmarksMirror (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    guid TEXT NOT NULL UNIQUE,
    type TINYINT NOT NULL,
    is_deleted TINYINT NOT NULL DEFAULT 0,
    parentid TEXT,
    parentName TEXT,
    feedUri TEXT,
    siteUri TEXT,
    pos INT,
    title TEXT,
    description TEXT,
    bmkUri TEXT,
    tags TEXT,
    keyword TEXT,
    folderName TEXT,
    queryId TEXT,
    server_modified INTEGER NOT NULL,
    hasDupe TINYINT NOT NULL DEFAULT 0,
    is_overridden TINYINT NOT NULL DEFAULT 0,
    faviconID INTEGER, --REFERENCES favicons(id) ON DELETE SET NULL,
    date_added INTEGER,
    CONSTRAINT parentidOrDeleted CHECK (parentid IS NOT NULL OR is_deleted = 1),
    CONSTRAINT parentNameOrDeleted CHECK (parentName IS NOT NULL OR is_deleted = 1)
);

CREATE TABLE bookmarksLocalStructure (
    parent TEXT NOT NULL REFERENCES bookmarksLocal(guid) ON DELETE CASCADE,
    child TEXT NOT NULL,
    idx INTEGER NOT NULL
);

CREATE TABLE bookmarksMirrorStructure (
    parent TEXT NOT NULL REFERENCES bookmarksMirror(guid) ON DELETE CASCADE,
    child TEXT NOT NULL,
    idx INTEGER NOT NULL
);

CREATE INDEX idx_bookmarksBufferStructure_parent_idx ON bookmarksBufferStructure (parent, idx);
CREATE INDEX idx_bookmarksLocalStructure_parent_idx ON bookmarksLocalStructure (parent, idx);
CREATE INDEX idx_bookmarksMirrorStructure_parent_idx ON bookmarksMirrorStructure (parent, idx);

CREATE INDEX idx_bookmarksBuffer_keyword ON bookmarksBuffer (keyword);
CREATE INDEX idx_bookmarksLocal_keyword ON bookmarksLocal (keyword);
CREATE INDEX idx_bookmarksMirror_keyword ON bookmarksMirror (keyword);
