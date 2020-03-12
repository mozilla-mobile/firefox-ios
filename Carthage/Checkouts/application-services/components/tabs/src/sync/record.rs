/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::error::*;
use serde_derive::{Deserialize, Serialize};

#[derive(Debug, Clone, Hash, PartialEq, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct TabsRecordTab {
    pub title: String,
    pub url_history: Vec<String>,
    pub icon: Option<String>,
    pub last_used: u64, // Seconds since epoch!
}

#[derive(Debug, Clone, Hash, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct TabsRecord {
    pub id: String, // `String` instead of `SyncGuid` because some IDs are FxA device ID.
    pub client_name: String,
    pub tabs: Vec<TabsRecordTab>,
}

impl TabsRecord {
    #[inline]
    pub fn from_payload(payload: sync15::Payload) -> Result<Self> {
        let record: TabsRecord = payload.into_record()?;
        Ok(record)
    }
}
