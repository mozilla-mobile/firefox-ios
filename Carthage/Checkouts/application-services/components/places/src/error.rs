/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::storage::bookmarks::BookmarkRootGuid;
use crate::types::BookmarkType;
use dogear;
use failure::Fail;
use interrupt::Interrupted;
use serde_json::Value as JsonValue;

// Note: If you add new error types that should be returned to consumers on the other side of the
// FFI, update `get_code` in `ffi.rs`
#[derive(Debug, Fail)]
pub enum ErrorKind {
    #[fail(display = "Invalid place info: {}", _0)]
    InvalidPlaceInfo(InvalidPlaceInfo),

    #[fail(display = "The store is corrupt: {}", _0)]
    Corruption(Corruption),

    #[fail(display = "Error synchronizing: {}", _0)]
    SyncAdapterError(#[fail(cause)] sync15::Error),

    #[fail(display = "Error merging: {}", _0)]
    MergeError(#[fail(cause)] dogear::Error),

    #[fail(display = "Error parsing JSON data: {}", _0)]
    JsonError(#[fail(cause)] serde_json::Error),

    #[fail(display = "Error executing SQL: {}", _0)]
    SqlError(#[fail(cause)] rusqlite::Error),

    #[fail(display = "Error parsing URL: {}", _0)]
    UrlParseError(#[fail(cause)] url::ParseError),

    #[fail(display = "A connection of this type is already open")]
    ConnectionAlreadyOpen,

    #[fail(display = "An invalid connection type was specified")]
    InvalidConnectionType,

    #[fail(display = "IO error: {}", _0)]
    IoError(#[fail(cause)] std::io::Error),

    #[fail(display = "Operation interrupted")]
    InterruptedError(#[fail(cause)] Interrupted),

    #[fail(display = "Tried to close connection on wrong PlacesApi instance")]
    WrongApiForClose,

    #[fail(display = "Incoming bookmark missing type")]
    MissingBookmarkKind,

    #[fail(display = "Incoming bookmark has unsupported type {}", _0)]
    UnsupportedIncomingBookmarkType(JsonValue),

    #[fail(display = "Synced bookmark has unsupported kind {}", _0)]
    UnsupportedSyncedBookmarkKind(u8),

    #[fail(display = "Synced bookmark has unsupported validity {}", _0)]
    UnsupportedSyncedBookmarkValidity(u8),

    // This will happen if you provide something absurd like
    // "/" or "" as your database path. For more subtley broken paths,
    // we'll likely return an IoError.
    #[fail(display = "Illegal database path: {:?}", _0)]
    IllegalDatabasePath(std::path::PathBuf),

    #[fail(display = "Protobuf decode error: {}", _0)]
    ProtobufDecodeError(#[fail(cause)] prost::DecodeError),

    #[fail(display = "UTF8 Error: {}", _0)]
    Utf8Error(#[fail(cause)] std::str::Utf8Error),

    #[fail(display = "Database cannot be upgraded")]
    DatabaseUpgradeError,

    #[fail(display = "Database version {} is not supported", _0)]
    UnsupportedDatabaseVersion(i64),
}

error_support::define_error! {
    ErrorKind {
        (SyncAdapterError, sync15::Error),
        (JsonError, serde_json::Error),
        (UrlParseError, url::ParseError),
        (SqlError, rusqlite::Error),
        (InvalidPlaceInfo, InvalidPlaceInfo),
        (Corruption, Corruption),
        (IoError, std::io::Error),
        (MergeError, dogear::Error),
        (ProtobufDecodeError, prost::DecodeError),
        (InterruptedError, Interrupted),
        (Utf8Error, std::str::Utf8Error),
    }
}

#[derive(Debug, Fail)]
pub enum InvalidPlaceInfo {
    #[fail(display = "No url specified")]
    NoUrl,
    #[fail(display = "Invalid guid")]
    InvalidGuid,
    #[fail(display = "Invalid parent: {}", _0)]
    InvalidParent(String),
    #[fail(display = "Invalid child guid")]
    InvalidChildGuid,

    // NoSuchGuid is used for guids, which aren't considered private information,
    // so it's fine if this error, including the guid, is in the logs.
    #[fail(display = "No such item: {}", _0)]
    NoSuchGuid(String),

    // NoSuchUrl is used for URLs, which are private information, so the URL
    // itself is not included in the error.
    #[fail(display = "No such url")]
    NoSuchUrl,

    #[fail(
        display = "Can't update a bookmark of type {} with one of type {}",
        _0, _1
    )]
    MismatchedBookmarkType(u8, u8),

    // Only returned when attempting to insert a bookmark --
    // for history we just ignore it.
    #[fail(display = "URL too long")]
    UrlTooLong,

    // Like Urls, a tag is considered private info, so the value isn't in the error.
    #[fail(display = "The tag value is invalid")]
    InvalidTag,
    #[fail(
        display = "Cannot change the '{}' property of a bookmark of type {:?}",
        _0, _1
    )]
    IllegalChange(&'static str, BookmarkType),

    #[fail(display = "Cannot update the bookmark root {:?}", _0)]
    CannotUpdateRoot(BookmarkRootGuid),
}

// Error types used when we can't continue due to corruption.
// Note that this is currently only for "logical" corruption. Should we
// consider mapping sqlite error codes which mean a lower-level of corruption
// into an enum value here?
#[derive(Debug, Fail)]
pub enum Corruption {
    #[fail(
        display = "Bookmark '{}' has a parent of '{}' which does not exist",
        _0, _1
    )]
    NoParent(String, String),

    #[fail(display = "The local roots are invalid")]
    InvalidLocalRoots,

    #[fail(display = "The synced roots are invalid")]
    InvalidSyncedRoots,

    #[fail(
        display = "Bookmark '{}' has no parent but is not the bookmarks root",
        _0
    )]
    NonRootWithoutParent(String),
}
