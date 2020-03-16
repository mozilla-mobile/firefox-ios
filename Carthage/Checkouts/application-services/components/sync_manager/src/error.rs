/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
use failure::Fail;
use interrupt::Interrupted;
use logins;
use places;
use sync15;

#[derive(Debug, Fail)]
pub enum ErrorKind {
    #[fail(display = "Unknown engine: {}", _0)]
    UnknownEngine(String),
    #[fail(display = "Manager was compiled without support for {:?}", _0)]
    UnsupportedFeature(String),
    #[fail(display = "Database connection for '{}' is not open", _0)]
    ConnectionClosed(String),
    #[fail(display = "Handle is invalid: {}", _0)]
    InvalidHandle(#[fail(cause)] ffi_support::HandleError),
    #[fail(display = "Protobuf decode error: {}", _0)]
    ProtobufDecodeError(#[fail(cause)] prost::DecodeError),
    // Used for things like 'failed to decode the provided sync key because it's
    // completely the wrong format', etc.
    #[fail(display = "Sync error: {}", _0)]
    Sync15Error(#[fail(cause)] sync15::Error),
    #[fail(display = "URL parse error: {}", _0)]
    UrlParseError(#[fail(cause)] url::ParseError),
    #[fail(display = "Operation interrupted")]
    InterruptedError(#[fail(cause)] Interrupted),
    #[fail(display = "Error parsing JSON data: {}", _0)]
    JsonError(#[fail(cause)] serde_json::Error),
    #[fail(display = "Logins error: {}", _0)]
    LoginsError(#[fail(cause)] logins::Error),
    #[fail(display = "Places error: {}", _0)]
    PlacesError(#[fail(cause)] places::Error),
}

error_support::define_error! {
    ErrorKind {
        (InvalidHandle, ffi_support::HandleError),
        (ProtobufDecodeError, prost::DecodeError),
        (Sync15Error, sync15::Error),
        (UrlParseError, url::ParseError),
        (InterruptedError, Interrupted),
        (JsonError, serde_json::Error),
        (LoginsError, logins::Error),
        (PlacesError, places::Error),
    }
}
