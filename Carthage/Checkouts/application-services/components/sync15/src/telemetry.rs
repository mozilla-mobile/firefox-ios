/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

//! Note: this mostly just reexports the things from sync15_traits::telemetry.

use crate::error::{Error, ErrorKind, ErrorResponse};

pub use sync15_traits::telemetry::*;

impl<'a> From<&'a Error> for SyncFailure {
    fn from(e: &Error) -> SyncFailure {
        match e.kind() {
            ErrorKind::TokenserverHttpError(status) => {
                if *status == 401 {
                    SyncFailure::Auth {
                        from: "tokenserver",
                    }
                } else {
                    SyncFailure::Http { code: *status }
                }
            }
            ErrorKind::BackoffError(_) => SyncFailure::Http { code: 503 },
            ErrorKind::StorageHttpError(ref e) => match e {
                ErrorResponse::NotFound { .. } => SyncFailure::Http { code: 404 },
                ErrorResponse::Unauthorized { .. } => SyncFailure::Auth { from: "storage" },
                ErrorResponse::PreconditionFailed { .. } => SyncFailure::Http { code: 412 },
                ErrorResponse::ServerError { status, .. } => SyncFailure::Http { code: *status },
                ErrorResponse::RequestFailed { status, .. } => SyncFailure::Http { code: *status },
            },
            ErrorKind::CryptoError(ref e) => SyncFailure::Unexpected {
                error: e.to_string(),
            },
            ErrorKind::RequestError(ref e) => SyncFailure::Unexpected {
                error: e.to_string(),
            },
            ErrorKind::UnexpectedStatus(ref e) => SyncFailure::Http { code: e.status },
            ErrorKind::Interrupted(ref e) => SyncFailure::Unexpected {
                error: e.to_string(),
            },
            e => SyncFailure::Other {
                error: e.to_string(),
            },
        }
    }
}
