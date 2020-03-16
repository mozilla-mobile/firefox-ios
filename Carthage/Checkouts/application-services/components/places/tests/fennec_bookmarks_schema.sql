PRAGMA user_version=39;
PRAGMA foreign_keys=ON;
PRAGMA synchronous=NORMAL;

CREATE TABLE bookmarks(
    _id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    url TEXT,
    type INTEGER NOT NULL DEFAULT 1,
    parent INTEGER,
    position INTEGER NOT NULL,
    keyword TEXT,
    description TEXT,
    tags TEXT,
    favicon_id INTEGER,
    created INTEGER,
    modified INTEGER,
    guid TEXT NOT NULL,
    deleted INTEGER NOT NULL DEFAULT 0,
    localVersion INTEGER NOT NULL DEFAULT 1,
    syncVersion INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (parent) REFERENCES bookmarks(_id)
);

CREATE UNIQUE INDEX bookmarks_guid_index ON bookmarks(guid);
CREATE INDEX bookmarks_modified_index ON bookmarks(modified);
CREATE INDEX bookmarks_type_deleted_index ON bookmarks(type, deleted);
CREATE INDEX bookmarks_url_index ON bookmarks(url);
