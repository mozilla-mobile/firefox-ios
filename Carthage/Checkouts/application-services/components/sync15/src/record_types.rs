/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use serde_derive::*;
use std::collections::HashMap;
use sync_guid::Guid;

// Known record formats.

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct MetaGlobalEngine {
    pub version: usize,
    #[serde(rename = "syncID")]
    pub sync_id: Guid,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct MetaGlobalRecord {
    #[serde(rename = "syncID")]
    pub sync_id: Guid,
    #[serde(rename = "storageVersion")]
    pub storage_version: usize,
    #[serde(default)]
    pub engines: HashMap<String, MetaGlobalEngine>,
    #[serde(default)]
    pub declined: Vec<String>,
}

#[derive(Deserialize, Serialize, Clone, Debug, Eq, PartialEq)]
pub struct CryptoKeysRecord {
    pub id: Guid,
    pub collection: String,
    pub default: [String; 2],
    pub collections: HashMap<String, [String; 2]>,
}

#[cfg(test)]
#[test]
fn test_deserialize_meta_global() {
    let record = serde_json::json!({
        "syncID": "abcd1234abcd",
        "storageVersion": 1,
    })
    .to_string();
    let r = serde_json::from_str::<MetaGlobalRecord>(&record).unwrap();
    assert_eq!(r.sync_id, "abcd1234abcd");
    assert_eq!(r.storage_version, 1);
    assert_eq!(r.engines.len(), 0);
    assert_eq!(r.declined.len(), 0);
}
