/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use failure::Fail;

impl From<Error> for ffi_support::ExternError {
    fn from(e: Error) -> ffi_support::ExternError {
        ffi_support::ExternError::new_error(e.kind().error_code(), format!("{:?}", e))
    }
}

error_support::define_error! {
    ErrorKind {
        (StorageSqlError, rusqlite::Error),
        (UrlParseError, url::ParseError),
    }
}

#[derive(Debug, Fail)]
pub enum ErrorKind {
    /// An unspecified general error has occured
    #[fail(display = "General Error: {:?}", _0)]
    GeneralError(String),

    #[fail(display = "Crypto error: {}", _0)]
    CryptoError(String),

    /// A Client communication error
    #[fail(display = "Communication Error: {:?}", _0)]
    CommunicationError(String),

    /// An error returned from the registration Server
    #[fail(display = "Communication Server Error: {:?}", _0)]
    CommunicationServerError(String),

    /// Channel is already registered, generate new channelID
    #[fail(display = "Channel already registered.")]
    AlreadyRegisteredError,

    /// An error with Storage
    #[fail(display = "Storage Error: {:?}", _0)]
    StorageError(String),

    #[fail(display = "No record for uaid:chid {:?}:{:?}", _0, _1)]
    RecordNotFoundError(String, String),

    /// A failure to encode data to/from storage.
    #[fail(display = "Error executing SQL: {}", _0)]
    StorageSqlError(#[fail(cause)] rusqlite::Error),

    #[fail(display = "Missing Registration Token")]
    MissingRegistrationTokenError,

    #[fail(display = "Transcoding Error: {}", _0)]
    TranscodingError(String),

    /// A failure to parse a URL.
    #[fail(display = "URL parse error: {:?}", _0)]
    UrlParseError(#[fail(cause)] url::ParseError),
}

// Note, be sure to duplicate errors in the Kotlin side
// see RustError.kt
impl ErrorKind {
    pub fn error_code(&self) -> ffi_support::ErrorCode {
        let code = match self {
            ErrorKind::GeneralError(_) => 22,
            ErrorKind::CryptoError(_) => 24,
            ErrorKind::CommunicationError(_) => 25,
            ErrorKind::CommunicationServerError(_) => 26,
            ErrorKind::AlreadyRegisteredError => 27,
            ErrorKind::StorageError(_) => 28,
            ErrorKind::StorageSqlError(_) => 29,
            ErrorKind::MissingRegistrationTokenError => 30,
            ErrorKind::TranscodingError(_) => 31,
            ErrorKind::RecordNotFoundError(_, _) => 32,
            ErrorKind::UrlParseError(_) => 33,
        };
        ffi_support::ErrorCode::new(code)
    }
}
