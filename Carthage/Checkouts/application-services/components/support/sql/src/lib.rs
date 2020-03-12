/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]

mod conn_ext;
mod each_chunk;
mod interrupt;
mod maybe_cached;
mod query_plan;
mod repeat;

pub use crate::conn_ext::*;
pub use crate::each_chunk::*;
pub use crate::interrupt::*;
pub use crate::maybe_cached::*;
pub use crate::query_plan::*;
pub use crate::repeat::*;

/// In PRAGMA foo='bar', `'bar'` must be a constant string (it cannot be a
/// bound parameter), so we need to escape manually. According to
/// https://www.sqlite.org/faq.html, the only character that must be escaped is
/// the single quote, which is escaped by placing two single quotes in a row.
pub fn escape_string_for_pragma(s: &str) -> String {
    s.replace("'", "''")
}

#[cfg(test)]
mod test {
    use super::*;
    #[test]
    fn test_escape_string_for_pragma() {
        assert_eq!(escape_string_for_pragma("foobar"), "foobar");
        assert_eq!(escape_string_for_pragma("'foo'bar'"), "''foo''bar''");
        assert_eq!(escape_string_for_pragma("''"), "''''");
    }
}
