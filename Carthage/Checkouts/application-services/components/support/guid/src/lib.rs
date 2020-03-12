/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]
// (It's tempting to avoid the utf8 checks, but they're easy to get wrong, so)
#![deny(unsafe_code)]
#[cfg(feature = "serde_support")]
mod serde_support;

#[cfg(feature = "rusqlite_support")]
mod rusqlite_support;

use std::{
    cmp::Ordering,
    fmt,
    hash::{Hash, Hasher},
    ops, str,
};

/// This is a type intended to be used to represent the guids used by sync. It
/// has several benefits over using a `String`:
///
/// 1. It's more explicit about what is being stored, and could prevent bugs
///    where a Guid is passed to a function expecting text.
///
/// 2. Guids are guaranteed to be immutable.
///
/// 3. It's optimized for the guids commonly used by sync. In particular, short guids
///    (including the guids which would meet `PlacesUtils.isValidGuid`) do not incur
///    any heap allocation, and are stored inline.
#[derive(Clone)]
pub struct Guid(Repr);

// The internal representation of a GUID. Most Sync GUIDs are 12 bytes,
// and contain only base64url characters; we can store them on the stack
// without a heap allocation. However, arbitrary ascii guids of up to length 64
// are possible, in which case we fall back to a heap-allocated string.
//
// This is separate only because making `Guid` an enum would expose the
// internals.
#[derive(Clone)]
enum Repr {
    // see FastGuid for invariants
    Fast(FastGuid),

    // invariants:
    // - _0.len() > MAX_FAST_GUID_LEN
    Slow(String),
}

/// Invariants:
///
/// - `len <= MAX_FAST_GUID_LEN`.
/// - `data[0..len]` encodes valid utf8.
/// - `data[len..].iter().all(|&b| b == b'\0')`
///
/// Note: None of these are required for memory safety, just correctness.
#[derive(Clone)]
struct FastGuid {
    len: u8,
    data: [u8; MAX_FAST_GUID_LEN],
}

// This is the maximum length (experimentally determined) we can make it before
// `Repr::Fast` is larger than `Guid::Slow` on 32 bit systems. The important
// thing is really that it's not too big, and is above 12 bytes.
const MAX_FAST_GUID_LEN: usize = 14;

impl FastGuid {
    #[inline]
    fn from_slice(bytes: &[u8]) -> Self {
        // Checked by the caller, so debug_assert is fine.
        debug_assert!(
            can_use_fast(bytes),
            "Bug: Caller failed to check can_use_fast: {:?}",
            bytes
        );
        let mut data = [0u8; MAX_FAST_GUID_LEN];
        data[0..bytes.len()].copy_from_slice(bytes);
        FastGuid {
            len: bytes.len() as u8,
            data,
        }
    }

    #[inline]
    fn as_str(&self) -> &str {
        // Note: we only use debug_assert! to enusre valid utf8-ness, so this need
        str::from_utf8(self.bytes()).expect("Invalid fast guid bytes!")
    }

    #[inline]
    fn len(&self) -> usize {
        self.len as usize
    }

    #[inline]
    fn bytes(&self) -> &[u8] {
        &self.data[0..self.len()]
    }
}

// Returns:
// - true to use Repr::Fast
// - false to use Repr::Slow
#[inline]
fn can_use_fast<T: ?Sized + AsRef<[u8]>>(bytes: &T) -> bool {
    let bytes = bytes.as_ref();
    // This is fine as a debug_assert since we'll still panic if it's ever used
    // in such a way where it would matter.
    debug_assert!(str::from_utf8(bytes).is_ok());
    bytes.len() <= MAX_FAST_GUID_LEN
}

impl Guid {
    /// Create a guid from a `str`.
    #[inline]
    pub fn new(s: &str) -> Self {
        Guid::from_slice(s.as_ref())
    }

    /// Create an empty guid. Usable as a constant.
    #[inline]
    pub const fn empty() -> Self {
        Guid(Repr::Fast(FastGuid {
            len: 0,
            data: [0u8; MAX_FAST_GUID_LEN],
        }))
    }

    /// Create a random guid (of 12 base64url characters). Requires the `random`
    /// feature.
    #[cfg(feature = "random")]
    pub fn random() -> Self {
        let bytes: [u8; 9] = rand::random();

        // Note: only first 12 bytes are used, but remaining are required to
        // build the FastGuid
        let mut output = [0u8; MAX_FAST_GUID_LEN];

        let bytes_written =
            base64::encode_config_slice(&bytes, base64::URL_SAFE_NO_PAD, &mut output[..12]);

        debug_assert!(bytes_written == 12);

        Guid(Repr::Fast(FastGuid {
            len: 12,
            data: output,
        }))
    }

    /// Convert `b` into a `Guid`.
    #[inline]
    pub fn from_string(s: String) -> Self {
        Guid::from_vec(s.into_bytes())
    }

    /// Convert `b` into a `Guid`.
    #[inline]
    pub fn from_slice(b: &[u8]) -> Self {
        if can_use_fast(b) {
            Guid(Repr::Fast(FastGuid::from_slice(b)))
        } else {
            Guid::new_slow(b.into())
        }
    }

    /// Convert `v` to a `Guid`, consuming it.
    #[inline]
    pub fn from_vec(v: Vec<u8>) -> Self {
        if can_use_fast(&v) {
            Guid(Repr::Fast(FastGuid::from_slice(&v)))
        } else {
            Guid::new_slow(v)
        }
    }

    /// Get the data backing this `Guid` as a `&[u8]`.
    #[inline]
    pub fn as_bytes(&self) -> &[u8] {
        match &self.0 {
            Repr::Fast(rep) => rep.bytes(),
            Repr::Slow(rep) => rep.as_ref(),
        }
    }

    /// Get the data backing this `Guid` as a `&str`.
    #[inline]
    pub fn as_str(&self) -> &str {
        match &self.0 {
            Repr::Fast(rep) => rep.as_str(),
            Repr::Slow(rep) => rep.as_ref(),
        }
    }

    /// Convert this `Guid` into a `String`, consuming it in the process.
    #[inline]
    pub fn into_string(self) -> String {
        match self.0 {
            Repr::Fast(rep) => rep.as_str().into(),
            Repr::Slow(rep) => rep,
        }
    }

    /// Returns true for Guids that are deemed valid by the sync server.
    /// See https://github.com/mozilla-services/server-syncstorage/blob/d92ef07877aebd05b92f87f6ade341d6a55bffc8/syncstorage/bso.py#L24
    pub fn is_valid_for_sync_server(&self) -> bool {
        !self.is_empty()
            && self.len() <= 64
            && self.bytes().all(|b| b >= b' ' && b <= b'~' && b != b',')
    }

    /// Returns true for Guids that are valid places guids, and false for all others.
    pub fn is_valid_for_places(&self) -> bool {
        self.len() == 12 && self.bytes().all(Guid::is_valid_places_byte)
    }

    /// Returns true if the byte `b` is a valid base64url byte.
    #[inline]
    pub fn is_valid_places_byte(b: u8) -> bool {
        BASE64URL_BYTES[b as usize] == 1
    }

    #[cold]
    fn new_slow(v: Vec<u8>) -> Self {
        assert!(
            !can_use_fast(&v),
            "Could use fast for guid (len = {})",
            v.len()
        );
        Guid(Repr::Slow(
            String::from_utf8(v).expect("Invalid slow guid bytes!"),
        ))
    }
}

// This is used to implement the places tests.
const BASE64URL_BYTES: [u8; 256] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0,
    0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1,
    0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
];

impl Ord for Guid {
    fn cmp(&self, other: &Self) -> Ordering {
        self.as_bytes().cmp(&other.as_bytes())
    }
}

impl PartialOrd for Guid {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl PartialEq for Guid {
    fn eq(&self, other: &Self) -> bool {
        self.as_bytes() == other.as_bytes()
    }
}

impl Eq for Guid {}

impl Hash for Guid {
    fn hash<H: Hasher>(&self, state: &mut H) {
        self.as_bytes().hash(state);
    }
}

impl<'a> From<&'a str> for Guid {
    #[inline]
    fn from(s: &'a str) -> Guid {
        Guid::from_slice(s.as_ref())
    }
}
impl<'a> From<&'a &str> for Guid {
    #[inline]
    fn from(s: &'a &str) -> Guid {
        Guid::from_slice(s.as_ref())
    }
}

impl<'a> From<&'a [u8]> for Guid {
    #[inline]
    fn from(s: &'a [u8]) -> Guid {
        Guid::from_slice(s)
    }
}

impl From<String> for Guid {
    #[inline]
    fn from(s: String) -> Guid {
        Guid::from_string(s)
    }
}

impl From<Vec<u8>> for Guid {
    #[inline]
    fn from(v: Vec<u8>) -> Guid {
        Guid::from_vec(v)
    }
}

impl From<Guid> for String {
    #[inline]
    fn from(guid: Guid) -> String {
        guid.into_string()
    }
}

impl From<Guid> for Vec<u8> {
    #[inline]
    fn from(guid: Guid) -> Vec<u8> {
        guid.into_string().into_bytes()
    }
}

impl AsRef<str> for Guid {
    #[inline]
    fn as_ref(&self) -> &str {
        self.as_str()
    }
}

impl AsRef<[u8]> for Guid {
    #[inline]
    fn as_ref(&self) -> &[u8] {
        self.as_bytes()
    }
}

impl ops::Deref for Guid {
    type Target = str;
    #[inline]
    fn deref(&self) -> &str {
        self.as_str()
    }
}

// The default Debug impl is pretty unhelpful here.
impl fmt::Debug for Guid {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Guid({:?})", self.as_str())
    }
}

impl fmt::Display for Guid {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        fmt::Display::fmt(self.as_str(), f)
    }
}

impl std::default::Default for Guid {
    /// Create a default guid by calling `Guid::empty()`
    #[inline]
    fn default() -> Self {
        Guid::empty()
    }
}

macro_rules! impl_guid_eq {
    ($($other: ty),+) => {$(
        impl<'a> PartialEq<$other> for Guid {
            #[inline]
            fn eq(&self, other: &$other) -> bool {
                PartialEq::eq(AsRef::<[u8]>::as_ref(self), AsRef::<[u8]>::as_ref(other))
            }
        }

        impl<'a> PartialEq<Guid> for $other {
            #[inline]
            fn eq(&self, other: &Guid) -> bool {
                PartialEq::eq(AsRef::<[u8]>::as_ref(self), AsRef::<[u8]>::as_ref(other))
            }
        }
    )+}
}

// Implement direct comparison with some common types from the stdlib.
impl_guid_eq![str, &'a str, String, [u8], &'a [u8], Vec<u8>];

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_base64url_bytes() {
        let mut expect = [0u8; 256];
        for b in b'0'..=b'9' {
            expect[b as usize] = 1;
        }
        for b in b'a'..=b'z' {
            expect[b as usize] = 1;
        }
        for b in b'A'..=b'Z' {
            expect[b as usize] = 1;
        }
        expect[b'_' as usize] = 1;
        expect[b'-' as usize] = 1;
        assert_eq!(&BASE64URL_BYTES[..], &expect[..]);
    }

    #[test]
    fn test_valid_for_places() {
        assert!(Guid::from("aaaabbbbcccc").is_valid_for_places());
        assert!(Guid::from_slice(b"09_az-AZ_09-").is_valid_for_places());
        assert!(!Guid::from("aaaabbbbccccd").is_valid_for_places()); // too long
        assert!(!Guid::from("aaaabbbbccc").is_valid_for_places()); // too short
        assert!(!Guid::from("aaaabbbbccc=").is_valid_for_places()); // right length, bad character
    }

    #[test]
    fn test_comparison() {
        assert_eq!(Guid::from("abcdabcdabcd"), "abcdabcdabcd");
        assert_ne!(Guid::from("abcdabcdabcd".to_string()), "ABCDabcdabcd");

        assert_eq!(Guid::from("abcdabcdabcd"), &b"abcdabcdabcd"[..]); // b"abcdabcdabcd" has type &[u8; 12]...
        assert_ne!(Guid::from(&b"abcdabcdabcd"[..]), &b"ABCDabcdabcd"[..]);

        assert_eq!(
            Guid::from(b"abcdabcdabcd"[..].to_owned()),
            "abcdabcdabcd".to_string()
        );
        assert_ne!(Guid::from("abcdabcdabcd"), "ABCDabcdabcd".to_string());

        assert_eq!(
            Guid::from("abcdabcdabcd1234"),
            Vec::from(b"abcdabcdabcd1234".as_ref())
        );
        assert_ne!(
            Guid::from("abcdabcdabcd4321"),
            Vec::from(b"ABCDabcdabcd4321".as_ref())
        );

        // order by data instead of length
        assert!(Guid::from("zzz") > Guid::from("aaaaaa"));
        assert!(Guid::from("ThisIsASolowGuid") < Guid::from("zzz"));
        assert!(Guid::from("ThisIsASolowGuid") > Guid::from("AnotherSlowGuid"));
    }

    #[cfg(feature = "random")]
    #[test]
    fn test_random() {
        use std::collections::HashSet;
        // Used to verify uniqueness within our sample of 1000. Could cause
        // random failures, but desktop has the same test, and it's never caused
        // a problem AFAIK.
        let mut seen: HashSet<String> = HashSet::new();
        for _ in 0..1000 {
            let g = Guid::random();
            assert_eq!(g.len(), 12);
            assert!(g.is_valid_for_places());
            let decoded = base64::decode_config(&g, base64::URL_SAFE_NO_PAD).unwrap();
            assert_eq!(decoded.len(), 9);
            let no_collision = seen.insert(g.clone().into_string());
            assert!(no_collision, "{}", g);
        }
    }
}
