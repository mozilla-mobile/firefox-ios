/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use rusqlite::types::{FromSql, FromSqlResult, ToSql, ToSqlOutput, ValueRef};
use serde::{Deserialize, Serialize};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

fn duration_ms(d: Duration) -> i64 {
    (d.as_secs() as i64) * 1000 + ((d.subsec_nanos() as i64) / 1_000_000)
}

#[derive(Copy, Clone, Eq, PartialEq, Ord, PartialOrd, Hash, Deserialize, Serialize, Default)]
#[serde(transparent)]
pub struct MsTime(pub i64);

/// Release of WorldWideWeb, the first web browser. Synced data could never come
/// from before this date. XXX this could be untrue for new collections...
pub const EARLIEST_SANE_TIME: MsTime = MsTime(662_083_200_000);

impl MsTime {
    #[inline]
    pub fn now() -> Self {
        SystemTime::now().into()
    }

    #[inline]
    pub fn from_millis(ts: i64) -> Self {
        MsTime(ts)
    }

    /// Note: panics if `u64` is too large (which would require an
    /// astronomically large timestamp)
    #[inline]
    pub fn from_unsigned_millis(ts: u64) -> Self {
        assert!(ts < (std::i64::MAX as u64));
        MsTime(ts as i64)
    }
}

impl std::ops::Sub for MsTime {
    type Output = Duration;
    fn sub(self, o: MsTime) -> Duration {
        if o > self {
            log::error!(
                "Attempt to subtract larger time from smaller: {} - {}",
                self,
                o
            );
            Duration::default()
        } else {
            Duration::from_millis((self.0 - o.0) as u64)
        }
    }
}

impl From<MsTime> for serde_json::Value {
    fn from(ts: MsTime) -> Self {
        ts.0.into()
    }
}

impl From<MsTime> for u64 {
    #[inline]
    fn from(ts: MsTime) -> Self {
        assert!(ts.0 >= 0);
        ts.0 as u64
    }
}

impl From<MsTime> for i64 {
    #[inline]
    fn from(ts: MsTime) -> Self {
        ts.0
    }
}

impl From<SystemTime> for MsTime {
    #[inline]
    fn from(st: SystemTime) -> Self {
        let d = st.duration_since(UNIX_EPOCH).unwrap_or_default();
        MsTime(duration_ms(d))
    }
}

impl From<MsTime> for SystemTime {
    #[inline]
    fn from(ts: MsTime) -> Self {
        UNIX_EPOCH + Duration::from_millis(ts.into())
    }
}

impl std::fmt::Display for MsTime {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        std::fmt::Display::fmt(&self.0, f)
    }
}

impl std::fmt::Debug for MsTime {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        std::fmt::Debug::fmt(&self.0, f)
    }
}

impl ToSql for MsTime {
    fn to_sql(&self) -> rusqlite::Result<ToSqlOutput<'_>> {
        Ok(ToSqlOutput::from(self.0))
    }
}

impl FromSql for MsTime {
    fn column_result(value: ValueRef<'_>) -> FromSqlResult<Self> {
        value.as_i64().map(MsTime)
    }
}

impl PartialEq<i64> for MsTime {
    #[inline]
    fn eq(&self, o: &i64) -> bool {
        self.0 == *o
    }
}

impl PartialEq<u64> for MsTime {
    #[inline]
    fn eq(&self, o: &u64) -> bool {
        *o < (std::i64::MAX as u64) && self.0 > 0 && self.0 == (*o as i64)
    }
}

impl PartialEq<MsTime> for i64 {
    #[inline]
    fn eq(&self, o: &MsTime) -> bool {
        PartialEq::eq(o, self)
    }
}

impl PartialEq<MsTime> for u64 {
    #[inline]
    fn eq(&self, o: &MsTime) -> bool {
        PartialEq::eq(o, self)
    }
}

impl std::cmp::PartialOrd<i64> for MsTime {
    #[inline]
    fn partial_cmp(&self, o: &i64) -> Option<std::cmp::Ordering> {
        std::cmp::PartialOrd::partial_cmp(&self.0, o)
    }
}

// partialord must be symmetric
impl std::cmp::PartialOrd<MsTime> for i64 {
    #[inline]
    fn partial_cmp(&self, o: &MsTime) -> Option<std::cmp::Ordering> {
        std::cmp::PartialOrd::partial_cmp(self, &o.0)
    }
}
