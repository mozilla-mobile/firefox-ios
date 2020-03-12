/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::error::{Error, ErrorKind};
use ffi_support::{ErrorCode, ExternError};

pub mod error_codes {
    // Note: 0 (success) and -1 (panic) are reserved by ffi_support
    pub const UNEXPECTED: i32 = 1;

    /// We were asked to sync an engine, but we either don't know what it is,
    /// or were compiled without support for it.
    pub const UNSUPPORTED_ENGINE: i32 = 2;

    /// We were asked to sync an engine which is not open (i.e. Weak::upgrade
    /// returns None).
    pub const ENGINE_NOT_OPEN: i32 = 3;
}

fn get_code(err: &Error) -> ErrorCode {
    match err.kind() {
        ErrorKind::UnknownEngine(e) => {
            log::error!("Unknown engine: {}", e);
            ErrorCode::new(error_codes::UNSUPPORTED_ENGINE)
        }
        ErrorKind::UnsupportedFeature(f) => {
            log::error!("Unsupported feature: {}", f);
            ErrorCode::new(error_codes::UNSUPPORTED_ENGINE)
        }
        ErrorKind::ConnectionClosed(e) => {
            log::error!("Connection closed: {}", e);
            ErrorCode::new(error_codes::ENGINE_NOT_OPEN)
        }
        err => {
            log::error!("Unexpected error: {}", err);
            ErrorCode::new(error_codes::UNEXPECTED)
        }
    }
}

impl From<Error> for ExternError {
    fn from(e: Error) -> ExternError {
        ExternError::new_error(get_code(&e), e.to_string())
    }
}

ffi_support::implement_into_ffi_by_protobuf!(crate::msg_types::SyncResult);
ffi_support::implement_into_ffi_by_protobuf!(crate::msg_types::SyncParams);
