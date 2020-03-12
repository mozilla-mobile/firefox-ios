/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
use rusqlite::Connection;
use sql_support::ConnExt;

use crate::error::Result;

const VERSION: i64 = 2;

const CREATE_TABLE_PUSH_SQL: &str = include_str!("schema.sql");

pub const COMMON_COLS: &str = "
    uaid,
    channel_id,
    endpoint,
    scope,
    key,
    ctime,
    app_server_key,
    native_id
";

pub fn init(db: &Connection) -> Result<()> {
    let user_version = db.query_one::<i64>("PRAGMA user_version")?;
    if user_version == 0 {
        create(db)?;
    } else if user_version != VERSION {
        if user_version < VERSION {
            upgrade(db, user_version)?;
        } else {
            log::warn!(
                "Loaded future schema version {} (we only understand version {}). \
                 Optimistically ",
                user_version,
                VERSION
            )
        }
    }
    Ok(())
}

fn upgrade(db: &Connection, from: i64) -> Result<()> {
    log::debug!("Upgrading schema from {} to {}", from, VERSION);
    match from {
        VERSION => Ok(()),
        0 => create(db),
        1 => create(db),
        _ => panic!("sorry, no upgrades yet - delete your db!"),
    }
}

pub fn create(db: &Connection) -> Result<()> {
    let statements = format!(
        "{create}\n\nPRAGMA user_version = {version}",
        create = CREATE_TABLE_PUSH_SQL,
        version = VERSION
    );
    db.execute_batch(&statements)?;

    Ok(())
}
