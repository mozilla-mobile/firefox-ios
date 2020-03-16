/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::types::Timestamp;
use serde_derive::*;
use std::fmt;
use std::time::{SystemTime, UNIX_EPOCH};

mod plan;
pub mod record;
pub mod store;

const MAX_INCOMING_PLACES: usize = 5000;
const MAX_OUTGOING_PLACES: usize = 5000;
const MAX_VISITS: usize = 20;
pub const HISTORY_TTL: u32 = 5_184_000; // 60 days in milliseconds

/// Visit timestamps on the server are *microseconds* since the epoch.
#[derive(
    Debug, Copy, Clone, Eq, PartialEq, Ord, PartialOrd, Hash, Deserialize, Serialize, Default,
)]
pub struct ServerVisitTimestamp(pub u64);

impl From<ServerVisitTimestamp> for Timestamp {
    #[inline]
    fn from(ts: ServerVisitTimestamp) -> Timestamp {
        Timestamp(ts.0 / 1000)
    }
}

impl From<Timestamp> for ServerVisitTimestamp {
    #[inline]
    fn from(ts: Timestamp) -> ServerVisitTimestamp {
        ServerVisitTimestamp(ts.0 * 1000)
    }
}

impl From<SystemTime> for ServerVisitTimestamp {
    #[inline]
    fn from(st: SystemTime) -> Self {
        let d = st.duration_since(UNIX_EPOCH).unwrap_or_default();
        ServerVisitTimestamp(
            (d.as_secs() as u64) * 1_000_000 + (u64::from(d.subsec_nanos()) / 1_000),
        )
    }
}

impl fmt::Display for ServerVisitTimestamp {
    #[inline]
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}
