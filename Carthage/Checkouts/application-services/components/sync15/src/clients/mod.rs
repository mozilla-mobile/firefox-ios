/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use std::collections::HashSet;

use failure;

mod engine;
mod record;
mod ser;

pub use engine::Engine;
pub use sync15_traits::client::{ClientData, DeviceType, RemoteClient};

// These are what desktop uses.
const CLIENTS_TTL: u32 = 1_814_400; // 21 days
pub(crate) const CLIENTS_TTL_REFRESH: u64 = 604_800; // 7 days

/// A command processor applies incoming commands like wipes and resets for all
/// stores, and returns commands to send to other clients. It also manages
/// settings like the device name and type, which is stored in the special
/// `clients` collection.
///
/// In practice, this trait only has one implementation, in the sync manager.
/// It's split this way because the clients engine depends on internal `sync15`
/// structures, and can't be implemented as a syncable store...but `sync15`
/// doesn't know anything about multiple engines. This lets the sync manager
/// provide its own implementation for handling wipe and reset commands for all
/// the engines that it manages.
pub trait CommandProcessor {
    fn settings(&self) -> &Settings;

    /// Fetches commands to send to other clients. An error return value means
    /// commands couldn't be fetched, and halts the sync.
    fn fetch_outgoing_commands(&self) -> Result<HashSet<Command>, failure::Error>;

    /// Applies a command sent to this client from another client. This method
    /// should return a `CommandStatus` indicating whether the command was
    /// processed.
    ///
    /// An error return value means the sync manager encountered an error
    /// applying the command, and halts the sync to prevent unexpected behavior
    /// (for example, merging local and remote bookmarks, when we were told to
    /// wipe our local bookmarks).
    fn apply_incoming_command(&self, command: Command) -> Result<CommandStatus, failure::Error>;
}

/// Indicates if a command was applied successfully, ignored, or not supported.
/// Applied and ignored commands are removed from our client record, and never
/// retried. Unsupported commands are put back into our record, and retried on
/// subsequent syncs. This is to handle clients adding support for new data
/// types.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub enum CommandStatus {
    Applied,
    Ignored,
    Unsupported,
}

impl From<&record::ClientRecord> for RemoteClient {
    fn from(record: &record::ClientRecord) -> RemoteClient {
        RemoteClient {
            fxa_device_id: record.fxa_device_id.clone(),
            device_name: record.name.clone(),
            device_type: record.typ.as_ref().and_then(DeviceType::try_from_str),
        }
    }
}

/// Information about this device to include in its client record. This should
/// be persisted across syncs, as part of the sync manager state.
#[derive(Clone, Debug, Eq, Hash, PartialEq)]
pub struct Settings {
    /// The FxA device ID of this client, also used as this client's record ID
    /// in the clients collection.
    pub fxa_device_id: String,
    /// The name of this client. This should match the client's name in the
    /// FxA device manager.
    pub device_name: String,
    /// The type of this client: mobile, tablet, desktop, or other.
    pub device_type: DeviceType,
}

#[derive(Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub enum Command {
    /// Erases all local data.
    WipeAll,
    /// Erases all local data for a specific engine.
    Wipe(String),
    /// Resets local sync state for all engines.
    ResetAll,
    /// Resets local sync state for a specific engine.
    Reset(String),
}
