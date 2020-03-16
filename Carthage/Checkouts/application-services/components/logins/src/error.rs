/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use failure::Fail;

// TODO: this is (IMO) useful and was dropped from `failure`, consider moving it
// into `error_support`.
macro_rules! throw {
    ($e:expr) => {
        return Err(Into::into($e));
    };
}

#[derive(Debug, Fail)]
pub enum ErrorKind {
    #[fail(display = "Invalid login: {}", _0)]
    InvalidLogin(InvalidLogin),

    #[fail(
        display = "The `sync_status` column in DB has an illegal value: {}",
        _0
    )]
    BadSyncStatus(u8),

    #[fail(display = "A duplicate GUID is present: {:?}", _0)]
    DuplicateGuid(String),

    #[fail(
        display = "No record with guid exists (when one was required): {:?}",
        _0
    )]
    NoSuchRecord(String),

    // Fennec import only works on empty logins tables.
    #[fail(display = "The logins tables are not empty")]
    NonEmptyTable,

    #[fail(display = "The provided salt is invalid")]
    InvalidSalt,

    #[fail(display = "Error synchronizing: {}", _0)]
    SyncAdapterError(#[fail(cause)] sync15::Error),

    #[fail(display = "Error parsing JSON data: {}", _0)]
    JsonError(#[fail(cause)] serde_json::Error),

    #[fail(display = "Error executing SQL: {}", _0)]
    SqlError(#[fail(cause)] rusqlite::Error),

    #[fail(display = "Error parsing URL: {}", _0)]
    UrlParseError(#[fail(cause)] url::ParseError),

    #[fail(display = "{}", _0)]
    Interrupted(#[fail(cause)] interrupt::Interrupted),

    #[fail(display = "Protobuf decode error: {}", _0)]
    ProtobufDecodeError(#[fail(cause)] prost::DecodeError),
}

error_support::define_error! {
    ErrorKind {
        (SyncAdapterError, sync15::Error),
        (JsonError, serde_json::Error),
        (UrlParseError, url::ParseError),
        (SqlError, rusqlite::Error),
        (InvalidLogin, InvalidLogin),
        (Interrupted, interrupt::Interrupted),
        (ProtobufDecodeError, prost::DecodeError),
    }
}

#[derive(Debug, Fail)]
pub enum InvalidLogin {
    // EmptyOrigin error occurs when the login's hostname field is empty.
    #[fail(display = "Origin is empty")]
    EmptyOrigin,
    #[fail(display = "Password is empty")]
    EmptyPassword,
    #[fail(display = "Login already exists")]
    DuplicateLogin,
    #[fail(display = "Both `formSubmitUrl` and `httpRealm` are present")]
    BothTargets,
    #[fail(display = "Neither `formSubmitUrl` or `httpRealm` are present")]
    NoTarget,
    #[fail(display = "Login has illegal field: {}", _0)]
    IllegalFieldValue { field_info: String },
}

impl Error {
    // Get a short textual label identifying the type of error that occurred,
    // but without including any potentially-sensitive information.
    pub fn label(&self) -> &'static str {
        match self.kind() {
            ErrorKind::BadSyncStatus(_) => "BadSyncStatus",
            ErrorKind::DuplicateGuid(_) => "DuplicateGuid",
            ErrorKind::NoSuchRecord(_) => "NoSuchRecord",
            ErrorKind::NonEmptyTable => "NonEmptyTable",
            ErrorKind::InvalidSalt => "InvalidSalt",
            ErrorKind::SyncAdapterError(_) => "SyncAdapterError",
            ErrorKind::JsonError(_) => "JsonError",
            ErrorKind::UrlParseError(_) => "UrlParseError",
            ErrorKind::SqlError(_) => "SqlError",
            ErrorKind::Interrupted(_) => "Interrupted",
            ErrorKind::InvalidLogin(desc) => match desc {
                InvalidLogin::EmptyOrigin => "InvalidLogin::EmptyOrigin",
                InvalidLogin::EmptyPassword => "InvalidLogin::EmptyPassword",
                InvalidLogin::DuplicateLogin => "InvalidLogin::DuplicateLogin",
                InvalidLogin::BothTargets => "InvalidLogin::BothTargets",
                InvalidLogin::NoTarget => "InvalidLogin::NoTarget",
                InvalidLogin::IllegalFieldValue { .. } => "InvalidLogin::IllegalFieldValue",
            },
            ErrorKind::ProtobufDecodeError(_) => "BufDecodeError",
        }
    }
}
