PRAGMA user_version=39;
PRAGMA foreign_keys=ON;
PRAGMA synchronous=NORMAL;

CREATE TABLE history (
    _id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    url TEXT NOT NULL,
    visits INTEGER NOT NULL DEFAULT 0,
    visits_local INTEGER NOT NULL DEFAULT 0,
    visits_remote INTEGER NOT NULL DEFAULT 0,
    favicon_id INTEGER,
    date INTEGER,
    date_local INTEGER NOT NULL DEFAULT 0,
    date_remote INTEGER NOT NULL DEFAULT 0,
    created INTEGER,
    modified INTEGER,
    guid TEXT NOT NULL,
    deleted INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE visits (
    _id INTEGER PRIMARY KEY AUTOINCREMENT,
    history_guid TEXT NOT NULL,
    visit_type TINYINT NOT NULL DEFAULT 1,
    date INTEGER NOT NULL,
    is_local TINYINT NOT NULL DEFAULT 1,
    FOREIGN KEY (history_guid) REFERENCES history(guid) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX history_guid_index ON history(guid);
CREATE INDEX history_modified_index ON history(modified);
CREATE INDEX history_url_index ON history(url);
CREATE INDEX history_visited_index ON history(date);
CREATE UNIQUE INDEX visits_history_guid_and_date_visited_index ON visits(history_guid,date);
CREATE INDEX visits_history_guid_index ON visits(history_guid);
