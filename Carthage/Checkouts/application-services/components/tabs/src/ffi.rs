/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// This module implement the traits that make the FFI code easier to manage.

use crate::{msg_types, ClientRemoteTabs, Error, ErrorKind, RemoteTab};
use ffi_support::{implement_into_ffi_by_protobuf, ErrorCode, ExternError};
use std::convert::TryInto;
use sync15::ErrorKind as Sync15ErrorKind;

pub mod error_codes {
    /// An unexpected error occurred which likely cannot be meaningfully handled
    /// by the application.
    pub const UNEXPECTED: i32 = -2;

    // Note: -1 and 0 (panic and success) codes are reserved by the ffi-support library

    /// Indicates the FxA credentials are invalid, and should be refreshed.
    pub const AUTH_INVALID: i32 = 1;

    /// A request to the sync server failed.
    pub const NETWORK: i32 = 2;
}

fn get_code(err: &Error) -> ErrorCode {
    match err.kind() {
        ErrorKind::SyncAdapterError(e) => {
            log::error!("Sync error {:?}", e);
            match e.kind() {
                Sync15ErrorKind::TokenserverHttpError(401) | Sync15ErrorKind::BadKeyLength(..) => {
                    ErrorCode::new(error_codes::AUTH_INVALID)
                }
                Sync15ErrorKind::RequestError(_) => ErrorCode::new(error_codes::NETWORK),
                _ => ErrorCode::new(error_codes::UNEXPECTED),
            }
        }

        err => {
            log::error!("Unexpected error: {:?}", err);
            ErrorCode::new(error_codes::UNEXPECTED)
        }
    }
}

impl From<Vec<ClientRemoteTabs>> for msg_types::ClientsTabs {
    fn from(clients: Vec<ClientRemoteTabs>) -> Self {
        Self {
            clients_tabs: clients.into_iter().map(Into::into).collect(),
        }
    }
}

impl From<ClientRemoteTabs> for msg_types::ClientTabs {
    fn from(client: ClientRemoteTabs) -> Self {
        Self {
            client_id: client.client_id,
            remote_tabs: client.remote_tabs.into_iter().map(Into::into).collect(),
        }
    }
}

impl From<RemoteTab> for msg_types::RemoteTab {
    fn from(tab: RemoteTab) -> Self {
        Self {
            title: tab.title,
            url_history: tab.url_history,
            icon: tab.icon,
            last_used: tab.last_used.try_into().unwrap_or(0),
        }
    }
}

impl From<msg_types::RemoteTab> for RemoteTab {
    fn from(msg: msg_types::RemoteTab) -> Self {
        Self {
            title: msg.title,
            url_history: msg.url_history,
            icon: msg.icon,
            last_used: msg.last_used.try_into().unwrap_or(0),
        }
    }
}

impl From<msg_types::RemoteTabs> for Vec<RemoteTab> {
    fn from(msg: msg_types::RemoteTabs) -> Self {
        msg.remote_tabs.into_iter().map(Into::into).collect()
    }
}

impl From<Error> for ExternError {
    fn from(e: Error) -> ExternError {
        ExternError::new_error(get_code(&e), e.to_string())
    }
}

implement_into_ffi_by_protobuf!(msg_types::ClientsTabs);
