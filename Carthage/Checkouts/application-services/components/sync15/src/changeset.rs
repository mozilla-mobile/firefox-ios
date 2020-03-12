/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::bso_record::{CleartextBso, EncryptedBso};
use crate::client::{Sync15ClientResponse, Sync15StorageClient};
use crate::error::{self, ErrorKind, ErrorResponse, Result};
use crate::key_bundle::KeyBundle;
use crate::request::{CollectionRequest, NormalResponseHandler, UploadInfo};
use crate::util::ServerTimestamp;
use crate::CollState;
use std::borrow::Cow;

pub use sync15_traits::{IncomingChangeset, OutgoingChangeset, RecordChangeset};

pub fn encrypt_outgoing(o: OutgoingChangeset, key: &KeyBundle) -> Result<Vec<EncryptedBso>> {
    let RecordChangeset {
        changes,
        collection,
        ..
    } = o;
    changes
        .into_iter()
        .map(|change| CleartextBso::from_payload(change, collection.clone()).encrypt(key))
        .collect()
}

pub fn fetch_incoming(
    client: &Sync15StorageClient,
    state: &mut CollState,
    collection_request: &CollectionRequest,
) -> Result<IncomingChangeset> {
    let collection = collection_request.collection.clone();
    let (records, timestamp) = match client.get_encrypted_records(collection_request)? {
        Sync15ClientResponse::Success {
            record,
            last_modified,
            ..
        } => (record, last_modified),
        other => return Err(other.create_storage_error().into()),
    };
    // xxx - duplication below of `timestamp` smells wrong
    state.last_modified = timestamp;
    let mut result = IncomingChangeset::new(collection, timestamp);
    result.changes.reserve(records.len());
    for record in records {
        // if we see a HMAC error, we've made an explicit decision to
        // NOT handle it here, but restart the global state machine.
        // That should cause us to re-read crypto/keys and things should
        // work (although if for some reason crypto/keys was updated but
        // not all storage was wiped we are probably screwed.)
        let decrypted = record.decrypt(&state.key)?;
        result.changes.push(decrypted.into_timestamped_payload());
    }
    Ok(result)
}

#[derive(Debug, Clone)]
pub struct CollectionUpdate<'a> {
    client: &'a Sync15StorageClient,
    state: &'a CollState,
    collection: Cow<'static, str>,
    xius: ServerTimestamp,
    to_update: Vec<EncryptedBso>,
    fully_atomic: bool,
}

impl<'a> CollectionUpdate<'a> {
    pub fn new(
        client: &'a Sync15StorageClient,
        state: &'a CollState,
        collection: Cow<'static, str>,
        xius: ServerTimestamp,
        records: Vec<EncryptedBso>,
        fully_atomic: bool,
    ) -> CollectionUpdate<'a> {
        CollectionUpdate {
            client,
            state,
            collection,
            xius,
            to_update: records,
            fully_atomic,
        }
    }

    pub fn new_from_changeset(
        client: &'a Sync15StorageClient,
        state: &'a CollState,
        changeset: OutgoingChangeset,
        fully_atomic: bool,
    ) -> Result<CollectionUpdate<'a>> {
        let collection = changeset.collection.clone();
        let xius = changeset.timestamp;
        if xius < state.last_modified {
            // We know we are going to fail the XIUS check...
            return Err(
                ErrorKind::StorageHttpError(ErrorResponse::PreconditionFailed {
                    route: collection.into_owned(),
                })
                .into(),
            );
        }
        let to_update = crate::changeset::encrypt_outgoing(changeset, &state.key)?;
        Ok(CollectionUpdate::new(
            client,
            state,
            collection,
            xius,
            to_update,
            fully_atomic,
        ))
    }

    /// Returns a list of the IDs that failed if allowed_dropped_records is true, otherwise
    /// returns an empty vec.
    pub fn upload(self) -> error::Result<UploadInfo> {
        let mut failed = vec![];
        let mut q = self.client.new_post_queue(
            &self.collection,
            &self.state.config,
            self.xius,
            NormalResponseHandler::new(!self.fully_atomic),
        )?;

        for record in self.to_update.into_iter() {
            let enqueued = q.enqueue(&record)?;
            if !enqueued && self.fully_atomic {
                return Err(ErrorKind::RecordTooLargeError.into());
            }
        }

        q.flush(true)?;
        let mut info = q.completed_upload_info();
        info.failed_ids.append(&mut failed);
        if self.fully_atomic {
            assert_eq!(
                info.failed_ids.len(),
                0,
                "Bug: Should have failed by now if we aren't allowing dropped records"
            );
        }
        Ok(info)
    }
}
