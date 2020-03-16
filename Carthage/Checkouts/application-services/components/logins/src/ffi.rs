/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// This module implement the traits that make the FFI code easier to manage.

use crate::msg_types;
use crate::{Error, ErrorKind, InvalidLogin};
use ffi_support::{implement_into_ffi_by_protobuf, ErrorCode, ExternError};
use sync15::ErrorKind as Sync15ErrorKind;

pub mod error_codes {
    /// An unexpected error occurred which likely cannot be meaningfully handled
    /// by the application.
    pub const UNEXPECTED: i32 = -2;

    // Note: -1 and 0 (panic and success) codes are reserved by the ffi-support library

    /// Indicates the FxA credentials are invalid, and should be refreshed.
    pub const AUTH_INVALID: i32 = 1;

    /// Returned from an `update()` call where the record ID did not exist.
    pub const NO_SUCH_RECORD: i32 = 2;

    /// Returned from an `add()` call that was provided an ID, where the ID
    /// already existed.
    pub const DUPLICATE_GUID: i32 = 3;

    /// Either the file is not a database, or it is not encrypted with the
    /// provided encryption key.
    pub const INVALID_KEY: i32 = 4;

    /// A request to the sync server failed.
    pub const NETWORK: i32 = 5;

    /// An operation has been interrupted.
    pub const INTERRUPTED: i32 = 6;

    /// An invalid salt was provided.
    pub const INVALID_SALT: i32 = 7;

    // Skip a bunch of spaces to make it clear these are part of a group,
    // even as more and more errors get added. We're only exposing the
    // InvalidLogin items that can actually be triggered, the others
    // (if they happen accidentally) will come through as unexpected.

    pub const INVALID_LOGIN_EMPTY_ORIGIN: i32 = 64;
    pub const INVALID_LOGIN_EMPTY_PASSWORD: i32 = 64 + 1;
    pub const INVALID_LOGIN_DUPLICATE_LOGIN: i32 = 64 + 2;
    pub const INVALID_LOGIN_BOTH_TARGETS: i32 = 64 + 3;
    pub const INVALID_LOGIN_NO_TARGET: i32 = 64 + 4;
    pub const INVALID_LOGIN_ILLEGAL_FIELD_VALUE: i32 = 64 + 5;
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
        ErrorKind::DuplicateGuid(id) => {
            log::error!("Guid already exists: {}", id);
            ErrorCode::new(error_codes::DUPLICATE_GUID)
        }
        ErrorKind::NoSuchRecord(id) => {
            log::error!("No record exists with id {}", id);
            ErrorCode::new(error_codes::NO_SUCH_RECORD)
        }
        ErrorKind::InvalidLogin(desc) => {
            log::error!("Invalid login: {}", desc);
            ErrorCode::new(match desc {
                InvalidLogin::EmptyOrigin => error_codes::INVALID_LOGIN_EMPTY_ORIGIN,
                InvalidLogin::EmptyPassword => error_codes::INVALID_LOGIN_EMPTY_PASSWORD,
                InvalidLogin::DuplicateLogin => error_codes::INVALID_LOGIN_DUPLICATE_LOGIN,
                InvalidLogin::BothTargets => error_codes::INVALID_LOGIN_BOTH_TARGETS,
                InvalidLogin::NoTarget => error_codes::INVALID_LOGIN_NO_TARGET,
                InvalidLogin::IllegalFieldValue { .. } => {
                    error_codes::INVALID_LOGIN_ILLEGAL_FIELD_VALUE
                }
            })
        }
        // We can't destructure `err` without bringing in the libsqlite3_sys crate
        // (and I'd really rather not) so we can't put this in the match.
        ErrorKind::SqlError(rusqlite::Error::SqliteFailure(err, _))
            if err.code == rusqlite::ErrorCode::NotADatabase =>
        {
            log::error!("Not a database / invalid key error");
            ErrorCode::new(error_codes::INVALID_KEY)
        }

        ErrorKind::SqlError(rusqlite::Error::SqliteFailure(err, _))
            if err.code == rusqlite::ErrorCode::OperationInterrupted =>
        {
            log::warn!("Operation interrupted (SQL)");
            ErrorCode::new(error_codes::INTERRUPTED)
        }

        ErrorKind::Interrupted(_) => {
            log::warn!("Operation interrupted (Outside SQL)");
            ErrorCode::new(error_codes::INTERRUPTED)
        }

        ErrorKind::InvalidSalt => {
            log::error!("Invalid salt provided");
            ErrorCode::new(error_codes::INVALID_SALT)
        }

        err => {
            log::error!("Unexpected error: {:?}", err);
            ErrorCode::new(error_codes::UNEXPECTED)
        }
    }
}

impl From<Error> for ExternError {
    fn from(e: Error) -> ExternError {
        ExternError::new_error(get_code(&e), e.to_string())
    }
}

implement_into_ffi_by_protobuf!(msg_types::PasswordInfo);
implement_into_ffi_by_protobuf!(msg_types::PasswordInfos);
