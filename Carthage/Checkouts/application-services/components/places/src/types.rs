/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use failure::Fail;
use rusqlite::types::{FromSql, FromSqlError, FromSqlResult, ToSql, ToSqlOutput, ValueRef};
use rusqlite::Result as RusqliteResult;
use serde::ser::{Serialize, Serializer};
use serde_derive::*;
use std::convert::TryFrom;
use std::fmt;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

mod visit_transition_set;
pub use visit_transition_set::VisitTransitionSet;

// Typesafe way to manage timestamps.
// We should probably work out how to share this too?
#[derive(
    Debug, Copy, Clone, Eq, PartialEq, Ord, PartialOrd, Hash, Deserialize, Serialize, Default,
)]
pub struct Timestamp(pub u64);

impl Timestamp {
    pub fn now() -> Self {
        SystemTime::now().into()
    }

    /// Returns None if `other` is later than `self` (Duration may not represent
    /// negative timespans in rust).
    #[inline]
    pub fn duration_since(self, other: Timestamp) -> Option<Duration> {
        // just do this via SystemTime.
        SystemTime::from(self).duration_since(other.into()).ok()
    }

    #[inline]
    pub fn checked_sub(self, d: Duration) -> Option<Timestamp> {
        SystemTime::from(self).checked_sub(d).map(Timestamp::from)
    }

    pub fn as_millis(self) -> u64 {
        self.0
    }
    /// In desktop sync, bookmarks are clamped to Jan 23, 1993 (which is 727747200000)
    /// There's no good reason history records could be older than that, so we do
    /// the same here (even though desktop's history currently doesn't)
    /// XXX - there's probably a case to be made for this being, say, 5 years ago -
    /// then all requests earlier than that are collapsed into a single visit at
    /// this timestamp.
    pub const EARLIEST: Timestamp = Timestamp(727_747_200_000);
}

impl From<Timestamp> for u64 {
    #[inline]
    fn from(ts: Timestamp) -> Self {
        ts.0
    }
}

impl From<SystemTime> for Timestamp {
    #[inline]
    fn from(st: SystemTime) -> Self {
        let d = st.duration_since(UNIX_EPOCH).unwrap(); // hrmph - unwrap doesn't seem ideal
        Timestamp((d.as_secs() as u64) * 1000 + (u64::from(d.subsec_nanos()) / 1_000_000))
    }
}

impl From<Timestamp> for SystemTime {
    #[inline]
    fn from(ts: Timestamp) -> Self {
        UNIX_EPOCH + Duration::from_millis(ts.into())
    }
}

impl From<u64> for Timestamp {
    #[inline]
    fn from(ts: u64) -> Self {
        assert!(ts != 0);
        Timestamp(ts)
    }
}

impl fmt::Display for Timestamp {
    #[inline]
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl ToSql for Timestamp {
    fn to_sql(&self) -> RusqliteResult<ToSqlOutput<'_>> {
        Ok(ToSqlOutput::from(self.0 as i64)) // hrm - no u64 in rusqlite
    }
}

impl FromSql for Timestamp {
    fn column_result(value: ValueRef<'_>) -> FromSqlResult<Self> {
        value.as_i64().map(|v| Timestamp(v as u64)) // hrm - no u64
    }
}

#[derive(Fail, Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
#[fail(display = "Invalid visit type")]
pub struct InvalidVisitType;

// NOTE: These discriminator values are the same as those used by Desktop
// Firefox and are what is written to the database. We also duplicate them
// in the android lib as constants on PlacesConnection, and in a couple
// constants in visit_transition_set.rs
#[repr(u8)]
#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub enum VisitTransition {
    // This transition type means the user followed a link.
    Link = 1,

    // This transition type means that the user typed the page's URL in the
    // URL bar or selected it from UI (URL bar autocomplete results, etc)
    Typed = 2,

    // XXX - moar comments.
    Bookmark = 3,
    Embed = 4,
    RedirectPermanent = 5,
    RedirectTemporary = 6,
    Download = 7,
    FramedLink = 8,
    Reload = 9,
}

impl ToSql for VisitTransition {
    fn to_sql(&self) -> RusqliteResult<ToSqlOutput<'_>> {
        Ok(ToSqlOutput::from(*self as u8))
    }
}

impl VisitTransition {
    pub fn from_primitive(p: u8) -> Option<Self> {
        match p {
            1 => Some(VisitTransition::Link),
            2 => Some(VisitTransition::Typed),
            3 => Some(VisitTransition::Bookmark),
            4 => Some(VisitTransition::Embed),
            5 => Some(VisitTransition::RedirectPermanent),
            6 => Some(VisitTransition::RedirectTemporary),
            7 => Some(VisitTransition::Download),
            8 => Some(VisitTransition::FramedLink),
            9 => Some(VisitTransition::Reload),
            _ => None,
        }
    }
}

impl TryFrom<u8> for VisitTransition {
    type Error = InvalidVisitType;
    fn try_from(p: u8) -> Result<Self, Self::Error> {
        VisitTransition::from_primitive(p).ok_or(InvalidVisitType)
    }
}

struct VisitTransitionSerdeVisitor;

impl<'de> serde::de::Visitor<'de> for VisitTransitionSerdeVisitor {
    type Value = VisitTransition;

    fn expecting(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("positive integer representing VisitTransition")
    }

    fn visit_u64<E: serde::de::Error>(self, value: u64) -> Result<VisitTransition, E> {
        use std::u8::MAX as U8_MAX;
        if value > u64::from(U8_MAX) {
            // In practice this is *way* out of the valid range of VisitTransition, but
            // serde requires us to implement this as visit_u64 so...
            return Err(E::custom(format!("value out of u8 range: {}", value)));
        }
        VisitTransition::from_primitive(value as u8)
            .ok_or_else(|| E::custom(format!("unknown VisitTransition value: {}", value)))
    }
}

impl serde::Serialize for VisitTransition {
    fn serialize<S: serde::Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        serializer.serialize_u64(*self as u64)
    }
}

impl<'de> serde::Deserialize<'de> for VisitTransition {
    fn deserialize<D: serde::Deserializer<'de>>(deserializer: D) -> Result<Self, D::Error> {
        deserializer.deserialize_u64(VisitTransitionSerdeVisitor)
    }
}

/// Bookmark types.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Ord, PartialOrd, Hash)]
#[repr(u8)]
pub enum BookmarkType {
    Bookmark = 1, // TYPE_BOOKMARK
    Folder = 2,   // TYPE_FOLDER
    Separator = 3, // TYPE_SEPARATOR;
                  // On desktop, TYPE_DYNAMIC_CONTAINER = 4 but is deprecated - so please
                  // avoid using this value in the future.
}

impl FromSql for BookmarkType {
    fn column_result(value: ValueRef<'_>) -> FromSqlResult<Self> {
        let v = value.as_i64()?;
        if v < 0 || v > i64::from(u8::max_value()) {
            return Err(FromSqlError::OutOfRange(v));
        }
        BookmarkType::from_u8(v as u8).ok_or_else(|| FromSqlError::OutOfRange(v))
    }
}

impl BookmarkType {
    #[inline]
    pub fn from_u8(v: u8) -> Option<Self> {
        match v {
            1 => Some(BookmarkType::Bookmark),
            2 => Some(BookmarkType::Folder),
            3 => Some(BookmarkType::Separator),
            _ => None,
        }
    }

    pub fn from_u8_with_valid_url<F: Fn() -> bool>(v: u8, has_valid_url: F) -> Self {
        match BookmarkType::from_u8(v) {
            Some(BookmarkType::Bookmark) | None => {
                if has_valid_url() {
                    // Even if the node says it is a bookmark it still must have a
                    // valid url.
                    BookmarkType::Bookmark
                } else {
                    BookmarkType::Folder
                }
            }
            Some(t) => t,
        }
    }
}

impl ToSql for BookmarkType {
    fn to_sql(&self) -> RusqliteResult<ToSqlOutput<'_>> {
        Ok(ToSqlOutput::from(*self as u8))
    }
}

impl Serialize for BookmarkType {
    fn serialize<S>(&self, serializer: S) -> std::result::Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_u8(*self as u8)
    }
}

/// Re SyncStatus - note that:
/// * logins has synced=0, changed=1, new=2
/// * desktop bookmarks has unknown=0, new=1, normal=2
/// This is "places", so eventually bookmarks will have a status - should history
/// and bookmarks share this enum?
/// Note that history specifically needs neither (a) login's "changed" (the
/// changeCounter works there), nor (b) bookmark's "unknown" (as that's only
/// used after a restore).
/// History only needs a distinction between "synced" and "new" so it doesn't
/// accumulate never-to-be-synced tombstones - so we basically copy bookmarks
/// and treat unknown as new.
/// Which means we get the "bonus side-effect" ;) of ::Unknown replacing Option<>!
///
/// Note that some of these values are in schema.rs
#[derive(Clone, Copy, Debug, Eq, PartialEq, Ord, PartialOrd, Hash)]
#[repr(u8)]
pub enum SyncStatus {
    Unknown = 0,
    New = 1,
    Normal = 2,
}

impl SyncStatus {
    #[inline]
    pub fn from_u8(v: u8) -> Self {
        match v {
            1 => SyncStatus::New,
            2 => SyncStatus::Normal,
            _ => SyncStatus::Unknown,
        }
    }
}

impl FromSql for SyncStatus {
    fn column_result(value: ValueRef<'_>) -> FromSqlResult<Self> {
        let v = value.as_i64()?;
        if v < 0 || v > i64::from(u8::max_value()) {
            return Err(FromSqlError::OutOfRange(v));
        }
        Ok(SyncStatus::from_u8(v as u8))
    }
}

impl ToSql for SyncStatus {
    fn to_sql(&self) -> RusqliteResult<ToSqlOutput<'_>> {
        Ok(ToSqlOutput::from(*self as u8))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_primitive() {
        assert_eq!(
            Some(VisitTransition::Link),
            VisitTransition::from_primitive(1)
        );
        assert_eq!(None, VisitTransition::from_primitive(99));
    }
}
