/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
use std::fmt;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use rusqlite::types::{FromSql, FromSqlResult, ToSql, ToSqlOutput, ValueRef};
use rusqlite::Result as RusqliteResult;
use serde_derive::*;

/// Typesafe way to manage timestamps.
// XXX: copied from places, consolidate the impls later
#[derive(
    Debug, Copy, Clone, Eq, PartialEq, Ord, PartialOrd, Hash, Deserialize, Serialize, Default,
)]
pub struct Timestamp(pub u64);

impl Timestamp {
    pub fn now() -> Self {
        SystemTime::now().into()
    }
}

impl From<Timestamp> for u64 {
    fn from(ts: Timestamp) -> Self {
        ts.0
    }
}

impl From<SystemTime> for Timestamp {
    fn from(st: SystemTime) -> Self {
        let d = st.duration_since(UNIX_EPOCH).unwrap_or_default();
        Timestamp((d.as_secs() as u64) * 1000 + (u64::from(d.subsec_nanos()) / 1_000_000))
    }
}

impl From<Timestamp> for SystemTime {
    fn from(ts: Timestamp) -> Self {
        UNIX_EPOCH + Duration::from_millis(ts.into())
    }
}

impl From<u64> for Timestamp {
    fn from(ts: u64) -> Self {
        Timestamp(ts)
    }
}

impl fmt::Display for Timestamp {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl ToSql for Timestamp {
    fn to_sql(&self) -> RusqliteResult<ToSqlOutput<'_>> {
        Ok(ToSqlOutput::from(self.0 as i64)) // hrm - no u64 in rusqlite
    }
}

impl FromSql for Timestamp {
    fn column_result(value: ValueRef<'_>) -> FromSqlResult<Self> {
        value.as_i64().map(|v| Timestamp(v as u64)) // hrm - no u64
    }
}
