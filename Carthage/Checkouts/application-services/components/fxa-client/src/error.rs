/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use failure::Fail;
use rc_crypto::hawk;
use std::string;

#[derive(Debug, Fail)]
pub enum ErrorKind {
    #[fail(display = "Unknown OAuth State")]
    UnknownOAuthState,

    #[fail(display = "The client requested keys alongside the token but they were not included")]
    TokenWithoutKeys,

    #[fail(display = "Login state needs to be Married for the current operation")]
    NotMarried,

    #[fail(display = "Multiple OAuth scopes requested")]
    MultipleScopesRequested,

    #[fail(display = "No cached token for scope {}", _0)]
    NoCachedToken(String),

    #[fail(display = "No cached scoped keys for scope {}", _0)]
    NoScopedKey(String),

    #[fail(display = "No stored refresh token")]
    NoRefreshToken,

    #[fail(display = "No stored session token")]
    NoSessionToken,

    #[fail(display = "No stored migration data")]
    NoMigrationData,

    #[fail(display = "No stored current device id")]
    NoCurrentDeviceId,

    #[fail(display = "Could not find a refresh token in the server response")]
    RefreshTokenNotPresent,

    #[fail(display = "Action requires a prior device registration")]
    DeviceUnregistered,

    #[fail(display = "Device target is unknown (Device ID: {})", _0)]
    UnknownTargetDevice(String),

    #[fail(display = "Unrecoverable server error {}", _0)]
    UnrecoverableServerError(&'static str),

    #[fail(display = "Invalid OAuth scope value {}", _0)]
    InvalidOAuthScopeValue(String),

    #[fail(display = "Illegal state: {}", _0)]
    IllegalState(&'static str),

    #[fail(display = "Unknown command: {}", _0)]
    UnknownCommand(String),

    #[fail(display = "Empty names")]
    EmptyOAuthScopeNames,

    #[fail(display = "Key {} had wrong length, got {}, expected {}", _0, _1, _2)]
    BadKeyLength(&'static str, usize, usize),

    #[fail(
        display = "Cannot xor arrays with different lengths: {} and {}",
        _0, _1
    )]
    XorLengthMismatch(usize, usize),

    #[fail(display = "Audience URL without a host")]
    AudienceURLWithoutHost,

    #[fail(display = "Origin mismatch")]
    OriginMismatch,

    #[fail(display = "JWT signature validation failed")]
    JWTSignatureValidationFailed,

    #[fail(display = "ECDH key generation failed")]
    KeyGenerationFailed,

    #[fail(display = "Public key computation failed")]
    PublicKeyComputationFailed,

    #[fail(display = "Remote key and local key mismatch")]
    MismatchedKeys,

    #[fail(display = "Key import failed")]
    KeyImportFailed,

    #[fail(display = "AEAD open failure")]
    AEADOpenFailure,

    #[fail(display = "Random number generation failure")]
    RngFailure,

    #[fail(display = "HMAC mismatch")]
    HmacMismatch,

    #[fail(display = "Unsupported command: {}", _0)]
    UnsupportedCommand(&'static str),

    #[fail(
        display = "Remote server error: '{}' '{}' '{}' '{}' '{}'",
        code, errno, error, message, info
    )]
    RemoteError {
        code: u64,
        errno: u64,
        error: String,
        message: String,
        info: String,
    },

    // Basically reimplement error_chain's foreign_links. (Ugh, this sucks).
    #[fail(display = "Crypto/NSS error: {}", _0)]
    CryptoError(#[fail(cause)] rc_crypto::Error),

    #[fail(display = "http-ece encryption error: {}", _0)]
    EceError(#[fail(cause)] rc_crypto::ece::Error),

    #[fail(display = "Hex decode error: {}", _0)]
    HexDecodeError(#[fail(cause)] hex::FromHexError),

    #[fail(display = "Base64 decode error: {}", _0)]
    Base64Decode(#[fail(cause)] base64::DecodeError),

    #[fail(display = "JSON error: {}", _0)]
    JsonError(#[fail(cause)] serde_json::Error),

    #[fail(display = "UTF8 decode error: {}", _0)]
    UTF8DecodeError(#[fail(cause)] string::FromUtf8Error),

    #[fail(display = "Network error: {}", _0)]
    RequestError(#[fail(cause)] viaduct::Error),

    #[fail(display = "Malformed URL error: {}", _0)]
    MalformedUrl(#[fail(cause)] url::ParseError),

    #[fail(display = "Unexpected HTTP status: {}", _0)]
    UnexpectedStatus(#[fail(cause)] viaduct::UnexpectedStatus),

    #[fail(display = "Sync15 error: {}", _0)]
    SyncError(#[fail(cause)] sync15::Error),

    #[fail(display = "HAWK error: {}", _0)]
    HawkError(#[fail(cause)] hawk::Error),

    #[fail(display = "Protobuf decode error: {}", _0)]
    ProtobufDecodeError(#[fail(cause)] prost::DecodeError),
}

error_support::define_error! {
    ErrorKind {
        (CryptoError, rc_crypto::Error),
        (EceError, rc_crypto::ece::Error),
        (HexDecodeError, hex::FromHexError),
        (Base64Decode, base64::DecodeError),
        (JsonError, serde_json::Error),
        (UTF8DecodeError, std::string::FromUtf8Error),
        (RequestError, viaduct::Error),
        (UnexpectedStatus, viaduct::UnexpectedStatus),
        (MalformedUrl, url::ParseError),
        (SyncError, sync15::Error),
        (ProtobufDecodeError, prost::DecodeError),
    }
}

error_support::define_error_conversions! {
    ErrorKind {
        (HawkError, hawk::Error),
    }
}
