/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use super::ServerVisitTimestamp;
use crate::error::*;
use serde_derive::*;
use sync_guid::Guid as SyncGuid;

#[derive(Debug, Clone, Hash, PartialEq, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct HistoryRecordVisit {
    pub date: ServerVisitTimestamp,
    #[serde(rename = "type")]
    pub transition: u8,
}

#[derive(Debug, Clone, Hash, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct HistoryRecord {
    // TODO: consider `#[serde(rename = "id")] pub guid: String` to avoid confusion
    pub id: SyncGuid,

    #[serde(default)]
    #[serde(skip_serializing_if = "String::is_empty")]
    pub title: String,

    pub hist_uri: String,

    pub visits: Vec<HistoryRecordVisit>,

    // These fields are somewhat magic - they are moved to and from the
    // BSO record, so are not expected to be on the unencrypted payload
    // when incoming and are not put on the unencrypted payload when outgoing.
    // There are hysterical raisens for this, which we should fix.
    // https://github.com/mozilla/application-services/issues/2712
    #[serde(default)]
    pub sortindex: i32,

    #[serde(default)]
    pub ttl: u32,
}

#[derive(Debug)]
pub struct HistorySyncRecord {
    pub guid: SyncGuid,
    pub record: Option<HistoryRecord>,
}

impl HistorySyncRecord {
    pub fn from_payload(payload: sync15::Payload) -> Result<Self> {
        let guid = payload.id.clone();
        let record: Option<HistoryRecord> = if payload.is_tombstone() {
            None
        } else {
            let record: HistoryRecord = payload.into_record()?;
            Some(record)
        };
        Ok(Self { guid, record })
    }
}
