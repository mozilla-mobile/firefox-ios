

-- A table containing every distinct schema we've seen.
CREATE TABLE remerge_schemas (
    id               INTEGER PRIMARY KEY,

    is_legacy        TINYINT NOT NULL,

    -- The version of this schema
    version          TEXT NOT NULL UNIQUE,

    -- If the schema is marked as having a required version, this is that
    -- version
    required_version TEXT,

    -- The schema's text as JSON.
    schema_text      TEXT NOT NULL
);

-- Table of local records
CREATE TABLE rec_local (
    id             INTEGER PRIMARY KEY,
    guid           TEXT NOT NULL UNIQUE,

    remerge_schema_version TEXT,
    -- XXX Should this be nullable for the case where is_deleted == true?
    record_data    TEXT NOT NULL,
    -- A local timestamp
    local_modified_ms INTEGER NOT NULL DEFAULT 0,

    is_deleted     TINYINT NOT NULL DEFAULT 0,
    sync_status    TINYINT NOT NULL DEFAULT 0,

    vector_clock   TEXT NOT NULL,
    last_writer_id TEXT NOT NULL
);

-- The "mirror", e.g. the last remote value we've seen.
CREATE TABLE rec_mirror (
    id             INTEGER PRIMARY KEY,
    guid           TEXT NOT NULL UNIQUE,

    record_data TEXT NOT NULL,

    remerge_schema_version TEXT,

    -- in milliseconds (a sync15::ServerTimestamp multiplied by 1000 and truncated)
    server_modified_ms INTEGER NOT NULL,

    -- Whether or not there have been local changes to the record.
    is_overridden   TINYINT NOT NULL DEFAULT 0,

    vector_clock   TEXT, -- Can be null for legacy collections...
    last_writer_id TEXT NOT NULL -- A sync guid.
);


-- Extra metadata. See `storage/bootstrap.rs` for information about the
-- contents. Arguably, should be changed into a table that only contains one
-- row, but we handle setting it up separately from schema initialization,
-- so migration would be tricky
CREATE TABLE metadata (key TEXT PRIMARY KEY, value BLOB) WITHOUT ROWID;
