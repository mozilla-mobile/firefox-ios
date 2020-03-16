-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

CREATE TABLE
IF NOT EXISTS push_record
(
    uaid               TEXT     NOT NULL,
    channel_id         TEXT     NOT NULL UNIQUE,
    endpoint           TEXT     NOT NULL UNIQUE,
    scope              TEXT     NOT NULL,
    key                TEXT     NOT NULL,
    ctime              INTEGER  NOT NULL,
    app_server_key     TEXT,
    native_id          TEXT,
    PRIMARY KEY (uaid, channel_id)
);

CREATE TABLE
IF NOT EXISTS meta_data
(
    key                TEXT    PRIMARY KEY,
    value                      NOT NULL
) without ROWID;
