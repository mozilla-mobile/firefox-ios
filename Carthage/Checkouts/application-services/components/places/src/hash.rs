/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// This is MAX_CHARS_TO_HASH in places, but I've renamed it because it's in bytes.
// Note that the indices for slicing a Rust `str` are in bytes, so this is what
// we want anyway.
const MAX_BYTES_TO_HASH: usize = 1500;

/// This should be identical to the "real" `mozilla::places::HashURL` with no prefix arg
/// (see also `hash_url_prefix` for the version with one).
///
/// This returns a u64, but only the lower 48 bits should ever be set, so casting to
/// an i64 is totally safe and lossless. If the string has no ':' in it, then the
/// returned hash will be a 32 bit hash.
pub fn hash_url(spec: &str) -> u64 {
    let max_len_to_hash = spec.len().min(MAX_BYTES_TO_HASH);
    let str_hash = u64::from(hash_string(&spec[..max_len_to_hash]));
    let str_head = &spec[..spec.len().min(50)];
    // We should be using memchr -- there's almost no chance we aren't
    // already pulling it in transitively and it's supposedly *way* faster.
    if let Some(pos) = str_head.as_bytes().iter().position(|&b| b == b':') {
        let prefix_hash = u64::from(hash_string(&spec[..pos]) & 0x0000_ffff);
        (prefix_hash << 32).wrapping_add(str_hash)
    } else {
        str_hash
    }
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum PrefixMode {
    /// Equivalent to `"prefix_lo"` in mozilla::places::HashURL
    Lo,
    /// Equivalent to `"prefix_hi"` in mozilla::places::HashURL
    Hi,
}

/// This should be identical to the "real" `mozilla::places::HashURL` when given
/// a prefix arg. Specifically:
///
/// - `hash_url_prefix(spec, PrefixMode::Lo)` is identical to
/// - `hash_url_prefix(spec, PrefixMode::Hi)` is identical to
///
/// As with `hash_url`, it returns a u64, but only the lower 48 bits should ever be set, so
/// casting to e.g. an i64 is lossless.
pub fn hash_url_prefix(spec_prefix: &str, mode: PrefixMode) -> u64 {
    let to_hash = &spec_prefix[..spec_prefix.len().min(MAX_BYTES_TO_HASH)];

    // Keep 16 bits
    let unshifted_hash = hash_string(to_hash) & 0x0000_ffff;
    let hash = u64::from(unshifted_hash) << 32;
    if mode == PrefixMode::Hi {
        hash.wrapping_add(0xffff_ffffu64)
    } else {
        hash
    }
}

// mozilla::kGoldenRatioU32
const GOLDEN_RATIO: u32 = 0x9E37_79B9;

// mozilla::AddU32ToHash
#[inline]
fn add_u32_to_hash(hash: u32, new_value: u32) -> u32 {
    (hash.rotate_left(5) ^ new_value).wrapping_mul(GOLDEN_RATIO)
}

/// This should return identical results to `mozilla::HashString`!
#[inline]
pub fn hash_string(string: &str) -> u32 {
    string
        .as_bytes()
        .iter()
        .fold(0u32, |hash, &cur| add_u32_to_hash(hash, u32::from(cur)))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_prefixes() {
        // These are the unique 16 bits of the prefix. You can generate these with:
        // `PlacesUtils.history.hashURL(val, "prefix_lo").toString(16).slice(0, 4)`.
        let test_values = &[
            ("http", 0x7226u16),
            ("https", 0x2b12),
            ("blob", 0x2612),
            ("data", 0x9736),
            ("chrome", 0x75fc),
            ("resource", 0x37f8),
            ("file", 0xc7c9),
            ("place", 0xf434),
        ];
        for &(prefix, top16bits) in test_values {
            let expected_lo = u64::from(top16bits) << 32;
            let expected_hi = expected_lo | 0xffff_ffffu64;
            assert_eq!(
                hash_url_prefix(prefix, PrefixMode::Lo),
                expected_lo,
                "wrong value for hash_url_prefix({:?}, PrefixMode::Lo)",
                prefix
            );
            assert_eq!(
                hash_url_prefix(prefix, PrefixMode::Hi),
                expected_hi,
                "wrong value for hash_url_prefix({:?}, PrefixMode::Hi)",
                prefix
            );
        }
    }

    #[test]
    fn test_hash_url() {
        // not actually a valid png, but whatever.
        let data_url = "data:image/png;base64,".to_owned() + &"iVBORw0KGgoAAA".repeat(500);
        let test_values = &[
            ("http://www.example.com", 0x7226_2c1a_3496u64),
            ("http://user:pass@foo:21/bar;par?b#c", 0x7226_61d2_18a7u64),
            (
                "https://github.com/mozilla/application-services/",
                0x2b12_e7bd_7fcdu64,
            ),
            ("place:transition=7&sort=4", 0xf434_ac2b_2dafu64),
            (
                "blob:36c6ded1-6190-45f4-8fcd-355d1b6c9f48",
                0x2612_0a43_1050u64,
            ),
            ("www.example.com", 0x8b14_9337u64), // URLs without a prefix are hashed to 32 bits
            (&data_url[..], 0x9736_d65d_86d9u64),
        ];

        for &(url_str, hash) in test_values {
            assert_eq!(hash_url(url_str), hash, "Wrong value for url {:?}", url_str);
        }
    }
}
