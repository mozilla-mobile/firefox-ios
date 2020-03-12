/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![allow(unknown_lints, clippy::implicit_hasher)]
#![warn(rust_2018_idioms)]

mod bso_record;
pub mod changeset;
mod client;
pub mod clients;
mod coll_state;
mod collection_keys;
mod error;
mod key_bundle;
mod migrate_state;
mod record_types;
mod request;
mod state;
mod status;
mod sync;
mod sync_multiple;
pub mod telemetry;
mod token;
mod util;

// Re-export some of the types callers are likely to want for convenience.
pub use crate::bso_record::{BsoRecord, CleartextBso, EncryptedBso, EncryptedPayload, Payload};
pub use crate::changeset::{IncomingChangeset, OutgoingChangeset, RecordChangeset};
pub use crate::client::{
    SetupStorageClient, Sync15ClientResponse, Sync15StorageClient, Sync15StorageClientInit,
};
pub use crate::coll_state::{CollState, CollSyncIds, StoreSyncAssociation};
pub use crate::collection_keys::CollectionKeys;
pub use crate::error::{Error, ErrorKind, Result};
pub use crate::key_bundle::KeyBundle;
pub use crate::migrate_state::extract_v1_state;
pub use crate::request::CollectionRequest;
pub use crate::state::{GlobalState, SetupStateMachine};
pub use crate::status::{ServiceStatus, SyncResult};
pub use crate::sync::{synchronize, Store};
pub use crate::sync_multiple::{
    sync_multiple, sync_multiple_with_command_processor, MemoryCachedState, SyncRequestInfo,
};
pub use crate::util::ServerTimestamp;
