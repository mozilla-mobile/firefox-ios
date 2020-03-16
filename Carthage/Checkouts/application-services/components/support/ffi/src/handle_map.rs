/* Copyright 2018-2019 Mozilla Foundation
 *
 * Licensed under the Apache License (Version 2.0), or the MIT license,
 * (the "Licenses") at your option. You may not use this file except in
 * compliance with one of the Licenses. You may obtain copies of the
 * Licenses at:
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *    http://opensource.org/licenses/MIT
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the Licenses is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the Licenses for the specific language governing permissions and
 * limitations under the Licenses. */

//! This module provides a [`Handle`] type, which you can think of something
//! like a dynamically checked, type erased reference/pointer type. Depending on
//! the usage pattern a handle can behave as either a borrowed reference, or an
//! owned pointer.
//!
//! They can be losslessly converted [to](Handle::into_u64) and
//! [from](Handle::from_u64) a 64 bit integer, for ease of passing over the FFI
//! (and they implement [`IntoFfi`] using these primitives for this purpose).
//!
//! The benefit is primarially that they can detect common misuse patterns that
//! would otherwise be silent bugs, such as use-after-free, double-free, passing
//! a wrongly-typed pointer to a function, etc.
//!
//! Handles are provided when inserting an item into either a [`HandleMap`] or a
//! [`ConcurrentHandleMap`].
//!
//! # Comparison to types from other crates
//!
//! [`HandleMap`] is similar to types offered by other crates, such as
//! `slotmap`, or `slab`. However, it has a number of key differences which make
//! it better for our purposes as compared to the types in those crates:
//!
//! 1. Unlike `slab` (but like `slotmap`), we implement versioning, detecting
//!    ABA problems, which allows us to detect use after free.
//! 2. Unlike `slotmap`, we don't have the `T: Copy` restriction.
//! 3. Unlike either, we can detect when you use a Key in a map that did not
//!    allocate the key. This is true even when the map is from a `.so` file
//!    compiled separately.
//! 3. Our implementation of doesn't use any `unsafe` (at the time of this
//!    writing).
//!
//! However, it comes with the following drawbacks:
//!
//! 1. `slotmap` holds its version information in a `u32`, and so it takes
//!    2<sup>31</sup> colliding insertions and deletions before it could
//!    potentially fail to detect an ABA issue, wheras we use a `u16`, and are
//!    limited to 2<sup>15</sup>.
//! 2. Similarly, we can only hold 2<sup>16</sup> items at once, unlike
//!    `slotmap`'s 2<sup>32</sup>. (Considering these items are typically things
//!    like database handles, this is probably plenty).
//! 3. Our implementation is slower, and uses slightly more memory than
//!    `slotmap` (which is in part due to the lack of `unsafe` mentioned above)
//!
//! The first two issues seem exceptionally unlikely, even for extremely
//! long-lived `HandleMap`, and we're still memory safe even if they occur (we
//! just might fail to notice a bug). The third issue also seems unimportant for
//! our use case.

use crate::error::{ErrorCode, ExternError};
use crate::into_ffi::IntoFfi;
use std::error::Error as StdError;
use std::fmt;
use std::ops;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::{Mutex, RwLock};

/// `HandleMap` is a collection type which can hold any type of value, and
/// offers a stable handle which can be used to retrieve it on insertion. These
/// handles offer methods for converting [to](Handle::into_u64) and
/// [from](Handle::from_u64) 64 bit integers, meaning they're very easy to pass
/// over the FFI (they also implement [`IntoFfi`] for the same purpose).
///
/// See the [module level docs](index.html) for more information.
///
/// Note: In FFI code, most usage of `HandleMap` will be done through the
/// [`ConcurrentHandleMap`] type, which is a thin wrapper around a
/// `RwLock<HandleMap<Mutex<T>>>`.
#[derive(Debug, Clone)]
pub struct HandleMap<T> {
    // The value of `map_id` in each `Handle`.
    id: u16,

    // Index to the start of the free list. Always points to a free item --
    // we never allow our free list to become empty.
    first_free: u16,

    // The number of entries with `data.is_some()`. This is never equal to
    // `entries.len()`, we always grow before that point to ensure we always have
    // a valid `first_free` index to add entries onto. This is our `len`.
    num_entries: usize,

    // The actual data. Note: entries.len() is our 'capacity'.
    entries: Vec<Entry<T>>,
}

#[derive(Debug, Clone)]
struct Entry<T> {
    // initially 1, incremented on insertion and removal. Thus,
    // if version is even, state should always be EntryState::Active.
    version: u16,
    state: EntryState<T>,
}

#[derive(Debug, Clone)]
enum EntryState<T> {
    // Not part of the free list
    Active(T),
    // The u16 is the next index in the free list.
    InFreeList(u16),
    // Part of the free list, but the sentinel.
    EndOfFreeList,
}

impl<T> EntryState<T> {
    #[cfg(any(debug_assertions, test))]
    fn is_end_of_list(&self) -> bool {
        match self {
            EntryState::EndOfFreeList => true,
            _ => false,
        }
    }

    #[inline]
    fn is_occupied(&self) -> bool {
        self.get_item().is_some()
    }

    #[inline]
    fn get_item(&self) -> Option<&T> {
        match self {
            EntryState::Active(v) => Some(v),
            _ => None,
        }
    }

    #[inline]
    fn get_item_mut(&mut self) -> Option<&mut T> {
        match self {
            EntryState::Active(v) => Some(v),
            _ => None,
        }
    }
}

// Small helper to check our casts.
#[inline]
fn to_u16(v: usize) -> u16 {
    use std::u16::MAX as U16_MAX;
    // Shouldn't ever happen.
    assert!(v <= (U16_MAX as usize), "Bug: Doesn't fit in u16: {}", v);
    v as u16
}

/// The maximum capacity of a [`HandleMap`]. Attempting to instantiate one with
/// a larger capacity will cause a panic.
///
/// Note: This could go as high as `(1 << 16) - 2`, but doing is seems more
/// error prone. For the sake of paranoia, we limit it to this size, which is
/// already quite a bit larger than it seems like we're likely to ever need.
pub const MAX_CAPACITY: usize = (1 << 15) - 1;

// Never having to worry about capacity == 0 simplifies the code at the cost of
// worse memory usage. It doesn't seem like there's any reason to make this
// public.
const MIN_CAPACITY: usize = 4;

/// An error representing the ways a `Handle` may be invalid.
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord)]
pub enum HandleError {
    /// Identical to invalid handle, but has a slightly more helpful
    /// message for the most common case 0.
    NullHandle,

    /// Returned from [`Handle::from_u64`] if [`Handle::is_valid`] fails.
    InvalidHandle,

    /// Returned from get/get_mut/delete if the handle is stale (this indicates
    /// something equivalent to a use-after-free / double-free, etc).
    StaleVersion,

    /// Returned if the handle index references an index past the end of the
    /// HandleMap.
    IndexPastEnd,

    /// The handle has a map_id for a different map than the one it was
    /// attempted to be used with.
    WrongMap,
}

impl StdError for HandleError {}

impl fmt::Display for HandleError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        use HandleError::*;
        match self {
            NullHandle => {
                f.write_str("Tried to use a null handle (this object has probably been closed)")
            }
            InvalidHandle => f.write_str("u64 could not encode a valid Handle"),
            StaleVersion => f.write_str("Handle has stale version number"),
            IndexPastEnd => f.write_str("Handle references a index past the end of this HandleMap"),
            WrongMap => f.write_str("Handle is from a different map"),
        }
    }
}

impl From<HandleError> for ExternError {
    fn from(e: HandleError) -> Self {
        ExternError::new_error(ErrorCode::INVALID_HANDLE, e.to_string())
    }
}

impl<T> HandleMap<T> {
    /// Create a new `HandleMap` with the default capacity.
    pub fn new() -> Self {
        Self::new_with_capacity(MIN_CAPACITY)
    }

    /// Allocate a new `HandleMap`. Note that the actual capacity may be larger
    /// than the requested value.
    ///
    /// Panics if `request` is greater than [`handle_map::MAX_CAPACITY`](MAX_CAPACITY)
    pub fn new_with_capacity(request: usize) -> Self {
        assert!(
            request <= MAX_CAPACITY,
            "HandleMap capacity is limited to {} (request was {})",
            MAX_CAPACITY,
            request
        );

        let capacity = request.max(MIN_CAPACITY);
        let id = next_handle_map_id();
        let mut entries = Vec::with_capacity(capacity);

        // Initialize each entry with version 1, and as a member of the free list
        for i in 0..(capacity - 1) {
            entries.push(Entry {
                version: 1,
                state: EntryState::InFreeList(to_u16(i + 1)),
            });
        }

        // And the final entry is at the end of the free list
        // (but still has version 1).
        entries.push(Entry {
            version: 1,
            state: EntryState::EndOfFreeList,
        });
        Self {
            id,
            first_free: 0,
            num_entries: 0,
            entries,
        }
    }

    /// Get the number of entries in the `HandleMap`.
    #[inline]
    pub fn len(&self) -> usize {
        self.num_entries
    }

    /// Returns true if the HandleMap is empty.
    #[inline]
    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }

    /// Returns the number of slots allocated in the handle map.
    #[inline]
    pub fn capacity(&self) -> usize {
        // It's not a bug that this isn't entries.capacity() -- We're returning
        // how many slots exist, not something about the backing memory allocation
        self.entries.len()
    }

    fn ensure_capacity(&mut self, cap_at_least: usize) {
        assert_ne!(self.len(), self.capacity(), "Bug: should have grown by now");
        assert!(cap_at_least <= MAX_CAPACITY, "HandleMap overfilled");
        if self.capacity() > cap_at_least {
            return;
        }

        let mut next_cap = self.capacity();
        while next_cap <= cap_at_least {
            next_cap *= 2;
        }
        next_cap = next_cap.min(MAX_CAPACITY);

        let need_extra = next_cap.saturating_sub(self.entries.capacity());
        self.entries.reserve(need_extra);

        assert!(
            !self.entries[self.first_free as usize].state.is_occupied(),
            "Bug: HandleMap.first_free points at occupied index"
        );

        // Insert new entries at the front of our list.
        while self.entries.len() < next_cap - 1 {
            // This is a little wasteful but whatever. Add each new entry to the
            // front of the free list one at a time.
            self.entries.push(Entry {
                version: 1,
                state: EntryState::InFreeList(self.first_free),
            });
            self.first_free = to_u16(self.entries.len() - 1);
        }

        self.debug_check_valid();
    }

    #[inline]
    fn debug_check_valid(&self) {
        // Run the expensive validity check in tests and in debug builds.
        #[cfg(any(debug_assertions, test))]
        {
            self.assert_valid();
        }
    }

    #[cfg(any(debug_assertions, test))]
    fn assert_valid(&self) {
        assert_ne!(self.len(), self.capacity());
        assert!(self.capacity() <= MAX_CAPACITY, "Entries too large");
        // Validate that our free list is correct.

        let number_of_ends = self
            .entries
            .iter()
            .filter(|e| e.state.is_end_of_list())
            .count();
        assert_eq!(
            number_of_ends, 1,
            "More than one entry think's it's the end of the list, or no entries do"
        );

        // Check that the free list hits every unoccupied item.
        // The tuple is: `(should_be_in_free_list, is_in_free_list)`.
        let mut free_indices = vec![(false, false); self.capacity()];
        for (i, e) in self.entries.iter().enumerate() {
            if !e.state.is_occupied() {
                free_indices[i].0 = true;
            }
        }

        let mut next = self.first_free;
        loop {
            let ni = next as usize;

            assert!(
                ni <= free_indices.len(),
                "Free list contains out of bounds index!"
            );

            assert!(
                free_indices[ni].0,
                "Free list has an index that shouldn't be free! {}",
                ni
            );

            assert!(
                !free_indices[ni].1,
                "Free list hit an index ({}) more than once! Cycle detected!",
                ni
            );

            free_indices[ni].1 = true;

            match &self.entries[ni].state {
                EntryState::InFreeList(next_index) => next = *next_index,
                EntryState::EndOfFreeList => break,
                // Hitting `Active` here is probably not possible because of the checks above, but who knows.
                EntryState::Active(..) => unreachable!("Bug: Active item in free list at {}", next),
            }
        }
        let mut occupied_count = 0;
        for (i, &(should_be_free, is_free)) in free_indices.iter().enumerate() {
            assert_eq!(
                should_be_free, is_free,
                "Free list missed item, or contains an item it shouldn't: {}",
                i
            );
            if !should_be_free {
                occupied_count += 1;
            }
        }
        assert_eq!(
            self.num_entries, occupied_count,
            "num_entries doesn't reflect the actual number of entries"
        );
    }

    /// Insert an item into the map, and return a handle to it.
    pub fn insert(&mut self, v: T) -> Handle {
        let need_cap = self.len() + 1;
        self.ensure_capacity(need_cap);
        let index = self.first_free;
        let result = {
            // Scoped mutable borrow of entry.
            let entry = &mut self.entries[index as usize];
            let new_first_free = match entry.state {
                EntryState::InFreeList(i) => i,
                _ => panic!("Bug: next_index pointed at non-free list entry (or end of list)"),
            };
            entry.version += 1;
            if entry.version == 0 {
                entry.version += 2;
            }
            entry.state = EntryState::Active(v);
            self.first_free = new_first_free;
            self.num_entries += 1;

            Handle {
                map_id: self.id,
                version: entry.version,
                index,
            }
        };
        self.debug_check_valid();
        result
    }

    // Helper to contain the handle validation boilerplate. Returns `h.index as usize`.
    fn check_handle(&self, h: Handle) -> Result<usize, HandleError> {
        if h.map_id != self.id {
            log::info!(
                "HandleMap access with handle having wrong map id: {:?} (our map id is {})",
                h,
                self.id
            );
            return Err(HandleError::WrongMap);
        }
        let index = h.index as usize;
        if index >= self.entries.len() {
            log::info!("HandleMap accessed with handle past end of map: {:?}", h);
            return Err(HandleError::IndexPastEnd);
        }
        if self.entries[index].version != h.version {
            log::info!(
                "HandleMap accessed with handle with wrong version {:?} (entry version is {})",
                h,
                self.entries[index].version
            );
            return Err(HandleError::StaleVersion);
        }
        // At this point, we know the handle version matches the entry version,
        // but if someone created a specially invalid handle, they could have
        // its version match the version they expect an unoccupied index to
        // have.
        //
        // We don't use any unsafe, so the worse thing that can happen here is
        // that we get confused and panic, but still that's not great, so we
        // check for this explicitly.
        //
        // Note that `active` versions are always even, as they start at 1, and
        // are incremented on both insertion and deletion.
        //
        // Anyway, this is just for sanity checking, we already check this in
        // practice when we convert `u64`s into `Handle`s, which is the only
        // way we ever use these in the real world.
        if (h.version % 2) != 0 {
            log::info!(
                "HandleMap given handle with matching but illegal version: {:?}",
                h,
            );
            return Err(HandleError::StaleVersion);
        }
        Ok(index)
    }

    /// Delete an item from the HandleMap.
    pub fn delete(&mut self, h: Handle) -> Result<(), HandleError> {
        self.remove(h).map(drop)
    }

    /// Remove an item from the HandleMap, returning the old value.
    pub fn remove(&mut self, h: Handle) -> Result<T, HandleError> {
        let index = self.check_handle(h)?;
        let prev = {
            // Scoped mutable borrow of entry.
            let entry = &mut self.entries[index];
            entry.version += 1;
            let index = h.index;
            let last_state =
                std::mem::replace(&mut entry.state, EntryState::InFreeList(self.first_free));
            self.num_entries -= 1;
            self.first_free = index;

            if let EntryState::Active(value) = last_state {
                value
            } else {
                // This indicates either a bug in HandleMap or memory
                // corruption. Abandon all hope.
                unreachable!(
                    "Handle {:?} passed validation but references unoccupied entry",
                    h
                );
            }
        };
        self.debug_check_valid();
        Ok(prev)
    }

    /// Get a reference to the item referenced by the handle, or return a
    /// [`HandleError`] describing the problem.
    pub fn get(&self, h: Handle) -> Result<&T, HandleError> {
        let idx = self.check_handle(h)?;
        let entry = &self.entries[idx];
        // This should be caught by check_handle above, but we avoid panicking
        // because we'd rather not poison any locks we don't have to poison
        let item = entry
            .state
            .get_item()
            .ok_or_else(|| HandleError::InvalidHandle)?;
        Ok(item)
    }

    /// Get a mut reference to the item referenced by the handle, or return a
    /// [`HandleError`] describing the problem.
    pub fn get_mut(&mut self, h: Handle) -> Result<&mut T, HandleError> {
        let idx = self.check_handle(h)?;
        let entry = &mut self.entries[idx];
        // This should be caught by check_handle above, but we avoid panicking
        // because we'd rather not poison any locks we don't have to poison
        let item = entry
            .state
            .get_item_mut()
            .ok_or_else(|| HandleError::InvalidHandle)?;
        Ok(item)
    }
}

impl<T> Default for HandleMap<T> {
    #[inline]
    fn default() -> Self {
        HandleMap::new()
    }
}

impl<T> ops::Index<Handle> for HandleMap<T> {
    type Output = T;
    #[inline]
    fn index(&self, h: Handle) -> &T {
        self.get(h)
            .expect("Indexed into HandleMap with invalid handle!")
    }
}

// We don't implement IndexMut intentionally (implementing ops::Index is
// dubious enough)

/// A Handle we allow to be returned over the FFI by implementing [`IntoFfi`].
/// This type is intentionally not `#[repr(C)]`, and getting the data out of the
/// FFI is done using `Handle::from_u64`, or it's implemetation of `From<u64>`.
///
/// It consists of, at a minimum:
///
/// - A "map id" (used to ensure you're using it with the correct map)
/// - a "version" (incremented when the value in the index changes, used to
///   detect multiple frees, use after free, and ABA and ABA)
/// - and a field indicating which index it goes into.
///
/// In practice, it may also contain extra information to help detect other
/// errors (currently it stores a "magic value" used to detect invalid
/// [`Handle`]s).
///
/// These fields may change but the following guarantees are made about the
/// internal representation:
///
/// - This will always be representable in 64 bits.
/// - The bits, when interpreted as a signed 64 bit integer, will be positive
///   (that is to say, it will *actually* be representable in 63 bits, since
///   this makes the most significant bit unavailable for the purposes of
///   encoding). This guarantee makes things slightly less dubious when passing
///   things to Java, gives us some extra validation ability, etc.
#[derive(Copy, Clone, Debug, PartialEq)]
pub struct Handle {
    map_id: u16,
    version: u16,
    index: u16,
}

// We stuff this into the top 16 bits of the handle when u16 encoded to detect
// various sorts of weirdness. It's the letters 'A' and 'S' as ASCII, but the
// only important thing about it is that the most significant bit be unset.
const HANDLE_MAGIC: u16 = 0x4153_u16;

impl Handle {
    /// Convert a `Handle` to a `u64`. You can also use `Into::into` directly.
    /// Most uses of this will be automatic due to our [`IntoFfi`] implementation.
    #[inline]
    pub fn into_u64(self) -> u64 {
        let map_id = u64::from(self.map_id);
        let version = u64::from(self.version);
        let index = u64::from(self.index);
        // SOMEDAY: we could also use this as a sort of CRC if we were really paranoid.
        // e.g. `magic = combine_to_u16(map_id, version, index)`.
        let magic = u64::from(HANDLE_MAGIC);
        (magic << 48) | (map_id << 32) | (index << 16) | version
    }

    /// Convert a `u64` to a `Handle`. Inverse of `into_u64`. We also implement
    /// `From::from` (which will panic instead of returning Err).
    ///
    /// Returns [`HandleError::InvalidHandle`](HandleError) if the bits cannot
    /// possibly represent a valid handle.
    pub fn from_u64(v: u64) -> Result<Self, HandleError> {
        if !Handle::is_valid(v) {
            log::warn!("Illegal handle! {:x}", v);
            if v == 0 {
                Err(HandleError::NullHandle)
            } else {
                Err(HandleError::InvalidHandle)
            }
        } else {
            let map_id = (v >> 32) as u16;
            let index = (v >> 16) as u16;
            let version = v as u16;
            Ok(Self {
                map_id,
                version,
                index,
            })
        }
    }

    /// Returns whether or not `v` makes a bit pattern that could represent an
    /// encoded [`Handle`].
    #[inline]
    pub fn is_valid(v: u64) -> bool {
        (v >> 48) == u64::from(HANDLE_MAGIC) &&
        // The "bottom" field is the version. We increment it both when
        // inserting and removing, and they're all initially 1. So, all valid
        // handles that we returned should have an even version.
        ((v & 1) == 0)
    }
}

impl From<u64> for Handle {
    fn from(u: u64) -> Self {
        Handle::from_u64(u).expect("Illegal handle!")
    }
}

impl From<Handle> for u64 {
    #[inline]
    fn from(h: Handle) -> u64 {
        h.into_u64()
    }
}

unsafe impl IntoFfi for Handle {
    type Value = u64;
    // Note: intentionally does not encode a valid handle for any map.
    #[inline]
    fn ffi_default() -> u64 {
        0u64
    }
    #[inline]
    fn into_ffi_value(self) -> u64 {
        self.into_u64()
    }
}

/// `ConcurrentHandleMap` is a relatively thin wrapper around
/// `RwLock<HandleMap<Mutex<T>>>`. Due to the nested locking, it's not possible
/// to implement the same API as [`HandleMap`], however it does implement an API
/// that offers equivalent functionality, as well as several functions that
/// greatly simplify FFI usage (see example below).
///
/// See the [module level documentation](index.html) for more info.
///
/// # Example
///
/// ```rust,no_run
/// # #[macro_use] extern crate lazy_static;
/// # extern crate ffi_support;
/// # use ffi_support::*;
/// # use std::sync::*;
///
/// // Somewhere...
/// struct Thing { value: f64 }
///
/// lazy_static! {
///     static ref ITEMS: ConcurrentHandleMap<Thing> = ConcurrentHandleMap::new();
/// }
///
/// #[no_mangle]
/// pub extern "C" fn mylib_new_thing(value: f64, err: &mut ExternError) -> u64 {
///     // Most uses will be `ITEMS.insert_with_result`. Note that this already
///     // calls `call_with_output` (or `call_with_result` if this were
///     // `insert_with_result`) for you.
///     ITEMS.insert_with_output(err, || Thing { value })
/// }
///
/// #[no_mangle]
/// pub extern "C" fn mylib_thing_value(h: u64, err: &mut ExternError) -> f64 {
///     // Or `ITEMS.call_with_result` for the fallible functions.
///     ITEMS.call_with_output(err, h, |thing| thing.value)
/// }
///
/// #[no_mangle]
/// pub extern "C" fn mylib_thing_set_value(h: u64, new_value: f64, err: &mut ExternError) {
///     ITEMS.call_with_output_mut(err, h, |thing| {
///         thing.value = new_value;
///     })
/// }
///
/// // Note: defines the following function:
/// // pub extern "C" fn mylib_destroy_thing(h: u64, err: &mut ExternError)
/// define_handle_map_deleter!(ITEMS, mylib_destroy_thing);
/// ```
pub struct ConcurrentHandleMap<T> {
    /// The underlying map. Public so that more advanced use-cases
    /// may use it as they please.
    pub map: RwLock<HandleMap<Mutex<T>>>,
}

impl<T> ConcurrentHandleMap<T> {
    /// Construct a new `ConcurrentHandleMap`.
    pub fn new() -> Self {
        Self {
            map: RwLock::new(HandleMap::new()),
        }
    }

    /// Get the number of entries in the `ConcurrentHandleMap`.
    ///
    /// This takes the map's `read` lock.
    #[inline]
    pub fn len(&self) -> usize {
        let map = self.map.read().unwrap();
        map.len()
    }

    /// Returns true if the `ConcurrentHandleMap` is empty.
    ///
    /// This takes the map's `read` lock.
    #[inline]
    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }

    /// Insert an item into the map, returning the newly allocated handle to the
    /// item.
    ///
    /// # Locking
    ///
    /// Note that this requires taking the map's write lock, and so it will
    /// block until all other threads have finished any read/write operations.
    pub fn insert(&self, v: T) -> Handle {
        // Fails if the lock is poisoned. Not clear what we should do here... We
        // could always insert anyway (by matching on LockResult), but that
        // seems... really quite dubious.
        let mut map = self.map.write().unwrap();
        map.insert(Mutex::new(v))
    }

    /// Remove an item from the map.
    ///
    /// # Locking
    ///
    /// Note that this requires taking the map's write lock, and so it will
    /// block until all other threads have finished any read/write operations.
    pub fn delete(&self, h: Handle) -> Result<(), HandleError> {
        // We use `remove` and not delete (and use the inner block) to ensure
        // that if `v`'s destructor panics, we aren't holding the write lock
        // when it happens, so that the map itself doesn't get poisoned.
        let v = {
            let mut map = self.map.write().unwrap();
            map.remove(h)
        };
        v.map(drop)
    }

    /// Convenient wrapper for `delete` which takes a `u64` that it will
    /// convert to a handle.
    ///
    /// The main benefit (besides convenience) of this over the version
    /// that takes a [`Handle`] is that it allows handling handle-related errors
    /// in one place.
    pub fn delete_u64(&self, h: u64) -> Result<(), HandleError> {
        self.delete(Handle::from_u64(h)?)
    }

    /// Remove an item from the map, returning either the item,
    /// or None if its guard mutex got poisoned at some point.
    ///
    /// # Locking
    ///
    /// Note that this requires taking the map's write lock, and so it will
    /// block until all other threads have finished any read/write operations.
    pub fn remove(&self, h: Handle) -> Result<Option<T>, HandleError> {
        let mut map = self.map.write().unwrap();
        let mutex = map.remove(h)?;
        Ok(mutex.into_inner().ok())
    }

    /// Convenient wrapper for `remove` which takes a `u64` that it will
    /// convert to a handle.
    ///
    /// The main benefit (besides convenience) of this over the version
    /// that takes a [`Handle`] is that it allows handling handle-related errors
    /// in one place.
    pub fn remove_u64(&self, h: u64) -> Result<Option<T>, HandleError> {
        self.remove(Handle::from_u64(h)?)
    }

    /// Call `callback` with a non-mutable reference to the item from the map,
    /// after acquiring the necessary locks.
    ///
    /// # Locking
    ///
    /// Note that this requires taking both:
    ///
    /// - The map's read lock, and so it will block until all other threads have
    ///   finished any write operations.
    /// - The mutex on the slot the handle is mapped to.
    ///
    /// And so it will block if there are ongoing write operations, or if
    /// another thread is reading from the same handle.
    ///
    /// # Panics
    ///
    /// This will panic if a previous `get()` or `get_mut()` call has panicked
    /// inside it's callback. The solution to this
    ///
    /// (It may also panic if the handle map detects internal state corruption,
    /// however this should not happen except for bugs in the handle map code).
    pub fn get<F, E, R>(&self, h: Handle, callback: F) -> Result<R, E>
    where
        F: FnOnce(&T) -> Result<R, E>,
        E: From<HandleError>,
    {
        self.get_mut(h, |v| callback(v))
    }

    /// Call `callback` with a mutable reference to the item from the map, after
    /// acquiring the necessary locks.
    ///
    /// # Locking
    ///
    /// Note that this requires taking both:
    ///
    /// - The map's read lock, and so it will block until all other threads have
    ///   finished any write operations.
    /// - The mutex on the slot the handle is mapped to.
    ///
    /// And so it will block if there are ongoing write operations, or if
    /// another thread is reading from the same handle.
    ///
    /// # Panics
    ///
    /// This will panic if a previous `get()` or `get_mut()` call has panicked
    /// inside it's callback. The only solution to this is to remove and reinsert
    /// said item.
    ///
    /// (It may also panic if the handle map detects internal state corruption,
    /// however this should not happen except for bugs in the handle map code).
    pub fn get_mut<F, E, R>(&self, h: Handle, callback: F) -> Result<R, E>
    where
        F: FnOnce(&mut T) -> Result<R, E>,
        E: From<HandleError>,
    {
        // XXX figure out how to handle poison...
        let map = self.map.read().unwrap();
        let mtx = map.get(h)?;
        let mut hm = mtx.lock().unwrap();
        callback(&mut *hm)
    }

    /// Convenient wrapper for `get` which takes a `u64` that it will convert to
    /// a handle.
    ///
    /// The other benefit (besides convenience) of this over the version
    /// that takes a [`Handle`] is that it allows handling handle-related errors
    /// in one place.
    ///
    /// # Locking
    ///
    /// Note that this requires taking both:
    ///
    /// - The map's read lock, and so it will block until all other threads have
    ///   finished any write operations.
    /// - The mutex on the slot the handle is mapped to.
    ///
    /// And so it will block if there are ongoing write operations, or if
    /// another thread is reading from the same handle.
    pub fn get_u64<F, E, R>(&self, u: u64, callback: F) -> Result<R, E>
    where
        F: FnOnce(&T) -> Result<R, E>,
        E: From<HandleError>,
    {
        self.get(Handle::from_u64(u)?, callback)
    }

    /// Convenient wrapper for `get_mut` which takes a `u64` that it will
    /// convert to a handle.
    ///
    /// The main benefit (besides convenience) of this over the version
    /// that takes a [`Handle`] is that it allows handling handle-related errors
    /// in one place.
    ///
    /// # Locking
    ///
    /// Note that this requires taking both:
    ///
    /// - The map's read lock, and so it will block until all other threads have
    ///   finished any write operations.
    /// - The mutex on the slot the handle is mapped to.
    ///
    /// And so it will block if there are ongoing write operations, or if
    /// another thread is reading from the same handle.
    pub fn get_mut_u64<F, E, R>(&self, u: u64, callback: F) -> Result<R, E>
    where
        F: FnOnce(&mut T) -> Result<R, E>,
        E: From<HandleError>,
    {
        self.get_mut(Handle::from_u64(u)?, callback)
    }

    /// Helper that performs both a [`call_with_result`] and [`get`](ConcurrentHandleMap::get_mut).
    pub fn call_with_result_mut<R, E, F>(
        &self,
        out_error: &mut ExternError,
        h: u64,
        callback: F,
    ) -> R::Value
    where
        F: std::panic::UnwindSafe + FnOnce(&mut T) -> Result<R, E>,
        ExternError: From<E>,
        R: IntoFfi,
    {
        use crate::call_with_result;
        call_with_result(out_error, || -> Result<_, ExternError> {
            // We can't reuse get_mut here because it would require E:
            // From<HandleError>, which is inconvenient...
            let h = Handle::from_u64(h)?;
            let map = self.map.read().unwrap();
            let mtx = map.get(h)?;
            let mut hm = mtx.lock().unwrap();
            Ok(callback(&mut *hm)?)
        })
    }

    /// Helper that performs both a [`call_with_result`] and [`get`](ConcurrentHandleMap::get).
    pub fn call_with_result<R, E, F>(
        &self,
        out_error: &mut ExternError,
        h: u64,
        callback: F,
    ) -> R::Value
    where
        F: std::panic::UnwindSafe + FnOnce(&T) -> Result<R, E>,
        ExternError: From<E>,
        R: IntoFfi,
    {
        self.call_with_result_mut(out_error, h, |r| callback(r))
    }

    /// Helper that performs both a [`call_with_output`] and [`get`](ConcurrentHandleMap::get).
    pub fn call_with_output<R, F>(
        &self,
        out_error: &mut ExternError,
        h: u64,
        callback: F,
    ) -> R::Value
    where
        F: std::panic::UnwindSafe + FnOnce(&T) -> R,
        R: IntoFfi,
    {
        self.call_with_result(out_error, h, |r| -> Result<_, HandleError> {
            Ok(callback(r))
        })
    }

    /// Helper that performs both a [`call_with_output`] and [`get_mut`](ConcurrentHandleMap::get).
    pub fn call_with_output_mut<R, F>(
        &self,
        out_error: &mut ExternError,
        h: u64,
        callback: F,
    ) -> R::Value
    where
        F: std::panic::UnwindSafe + FnOnce(&mut T) -> R,
        R: IntoFfi,
    {
        self.call_with_result_mut(out_error, h, |r| -> Result<_, HandleError> {
            Ok(callback(r))
        })
    }

    /// Use `constructor` to create and insert a `T`, while inside a
    /// [`call_with_result`] call (to handle panics and map errors onto an
    /// `ExternError`).
    pub fn insert_with_result<E, F>(&self, out_error: &mut ExternError, constructor: F) -> u64
    where
        F: std::panic::UnwindSafe + FnOnce() -> Result<T, E>,
        ExternError: From<E>,
    {
        use crate::call_with_result;
        call_with_result(out_error, || -> Result<_, ExternError> {
            // Note: it's important that we don't call the constructor while
            // we're holding the write lock, because we don't want to poison
            // the entire map if it panics!
            let to_insert = constructor()?;
            Ok(self.insert(to_insert))
        })
    }

    /// Equivalent to
    /// [`insert_with_result`](ConcurrentHandleMap::insert_with_result) for the
    /// case where the constructor cannot produce an error.
    ///
    /// The name is somewhat dubious, since there's no `output`, but it's intended to make it
    /// clear that it contains a [`call_with_output`] internally.
    pub fn insert_with_output<F>(&self, out_error: &mut ExternError, constructor: F) -> u64
    where
        F: std::panic::UnwindSafe + FnOnce() -> T,
    {
        // The Err type isn't important here beyond being convertable to ExternError
        self.insert_with_result(out_error, || -> Result<_, HandleError> {
            Ok(constructor())
        })
    }
}

impl<T> Default for ConcurrentHandleMap<T> {
    #[inline]
    fn default() -> Self {
        Self::new()
    }
}

// Returns the next map_id.
fn next_handle_map_id() -> u16 {
    let id = HANDLE_MAP_ID_COUNTER
        .fetch_add(1, Ordering::SeqCst)
        .wrapping_add(1);
    id as u16
}

// Note: These IDs are only used to detect using a key against the wrong HandleMap.
// We ensure they're randomly initialized, to prevent using them across separately
// compiled .so files.
lazy_static::lazy_static! {
    // This should be `AtomicU16`, but those aren't stablilized yet.
    // Instead, we just cast to u16 on read.
    static ref HANDLE_MAP_ID_COUNTER: AtomicUsize = {
        // Abuse HashMap's RandomState to get a strong RNG without bringing in
        // the `rand` crate (OTOH maybe we should just bring in the rand crate?)
        use std::collections::hash_map::RandomState;
        use std::hash::{BuildHasher, Hasher};
        let init = RandomState::new().build_hasher().finish() as usize;
        AtomicUsize::new(init)
    };
}

#[cfg(test)]
mod test {
    use super::*;
    use std::sync::Arc;

    #[derive(PartialEq, Debug)]
    struct Foobar(usize);

    #[test]
    fn test_invalid_handle() {
        assert_eq!(Handle::from_u64(0), Err(HandleError::NullHandle));
        // Valid except `version` is odd
        assert_eq!(
            Handle::from_u64((u64::from(HANDLE_MAGIC) << 48) | 0x1234_0012_0001),
            Err(HandleError::InvalidHandle)
        );

        assert_eq!(
            Handle::from_u64((u64::from(HANDLE_MAGIC) << 48) | 0x1234_0012_0002),
            Ok(Handle {
                version: 0x0002,
                index: 0x0012,
                map_id: 0x1234,
            })
        );
    }

    #[test]
    fn test_correct_value_single() {
        let mut map = HandleMap::new();
        let handle = map.insert(Foobar(1234));
        assert_eq!(map.get(handle).unwrap(), &Foobar(1234));
        map.delete(handle).unwrap();
        assert_eq!(map.get(handle), Err(HandleError::StaleVersion));
    }

    #[test]
    fn test_correct_value_multiple() {
        let mut map = HandleMap::new();
        let handle1 = map.insert(Foobar(1234));
        let handle2 = map.insert(Foobar(4321));
        assert_eq!(map.get(handle1).unwrap(), &Foobar(1234));
        assert_eq!(map.get(handle2).unwrap(), &Foobar(4321));
        map.delete(handle1).unwrap();
        assert_eq!(map.get(handle1), Err(HandleError::StaleVersion));
        assert_eq!(map.get(handle2).unwrap(), &Foobar(4321));
    }

    #[test]
    fn test_wrong_map() {
        let mut map1 = HandleMap::new();
        let mut map2 = HandleMap::new();

        let handle1 = map1.insert(Foobar(1234));
        let handle2 = map2.insert(Foobar(1234));

        assert_eq!(map1.get(handle1).unwrap(), &Foobar(1234));
        assert_eq!(map2.get(handle2).unwrap(), &Foobar(1234));

        assert_eq!(map1.get(handle2), Err(HandleError::WrongMap));
        assert_eq!(map2.get(handle1), Err(HandleError::WrongMap));
    }

    #[test]
    fn test_bad_index() {
        let map: HandleMap<Foobar> = HandleMap::new();
        assert_eq!(
            map.get(Handle {
                map_id: map.id,
                version: 2,
                index: 100
            }),
            Err(HandleError::IndexPastEnd)
        );
    }

    #[test]
    fn test_resizing() {
        let mut map = HandleMap::new();
        let mut handles = vec![];
        for i in 0..1000 {
            handles.push(map.insert(Foobar(i)))
        }
        for (i, &h) in handles.iter().enumerate() {
            assert_eq!(map.get(h).unwrap(), &Foobar(i));
            assert_eq!(map.remove(h).unwrap(), Foobar(i));
        }
        let mut handles2 = vec![];
        for i in 1000..2000 {
            // Not really related to this test, but it's convenient to check this here.
            let h = map.insert(Foobar(i));
            let hu = h.into_u64();
            assert_eq!(Handle::from_u64(hu).unwrap(), h);
            handles2.push(hu);
        }

        for (i, (&h0, h1u)) in handles.iter().zip(handles2).enumerate() {
            // It's still a stale version, even though the slot is occupied again.
            assert_eq!(map.get(h0), Err(HandleError::StaleVersion));
            let h1 = Handle::from_u64(h1u).unwrap();
            assert_eq!(map.get(h1).unwrap(), &Foobar(i + 1000));
        }
    }

    fn with_error<F: FnOnce(&mut ExternError) -> T, T>(callback: F) -> T {
        let mut e = ExternError::success();
        let result = callback(&mut e);
        if let Some(m) = unsafe { e.get_and_consume_message() } {
            panic!("unexpected error: {}", m);
        }
        result
    }

    struct DropChecking {
        counter: Arc<AtomicUsize>,
        id: usize,
    }
    impl Drop for DropChecking {
        fn drop(&mut self) {
            let val = self.counter.fetch_add(1, Ordering::SeqCst);
            log::debug!("Dropped {} :: {}", self.id, val);
        }
    }
    #[test]
    fn test_concurrent_drop() {
        use rand::prelude::*;
        use rayon::prelude::*;
        let _ = env_logger::try_init();
        let drop_counter = Arc::new(AtomicUsize::new(0));
        let id = Arc::new(AtomicUsize::new(1));
        let map = ConcurrentHandleMap::new();
        let count = 1000;
        let mut handles = (0..count)
            .into_par_iter()
            .map(|_| {
                let id = id.fetch_add(1, Ordering::SeqCst);
                let handle = with_error(|e| {
                    map.insert_with_output(e, || {
                        log::debug!("Created {}", id);
                        DropChecking {
                            counter: drop_counter.clone(),
                            id,
                        }
                    })
                });
                (id, handle)
            })
            .collect::<Vec<_>>();

        handles.shuffle(&mut thread_rng());

        assert_eq!(drop_counter.load(Ordering::SeqCst), 0);
        handles.par_iter().for_each(|(id, h)| {
            with_error(|e| {
                map.call_with_output(e, *h, |val| {
                    assert_eq!(val.id, *id);
                })
            });
        });

        assert_eq!(drop_counter.load(Ordering::SeqCst), 0);

        handles.par_iter().for_each(|(id, h)| {
            with_error(|e| {
                map.call_with_output(e, *h, |val| {
                    assert_eq!(val.id, *id);
                })
            });
        });

        handles.par_iter().for_each(|(id, h)| {
            let item = map
                .remove_u64(*h)
                .expect("remove to succeed")
                .expect("item to exist");
            assert_eq!(item.id, *id);
            let h = map.insert(item).into_u64();
            map.delete_u64(h).expect("delete to succeed");
        });
        assert_eq!(drop_counter.load(Ordering::SeqCst), count);
    }

    struct PanicOnDrop(());
    impl Drop for PanicOnDrop {
        fn drop(&mut self) {
            panic!("intentional panic (drop)");
        }
    }

    #[test]
    fn test_panicking_drop() {
        let map = ConcurrentHandleMap::new();
        let h = map.insert(PanicOnDrop(())).into_u64();
        let mut e = ExternError::success();
        crate::call_with_result(&mut e, || map.delete_u64(h));
        assert_eq!(e.get_code(), crate::ErrorCode::PANIC);
        let _ = unsafe { e.get_and_consume_message() };
        assert!(!map.map.is_poisoned());
        let inner = map.map.read().unwrap();
        inner.assert_valid();
        assert_eq!(inner.len(), 0);
    }

    #[test]
    fn test_panicking_call_with() {
        let map = ConcurrentHandleMap::new();
        let h = map.insert(Foobar(0)).into_u64();
        let mut e = ExternError::success();
        map.call_with_output(&mut e, h, |_thing| {
            panic!("intentional panic (call_with_output)");
        });

        assert_eq!(e.get_code(), crate::ErrorCode::PANIC);
        let _ = unsafe { e.get_and_consume_message() };

        {
            assert!(!map.map.is_poisoned());
            let inner = map.map.read().unwrap();
            inner.assert_valid();
            assert_eq!(inner.len(), 1);
            let mut seen = false;
            for e in &inner.entries {
                if let EntryState::Active(v) = &e.state {
                    assert!(!seen);
                    assert!(v.is_poisoned());
                    seen = true;
                }
            }
        }
        assert!(map.delete_u64(h).is_ok());
        assert!(!map.map.is_poisoned());
        let inner = map.map.read().unwrap();
        inner.assert_valid();
        assert_eq!(inner.len(), 0);
    }

    #[test]
    fn test_panicking_insert_with() {
        let map = ConcurrentHandleMap::new();
        let mut e = ExternError::success();
        let res = map.insert_with_output(&mut e, || {
            panic!("intentional panic (insert_with_output)");
        });

        assert_eq!(e.get_code(), crate::ErrorCode::PANIC);
        let _ = unsafe { e.get_and_consume_message() };

        assert_eq!(res, 0);

        assert!(!map.map.is_poisoned());
        let inner = map.map.read().unwrap();
        inner.assert_valid();
        assert_eq!(inner.len(), 0);
    }
}
