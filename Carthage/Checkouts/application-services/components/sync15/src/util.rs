/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use std::collections::{HashMap, HashSet};
use std::sync::atomic::{AtomicU32, Ordering};

pub use sync15_traits::ServerTimestamp;

/// Finds the maximum of the current value and the argument `val`, and sets the
/// new value to the result.
///
/// Note: `AtomicFoo::fetch_max` is unstable, and can't really be implemented as
/// a single atomic operation from outside the stdlib ;-;
pub(crate) fn atomic_update_max(v: &AtomicU32, new: u32) {
    // For loads (and the compare_exchange_weak second ordering argument) this
    // is too strong, we could probably get away with Acquire (or maybe Relaxed
    // because we don't need the result?). In either case, this fn isn't called
    // from a hot spot so whatever.
    let mut cur = v.load(Ordering::SeqCst);
    while cur < new {
        // we're already handling the failure case so there's no reason not to
        // use _weak here.
        match v.compare_exchange_weak(cur, new, Ordering::SeqCst, Ordering::SeqCst) {
            Ok(_) => {
                // Success.
                break;
            }
            Err(new_cur) => {
                // Interrupted, keep trying.
                cur = new_cur
            }
        }
    }
}

// Slight wrappers around the builtin methods for doing this.
pub(crate) fn set_union(a: &HashSet<String>, b: &HashSet<String>) -> HashSet<String> {
    a.union(b).cloned().collect()
}

pub(crate) fn set_difference(a: &HashSet<String>, b: &HashSet<String>) -> HashSet<String> {
    a.difference(b).cloned().collect()
}

pub(crate) fn set_intersection(a: &HashSet<String>, b: &HashSet<String>) -> HashSet<String> {
    a.intersection(b).cloned().collect()
}

pub(crate) fn partition_by_value(v: &HashMap<String, bool>) -> (HashSet<String>, HashSet<String>) {
    let mut true_: HashSet<String> = HashSet::new();
    let mut false_: HashSet<String> = HashSet::new();
    for (s, val) in v {
        if *val {
            true_.insert(s.clone());
        } else {
            false_.insert(s.clone());
        }
    }
    (true_, false_)
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_set_ops() {
        fn hash_set(s: &[&str]) -> HashSet<String> {
            s.iter()
                .copied()
                .map(ToOwned::to_owned)
                .collect::<HashSet<_>>()
        }

        assert_eq!(
            set_union(&hash_set(&["a", "b", "c"]), &hash_set(&["b", "d"])),
            hash_set(&["a", "b", "c", "d"]),
        );

        assert_eq!(
            set_difference(&hash_set(&["a", "b", "c"]), &hash_set(&["b", "d"])),
            hash_set(&["a", "c"]),
        );
        assert_eq!(
            set_intersection(&hash_set(&["a", "b", "c"]), &hash_set(&["b", "d"])),
            hash_set(&["b"]),
        );
        let m: HashMap<String, bool> = [
            ("foo", true),
            ("bar", true),
            ("baz", false),
            ("quux", false),
        ]
        .iter()
        .copied()
        .map(|(a, b)| (a.to_owned(), b))
        .collect();
        assert_eq!(
            partition_by_value(&m),
            (hash_set(&["foo", "bar"]), hash_set(&["baz", "quux"])),
        );
    }
}
