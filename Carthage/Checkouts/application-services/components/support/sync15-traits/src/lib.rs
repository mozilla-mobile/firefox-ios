/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![warn(rust_2018_idioms)]
mod changeset;
pub mod client;
mod payload;
pub mod request;
mod server_timestamp;
mod store;
pub mod telemetry;

pub use changeset::{IncomingChangeset, OutgoingChangeset, RecordChangeset};
pub use payload::Payload;
pub use request::{CollectionRequest, RequestOrder};
pub use server_timestamp::ServerTimestamp;
pub use store::{CollSyncIds, Store, StoreSyncAssociation};
pub use sync_guid::Guid;

// For skip_serializing_if
pub(crate) fn skip_if_default<T: PartialEq + Default>(v: &T) -> bool {
    *v == T::default()
}
