/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::bso_record::{EncryptedBso, Payload};
use crate::error::Result;
use crate::key_bundle::KeyBundle;
use crate::record_types::CryptoKeysRecord;
use crate::util::ServerTimestamp;
use std::collections::HashMap;

#[derive(Clone, Debug, PartialEq)]
pub struct CollectionKeys {
    pub timestamp: ServerTimestamp,
    pub default: KeyBundle,
    pub collections: HashMap<String, KeyBundle>,
}

impl CollectionKeys {
    pub fn new_random() -> Result<CollectionKeys> {
        let default = KeyBundle::new_random()?;
        Ok(CollectionKeys {
            timestamp: ServerTimestamp(0),
            default,
            collections: HashMap::new(),
        })
    }

    pub fn from_encrypted_bso(
        record: EncryptedBso,
        root_key: &KeyBundle,
    ) -> Result<CollectionKeys> {
        let keys = record.decrypt_as::<CryptoKeysRecord>(root_key)?;
        Ok(CollectionKeys {
            timestamp: keys.modified,
            default: KeyBundle::from_base64(&keys.payload.default[0], &keys.payload.default[1])?,
            collections: keys
                .payload
                .collections
                .into_iter()
                .map(|kv| Ok((kv.0, KeyBundle::from_base64(&kv.1[0], &kv.1[1])?)))
                .collect::<Result<HashMap<String, KeyBundle>>>()?,
        })
    }

    pub fn to_encrypted_bso(&self, root_key: &KeyBundle) -> Result<EncryptedBso> {
        let record = CryptoKeysRecord {
            id: "keys".into(),
            collection: "crypto".into(),
            default: self.default.to_b64_array(),
            collections: self
                .collections
                .iter()
                .map(|kv| (kv.0.clone(), kv.1.to_b64_array()))
                .collect(),
        };
        let bso = crate::CleartextBso::from_payload(Payload::from_record(record)?, "crypto");
        Ok(bso.encrypt(root_key)?)
    }

    pub fn key_for_collection<'a>(&'a self, collection: &str) -> &'a KeyBundle {
        self.collections.get(collection).unwrap_or(&self.default)
    }
}
