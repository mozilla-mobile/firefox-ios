/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

//! This module provides wrappers around JsonValue that allow for better
//! documentation and type safety for the format a method (usually in `db.rs`)
//! is expected to take/return.
//!
//! XXX The names "Local" vs "Native" here (and around) is confusing, but beats
//! everything passing around `serde_json::Value`s directly, and it matches the
//! terms used in the RFC. I'm open to name suggestions, though.

use crate::{error::*, JsonObject, JsonValue};
use std::marker::PhantomData;

mod private {
    /// Sealed trait to prevent code from outside from implementing RecordFormat
    /// for anything other than the implementations here.
    pub trait Sealed {}
    impl Sealed for super::LocalFormat {}
    impl Sealed for super::NativeFormat {}
}

/// Used to distinguish different categories of records.
///
/// Most of the bounds are just so that we don't have to manually implement
/// traits we could otherwise derive -- in practice we just use this in a
/// PhantomData.
pub trait RecordFormat:
    private::Sealed + Copy + std::fmt::Debug + PartialEq + 'static + Sync + Send
{
}

/// Record format for records in the current local schema. This is the format
/// which we insert into the database, and it should always be newer or
/// equal to the native format.
#[derive(Debug, Clone, PartialEq, Copy, Eq, Ord, Hash, PartialOrd)]
pub struct LocalFormat;

/// A record in the native format understood by the local application using
/// remerge. Data that comes from the FFI, and that is returned over the FFI
/// should be in this format.
#[derive(Debug, Clone, PartialEq, Copy, Eq, Ord, Hash, PartialOrd)]
pub struct NativeFormat;

// Note: For sync we'll likely want a RemoteFormat/RemoteRecord too.

impl RecordFormat for LocalFormat {}
impl RecordFormat for NativeFormat {}

/// A [`Record`] in [`LocalFormat`].
pub type LocalRecord = Record<LocalFormat>;
/// A [`Record`] in [`NativeFormat`].
pub type NativeRecord = Record<NativeFormat>;

/// A wrapper around `serde_json::Value` which indicates what format the record
/// is in. Note that converting between formats cannot be done without schema
/// information, so this is a paper-thin wrapper.
///
/// # Which record format to use
///
/// - Data coming from the FFI, or being returned to the FFI is always in
///   [`NativeFormat`], so use NativeRecord.
///
/// - Data going into the database, or that came out of the database is in
///   [`LocalFormat`], so use LocalRecord.
///
/// - Data from remote servers will likely be a future `RemoteFormat`, and you'd
///   use [`RemoteRecord`].
///
/// Converting between a record in one format to another requires schema
/// information. This can generally done by methods on `SchemaBundle`.

#[repr(transparent)]
#[derive(Debug, Clone, PartialEq)]
pub struct Record<F: RecordFormat>(pub(crate) JsonObject, PhantomData<F>);

impl<F: RecordFormat> Record<F> {
    /// Create a new record with the format `F` directly.
    ///
    /// The name of this function contains `unchecked` as it's up to the caller
    /// to ensure that the `record_json` is actually in the requested format.
    /// See the [`Record`] docs for how to make this determination.
    #[inline]
    pub fn new_unchecked(record_json: JsonObject) -> Self {
        Self(record_json, PhantomData)
    }

    /// If `record` is a JSON Object, returns `Ok(Self::new_unchecked(record))`,
    /// otherwise, returns `Err(InvalidRecord::NotJsonObject)`
    ///
    /// The name of this function contains `unchecked` as it's up to the caller
    /// to ensure that the `record_json` is actually in the requested format.
    /// See the [`Record`] docs for how to make this determination.
    pub fn from_value_unchecked(record_json: JsonValue) -> Result<Self, InvalidRecord> {
        if let JsonValue::Object(m) = record_json {
            Ok(Self::new_unchecked(m))
        } else {
            Err(crate::error::InvalidRecord::NotJsonObject)
        }
    }

    #[inline]
    pub fn as_obj(&self) -> &JsonObject {
        &self.0
    }

    #[inline]
    pub fn into_obj(self) -> JsonObject {
        self.0
    }

    #[inline]
    pub fn into_val(self) -> JsonValue {
        self.into_obj().into()
    }
}

impl NativeRecord {
    /// Parse a record from a str given to us over the FFI, returning an error
    /// if it's obviously bad (not a json object).
    pub fn from_native_str(s: &str) -> Result<Self> {
        let record: JsonValue = serde_json::from_str(s)?;
        if let JsonValue::Object(m) = record {
            Ok(Self(m, PhantomData))
        } else {
            Err(crate::error::InvalidRecord::NotJsonObject.into())
        }
    }
}

impl<F: RecordFormat> std::ops::Deref for Record<F> {
    type Target = JsonObject;
    #[inline]
    fn deref(&self) -> &Self::Target {
        self.as_obj()
    }
}

impl<F: RecordFormat> AsRef<JsonObject> for Record<F> {
    #[inline]
    fn as_ref(&self) -> &JsonObject {
        self.as_obj()
    }
}

impl<F: RecordFormat> From<Record<F>> for JsonValue {
    #[inline]
    fn from(r: Record<F>) -> JsonValue {
        r.into_val()
    }
}
impl<F: RecordFormat> From<Record<F>> for JsonObject {
    #[inline]
    fn from(r: Record<F>) -> JsonObject {
        r.into_obj()
    }
}
impl<'a, F: RecordFormat> From<&'a Record<F>> for &'a JsonObject {
    #[inline]
    fn from(r: &'a Record<F>) -> &'a JsonObject {
        &r.0
    }
}

impl From<JsonObject> for NativeRecord {
    #[inline]
    fn from(o: JsonObject) -> NativeRecord {
        NativeRecord::new_unchecked(o)
    }
}

impl std::convert::TryFrom<JsonValue> for NativeRecord {
    type Error = Error;
    #[inline]
    fn try_from(v: JsonValue) -> Result<NativeRecord, Self::Error> {
        Ok(Self::from_value_unchecked(v)?)
    }
}

impl<F: RecordFormat> std::fmt::Display for Record<F> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let mut writer = crate::util::FormatWriter(f);
        serde_json::to_writer(&mut writer, &self.0).map_err(|_| std::fmt::Error)
    }
}

// Separated because we're going to glob import rusqlite::types::*, since we
// need nearly all of them.
mod sql_impls {
    use super::LocalRecord;
    use rusqlite::{types::*, Result};

    impl ToSql for LocalRecord {
        fn to_sql(&self) -> Result<ToSqlOutput<'_>> {
            Ok(ToSqlOutput::from(self.to_string()))
        }
    }

    impl FromSql for LocalRecord {
        fn column_result(value: ValueRef<'_>) -> FromSqlResult<Self> {
            match value {
                ValueRef::Text(s) => serde_json::from_slice(s),
                ValueRef::Blob(b) => serde_json::from_slice(b),
                _ => return Err(FromSqlError::InvalidType),
            }
            .map(LocalRecord::new_unchecked)
            .map_err(|err| FromSqlError::Other(err.into()))
        }
    }
}
