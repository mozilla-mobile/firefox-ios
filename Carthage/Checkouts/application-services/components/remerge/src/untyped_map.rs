/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

//! this module implements the untyped_map data type. This works as follows:
//!
//! - The "native" representation of an "untyped_map" value is just the
//!   underlying map data, e.g. a `JsonObject`.
//! - To convert a native map to any other format of map, the tombstone list
//!   must be provided (of course, it's initially empty), creating an
//!   `UntypedMap`
//! - To convert a local map to a native map, the tombstone gets stored in the
//!   database (if applicable) and then discarded. (Note: this happens in
//!   storage/records.rs, with the other local -> native conversion code)
//!
//! See the RFC for the merge algorithm for these.

use crate::{error::*, JsonObject, JsonValue};
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, BTreeSet};

pub type MapData = BTreeMap<String, JsonValue>;

#[derive(Debug, Clone, PartialEq, Deserialize, Serialize, Default)]
pub struct UntypedMap {
    map: MapData,
    #[serde(default)]
    tombs: BTreeSet<String>,
}

// duplication is annoying here, but keeps the api clean and isn't that much
// code
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum OnCollision {
    /// Remove the map entry, keeping the tombstone (for prefer_deletion: true, or if
    /// the tombstone is newer than the data in the map).
    DeleteEntry,
    /// Keep the map entry, remove the tombstone (for prefer_deletion: false, or
    /// if the data in the map is newer than tombstones, e.g. when updating a
    /// record with new data).
    KeepEntry,
}

impl From<OnCollision> for CollisionHandling {
    fn from(src: OnCollision) -> Self {
        match src {
            OnCollision::DeleteEntry => Self::DeleteEntry,
            OnCollision::KeepEntry => Self::KeepEntry,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
enum CollisionHandling {
    /// Emit a `UntypedMapTombstoneCollision` error (a decent default if the map
    /// data and tombstones shouldn't collide).
    Error,
    /// See OnCollision::DeleteEntry
    DeleteEntry,
    /// See OnCollision::KeepEntry
    KeepEntry,
}

impl UntypedMap {
    pub fn empty() -> Self {
        Self::default()
    }

    pub fn from_native(map: JsonObject) -> Self {
        Self {
            map: map.into_iter().collect(),
            tombs: Default::default(),
        }
    }

    fn new_impl(
        mut map: MapData,
        mut tombs: BTreeSet<String>,
        on_tombstone_map_collision: CollisionHandling,
    ) -> Result<UntypedMap> {
        // Should usually be empty so the cloning probably isn't worth fighting
        let collided = map
            .keys()
            .filter(|k| tombs.contains(k.as_str()))
            .cloned()
            .collect::<Vec<_>>();

        for key in collided {
            match on_tombstone_map_collision {
                CollisionHandling::Error => {
                    // this is definitely PII, so only log at trace level.
                    log::trace!("UntypedMap tombstone collision for key {:?}", key);
                    throw!(ErrorKind::UntypedMapTombstoneCollision)
                }
                CollisionHandling::DeleteEntry => {
                    map.remove(&key);
                }
                CollisionHandling::KeepEntry => {
                    tombs.remove(&key);
                }
            }
        }
        Ok(UntypedMap { map, tombs })
    }

    pub fn new<M, T>(map: M, tombstones: T, on_collision: OnCollision) -> Self
    where
        M: IntoIterator<Item = (String, JsonValue)>,
        T: IntoIterator<Item = String>,
    {
        Self::new_impl(
            map.into_iter().collect(),
            tombstones.into_iter().collect(),
            on_collision.into(),
        )
        .expect("bug: new_impl error when not passed CollisionHandling::Error")
    }

    pub fn try_new<M, T>(map: M, tombstones: T) -> Result<Self>
    where
        M: IntoIterator<Item = (String, JsonValue)>,
        T: IntoIterator<Item = String>,
    {
        Self::new_impl(
            map.into_iter().collect(),
            tombstones.into_iter().collect(),
            CollisionHandling::Error,
        )
    }

    pub fn into_local_json(self) -> JsonValue {
        serde_json::to_value(self).expect("UntypedMap can always be represented as json")
    }

    pub fn from_local_json(json: JsonValue) -> Result<Self> {
        serde_json::from_value(json)
            .map_err(Error::from)
            .and_then(|Self { map, tombs }| {
                // Ensure the entry is valid. TODO: eventually maintenance will
                // need to handle this. Is this fine until then?
                Self::try_new(map, tombs)
            })
    }

    // Note: we don't use NativeRecord and such here since these are fields on
    // records, and not actually records themselves. It's not really clear to me
    // if/how we could use the RecordFormat markers or similar here either...
    pub(crate) fn update_local_from_native(
        old_local: JsonValue,
        new_native: JsonValue,
    ) -> Result<JsonValue> {
        Ok(Self::from_local_json(old_local)?
            .with_native(crate::util::into_obj(new_native)?)
            .into_local_json())
    }

    /// Create a new representing an update of our data to the data in to
    /// `new_native`, updating `tombs` in the process. Specifically:
    /// 1. entries in `tombs` which refer to keys in `new_native` are removed
    /// 2. entries in `self.map` which are missing from `new_native` are added
    ///    to `tombs`.
    #[must_use]
    pub fn with_native(&self, new_native: JsonObject) -> Self {
        let now_missing = self.map.keys().filter(|&k| !new_native.contains_key(k));

        let tombs = now_missing
            .chain(self.tombs.iter())
            .filter(|t| !new_native.contains_key(t.as_str()))
            .cloned()
            .collect::<BTreeSet<String>>();

        Self {
            map: new_native.into_iter().collect(),
            tombs,
        }
    }

    pub fn into_native(self) -> JsonObject {
        self.map.into_iter().collect()
    }

    #[inline]
    pub fn map(&self) -> &MapData {
        &self.map
    }

    #[inline]
    pub fn tombstones(&self) -> &BTreeSet<String> {
        &self.tombs
    }

    #[cfg(test)]
    pub(crate) fn assert_tombstones<V>(&self, expect: V)
    where
        V: IntoIterator,
        V::Item: Into<String>,
    {
        assert_eq!(
            self.tombs,
            expect
                .into_iter()
                .map(|s| s.into())
                .collect::<BTreeSet<_>>(),
        );
    }
}

// Note: no derefmut, need to maintain `tombs` array.
impl std::ops::Deref for UntypedMap {
    type Target = MapData;
    #[inline]
    fn deref(&self) -> &Self::Target {
        self.map()
    }
}

#[cfg(test)]
mod test {
    use super::*;
    use matches::matches;

    #[test]
    fn test_new_err() {
        let v = UntypedMap::try_new(
            json_obj!({
                "foo": 3,
                "bar": 4,
            }),
            vec!["a".to_string()],
        )
        .unwrap();
        assert_eq!(v["foo"], 3);
        assert_eq!(v["bar"], 4);
        assert_eq!(v.len(), 2);
        v.assert_tombstones(vec!["a"]);

        let e = UntypedMap::try_new(
            json_obj!({
                "foo": 3,
                "bar": 4,
            }),
            vec!["foo".to_string()],
        )
        .unwrap_err();

        assert!(matches!(e.kind(), ErrorKind::UntypedMapTombstoneCollision));
    }

    #[test]
    fn test_new_delete() {
        let v = UntypedMap::new(
            json_obj!({
                "foo": 3,
                "bar": 4,
            }),
            vec!["foo".to_string(), "quux".to_string()],
            OnCollision::DeleteEntry,
        );
        assert!(!v.contains_key("foo"));
        assert_eq!(v["bar"], 4);
        assert_eq!(v.len(), 1);
        v.assert_tombstones(vec!["foo", "quux"]);
    }

    #[test]
    fn test_new_keep() {
        let v = UntypedMap::new(
            json_obj!({
                "foo": 3,
                "bar": 4,
            }),
            vec!["foo".to_string(), "quux".to_string()],
            OnCollision::KeepEntry,
        );
        assert_eq!(v["foo"], 3);
        assert_eq!(v["bar"], 4);
        assert_eq!(v.len(), 2);
        v.assert_tombstones(vec!["quux"]);
    }

    #[test]
    fn test_update() {
        let o = UntypedMap::try_new(
            json_obj!({
                "foo": 3,
                "bar": 4,
            }),
            vec!["frob".to_string(), "quux".to_string()],
        )
        .unwrap();
        let updated = o.with_native(json_obj!({
            "foo": 5,
            "quux": 10,
        }));

        assert_eq!(updated["foo"], 5);
        assert_eq!(updated["quux"], 10);
        assert_eq!(updated.len(), 2);
        updated.assert_tombstones(vec!["bar", "frob"]);
    }
}
