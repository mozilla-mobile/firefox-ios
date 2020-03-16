/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const VERSION: i64 = 1;
use crate::error::Result;
use rusqlite::Connection;
use sql_support::ConnExt;

pub fn init(db: &Connection) -> Result<()> {
    let user_version = db.query_one::<i64>("PRAGMA user_version")?;
    if user_version == 0 {
        create(db.conn())?;
    } else if user_version != VERSION {
        if user_version < VERSION {
            upgrade(db.conn(), user_version)?;
        } else {
            log::warn!(
                "Loaded future database schema version {} (we only understand version {}). \
                 Optimistically ",
                user_version,
                VERSION
            )
        }
    }
    Ok(())
}

fn upgrade(_: &Connection, from: i64) -> Result<()> {
    log::debug!("Upgrading schema from {} to {}", from, VERSION);
    if from == VERSION {
        return Ok(());
    }
    unimplemented!("FIXME: migration");
}

pub fn create(db: &Connection) -> Result<()> {
    log::debug!("Creating schema");
    db.execute_batch(include_str!("../../sql/schema.sql"))?;
    db.execute_batch(&format!(
        "PRAGMA user_version = {version}",
        version = VERSION
    ))?;
    Ok(())
}
