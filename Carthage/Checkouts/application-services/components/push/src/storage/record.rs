/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use rusqlite::Row;

use crate::crypto::KeyV1 as Key;
use crate::error::Result;

use super::types::Timestamp;

pub type ChannelID = String;

/// Meta information are various push related values that need to persist across restarts.
/// e.g. "UAID", server "auth" token, etc. This table should not be exposed outside of
/// the push component.
#[derive(Clone, Debug, PartialEq)]
pub struct MetaRecord {
    /// User Agent unique identifier
    pub key: String,
    /// Server authorization token
    pub val: String,
}

#[derive(Clone, Debug, PartialEq)]
pub struct PushRecord {
    /// User Agent's unique identifier
    pub uaid: String,

    /// Designation label provided by the subscribing service
    pub channel_id: ChannelID,

    /// Endpoint provided from the push server
    pub endpoint: String,

    /// The receipient (service worker)'s scope
    pub scope: String,

    /// Private EC Prime256v1 key info.
    pub key: Vec<u8>,

    /// Time this subscription was created.
    pub ctime: Timestamp,

    /// VAPID public key to restrict subscription updates for only those that sign
    /// using the private VAPID key.
    pub app_server_key: Option<String>,

    /// (if this is a bridged connection (e.g. on Android), this is the native OS Push ID)
    pub native_id: Option<String>,
}

impl PushRecord {
    /// Create a Push Record from the Subscription info: endpoint, encryption
    /// keys, etc.
    pub fn new(uaid: &str, chid: &str, endpoint: &str, scope: &str, key: Key) -> Self {
        // XXX: unwrap
        Self {
            uaid: uaid.to_owned(),
            channel_id: chid.to_owned(),
            endpoint: endpoint.to_owned(),
            scope: scope.to_owned(),
            key: key.serialize().unwrap(),
            ctime: Timestamp::now(),
            app_server_key: None,
            native_id: None,
        }
    }

    pub(crate) fn from_row(row: &Row<'_>) -> Result<Self> {
        Ok(PushRecord {
            uaid: row.get("uaid")?,
            channel_id: row.get("channel_id")?,
            endpoint: row.get("endpoint")?,
            scope: row.get("scope")?,
            key: row.get("key")?,
            ctime: row.get("ctime")?,
            app_server_key: row.get("app_server_key")?,
            native_id: row.get("native_id")?,
        })
    }
}
