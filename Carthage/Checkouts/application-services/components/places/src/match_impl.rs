/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::util;
use bitflags::bitflags;
use caseless::Caseless;
use rusqlite::{
    self,
    types::{FromSql, FromSqlError, FromSqlResult, ToSql, ToSqlOutput, ValueRef},
};
use std::borrow::Cow;

const MAX_CHARS_TO_SEARCH_THROUGH: usize = 255;

#[derive(Clone, Copy, PartialEq, Debug)]
#[repr(u32)]
pub enum MatchBehavior {
    // Match anywhere in each searchable tearm
    Anywhere = 0,
    /// Match first on word boundaries, and if we do not get enough results, then
    /// match anywhere in each searchable term.
    BoundaryAnywhere = 1,
    /// Match on word boundaries in each searchable term.
    Boundary = 2,
    /// Match only the beginning of each search term.
    Beginning = 3,
    /// Match anywhere in each searchable term without doing any transformation
    /// or stripping on the underlying data.
    AnywhereUnmodified = 4,
    /// Match only the beginning of each search term using a case sensitive
    /// comparator
    BeginningCaseSensitive = 5,
}

impl FromSql for MatchBehavior {
    #[inline]
    fn column_result(value: ValueRef<'_>) -> FromSqlResult<Self> {
        Ok(match value.as_i64()? {
            0 => MatchBehavior::Anywhere,
            1 => MatchBehavior::BoundaryAnywhere,
            2 => MatchBehavior::Boundary,
            3 => MatchBehavior::Beginning,
            4 => MatchBehavior::AnywhereUnmodified,
            5 => MatchBehavior::BeginningCaseSensitive,
            _ => return Err(FromSqlError::InvalidType),
        })
    }
}

impl ToSql for MatchBehavior {
    #[inline]
    fn to_sql(&self) -> rusqlite::Result<ToSqlOutput<'_>> {
        Ok(ToSqlOutput::from(*self as u32))
    }
}

bitflags! {
    pub struct SearchBehavior: u32 {
        /// Search through history.
        const HISTORY = 1;

        /// Search through bookmarks.
        const BOOKMARK = 1 << 1;

        /// Search through tags.
        const TAG = 1 << 2;

        /// Search through the title of pages.
        const TITLE = 1 << 3;

        /// Search the URL of pages.
        const URL = 1 << 4;

        /// Search for typed pages
        const TYPED = 1 << 5;

        /// Search for javascript: urls
        const JAVASCRIPT = 1 << 6;

        /// Search for open pages (currently not meaningfully implemented)
        const OPENPAGE = 1 << 7;

        /// Use intersection between history, typed, bookmark, tag and openpage
        /// instead of union, when the restrict bit is set.
        const RESTRICT = 1 << 8;

        /// Include search suggestions from the currently selected search provider
        /// (currently not implemented)
        const SEARCHES = 1 << 9;
    }
}

impl Default for SearchBehavior {
    // See `defaultBehavior` in Desktop's `UrlbarPrefs.jsm`.
    fn default() -> SearchBehavior {
        SearchBehavior::HISTORY
            | SearchBehavior::BOOKMARK
            | SearchBehavior::OPENPAGE
            | SearchBehavior::SEARCHES
    }
}

impl SearchBehavior {
    #[inline]
    pub fn any() -> Self {
        SearchBehavior::all() & !SearchBehavior::RESTRICT
    }
}

impl FromSql for SearchBehavior {
    #[inline]
    fn column_result(value: ValueRef<'_>) -> FromSqlResult<Self> {
        SearchBehavior::from_bits(u32::column_result(value)?)
            .ok_or_else(|| FromSqlError::InvalidType)
    }
}

impl ToSql for SearchBehavior {
    #[inline]
    fn to_sql(&self) -> rusqlite::Result<ToSqlOutput<'_>> {
        Ok(ToSqlOutput::from(self.bits()))
    }
}

/// Convert `c` to lower case if it's an alphabetic ascii character, or completely mangle it if it's
/// not. Just returns `c | 0x20`. I don't know if I actually believe this is faster in a way that
/// matters than the saner version.
#[inline(always)]
fn dubious_to_ascii_lower(c: u8) -> u8 {
    c | 0x20
}

/// A port of nextSearchCandidate in the desktop places's SQLFunctions.cpp:
///
/// > Scan forward through UTF-8 text until the next potential character that
/// > could match a given codepoint when lower-cased (false positives are okay).
/// > This avoids having to actually parse the UTF-8 text, which is slow.
///
/// It returns the byte index of the first character that could possibly match.
#[inline(always)]
fn next_search_candidate(to_search: &str, search_for: char) -> Option<usize> {
    // If the character we search for is ASCII, then we can scan until we find
    // it or its ASCII uppercase character, modulo the special cases
    // U+0130 LATIN CAPITAL LETTER I WITH DOT ABOVE and U+212A KELVIN SIGN
    // (which are the only non-ASCII characters that lower-case to ASCII ones).
    // Since false positives are okay, we approximate ASCII lower-casing by
    // bit-ORing with 0x20, for increased performance.
    //
    // If the character we search for is *not* ASCII, we can ignore everything
    // that is, since all ASCII characters lower-case to ASCII.
    //
    // Because of how UTF-8 uses high-order bits, this will never land us
    // in the middle of a codepoint.
    //
    // The assumptions about Unicode made here are verified in test_casing.
    let search_bytes = to_search.as_bytes();
    if (search_for as u32) < 128 {
        // When searching for I or K, we pick out the first byte of the UTF-8
        // encoding of the corresponding special case character, and look for it
        // in the loop below.  For other characters we fall back to 0xff, which
        // is not a valid UTF-8 byte.
        let target = dubious_to_ascii_lower(search_for as u8);
        let special = if target == b'i' {
            0xc4u8
        } else if target == b'k' {
            0xe2u8
        } else {
            0xffu8
        };
        // Note: rustc doesn't do great at all on the more idiomatic
        // implementation of this (or below), but it does okay for this.
        let mut ci = 0;
        while ci < search_bytes.len() {
            let cur = search_bytes[ci];
            if dubious_to_ascii_lower(cur) == target || cur == special {
                return Some(ci);
            }
            ci += 1;
        }
    } else {
        let mut ci = 0;
        while ci < search_bytes.len() {
            let cur = search_bytes[ci];
            if (cur & 0x80) != 0 {
                return Some(ci);
            }
            ci += 1;
        }
    }
    None
}

#[inline(always)]
fn is_ascii_lower_alpha(c: u8) -> bool {
    // Equivalent to (but fewer operations than) `b'a' <= c && c <= b'z'`
    c.wrapping_sub(b'a') <= (b'z' - b'a')
}

/// port of isOnBoundary from gecko places.
///
/// > Check whether a character position is on a word boundary of a UTF-8 string
/// > (rather than within a word).  We define "within word" to be any position
/// > between [a-zA-Z] and [a-z] -- this lets us match CamelCase words.
/// > TODO: support non-latin alphabets.
#[inline(always)]
fn is_on_boundary(text: &str, index: usize) -> bool {
    if index == 0 {
        return true;
    }
    let bytes = text.as_bytes();
    if is_ascii_lower_alpha(bytes[index]) {
        let prev_lower = dubious_to_ascii_lower(bytes[index - 1]);
        !is_ascii_lower_alpha(prev_lower)
    } else {
        true
    }
}

/// Returns true if `source` starts with `token` ignoring case.
///
/// Loose port of stringMatch from places, which we've modified to perform more correct case
/// folding (if this turns out to be a perf issue we can always address it then).
#[inline]
fn string_match(token: &str, source: &str) -> bool {
    if source.len() < token.len() {
        return false;
    }
    let mut ti = token.chars().default_case_fold();
    let mut si = source.chars().default_case_fold();
    loop {
        match (ti.next(), si.next()) {
            (None, _) => return true,
            (Some(_), None) => return false,
            (Some(x), Some(y)) => {
                if x != y {
                    return false;
                }
            }
        }
    }
}

/// This performs single-codepoint case folding. It will do the wrong thing
/// for characters which have lowercase equivalents with multiple characters.
#[inline]
fn char_to_lower_single(c: char) -> char {
    c.to_lowercase().next().unwrap()
}

/// Read the next codepoint out of `s` and return it's lowercase variant, and the index of the
/// codepoint after it.
#[inline]
fn next_codepoint_lower(s: &str) -> (char, usize) {
    // This is super convoluted, and I wish a more direct way to do it was exposed. (In theory
    // this should be more efficient than this implementation is)
    let mut indices = s.char_indices();
    let (_, next_char) = indices.next().unwrap();
    let next_index = indices
        .next()
        .map(|(index, _)| index)
        .unwrap_or_else(|| s.len());
    (char_to_lower_single(next_char), next_index)
}

// Port of places `findInString`.
pub fn find_in_string(token: &str, src: &str, only_boundary: bool) -> bool {
    // Place's version has this restriction too
    assert!(!token.is_empty(), "Don't search for an empty string");
    if src.len() < token.len() {
        return false;
    }

    let token_first_char = next_codepoint_lower(token).0;
    // The C++ code is a big ol pointer party, and even indexes with negative numbers
    // in some places. We aren't quite this depraved, so we just use indices into slices.
    //
    // There's probably a higher cost to this than usual, and if we had more robust testing
    // (fuzzing, even) it might be worth measuring a version of this that avoids more of the
    // bounds checks.
    let mut cur_offset = 0;
    // Scan forward to the next viable candidate (if any).
    while let Some(src_idx) = next_search_candidate(&src[cur_offset..], token_first_char) {
        if cur_offset + src_idx >= src.len() {
            break;
        }
        cur_offset += src_idx;
        let src_cur = &src[cur_offset..];

        // Check whether the first character in the token matches the character
        // at src_cur. At the same time, get the index of the next character
        // in the source.
        let (src_next_char, next_offset_in_cur) = next_codepoint_lower(src_cur);

        // If it is the first character, and we either don't care about boundaries or
        // we're on one, do the more expensive string matching and return true if it hits.
        if src_next_char == token_first_char
            && (!only_boundary || is_on_boundary(src, cur_offset))
            && string_match(token, src_cur)
        {
            return true;
        }
        cur_offset += next_offset_in_cur;
    }
    false
}

// Search functions used as function pointers by AutocompleteMatch::Invoke

fn find_anywhere(token: &str, source: &str) -> bool {
    assert!(!token.is_empty(), "Don't search for an empty token");
    find_in_string(token, source, false)
}

fn find_on_boundary(token: &str, source: &str) -> bool {
    assert!(!token.is_empty(), "Don't search for an empty token");
    find_in_string(token, source, true)
}

fn find_beginning(token: &str, source: &str) -> bool {
    assert!(!token.is_empty(), "Don't search for an empty token");
    string_match(token, source)
}

fn find_beginning_case_sensitive(token: &str, source: &str) -> bool {
    assert!(!token.is_empty(), "Don't search for an empty token");
    source.starts_with(token)
}

// I can't wait for Rust 2018 when lifetime annotations are automatic.
pub struct AutocompleteMatch<'search, 'url, 'title, 'tags> {
    pub search_str: &'search str,
    pub url_str: &'url str,
    pub title_str: &'title str,
    pub tags: &'tags str,
    pub visit_count: u32,
    pub typed: bool,
    pub bookmarked: bool,
    pub open_page_count: u32,
    pub match_behavior: MatchBehavior,
    pub search_behavior: SearchBehavior,
}

impl<'search, 'url, 'title, 'tags> AutocompleteMatch<'search, 'url, 'title, 'tags> {
    fn get_search_fn(&self) -> fn(&str, &str) -> bool {
        match self.match_behavior {
            MatchBehavior::Anywhere | MatchBehavior::AnywhereUnmodified => find_anywhere,
            MatchBehavior::Beginning => find_beginning,
            MatchBehavior::BeginningCaseSensitive => find_beginning_case_sensitive,
            _ => find_on_boundary,
        }
    }

    fn fixup_url_str<'a>(&self, mut s: &'a str) -> Cow<'a, str> {
        if self.match_behavior != MatchBehavior::AnywhereUnmodified {
            if s.starts_with("http://") {
                s = &s[7..];
            } else if s.starts_with("https://") {
                s = &s[8..];
            } else if s.starts_with("ftp://") {
                s = &s[6..];
            }
        }
        // Bail out early if we don't need to percent decode. It's a
        // little weird that it's measurably faster to check this
        // separately, but whatever.
        if memchr::memchr(b'%', s.as_bytes()).is_none() {
            return Cow::Borrowed(s);
        }
        // TODO: would be nice to decode punycode here too, but for now
        // this is probably fine.
        match percent_encoding::percent_decode(s.as_bytes()).decode_utf8() {
            Err(_) => Cow::Borrowed(s),
            Ok(decoded) => decoded,
        }
    }

    #[inline]
    fn has_behavior(&self, behavior: SearchBehavior) -> bool {
        self.search_behavior.intersects(behavior)
    }

    pub fn invoke(&self) -> bool {
        // We only want to filter javascript: URLs if we are not supposed to search
        // for them, and the search does not start with "javascript:".
        if self.match_behavior == MatchBehavior::AnywhereUnmodified
            && self.url_str.starts_with("javascript:")
            && !self.has_behavior(SearchBehavior::JAVASCRIPT)
            && !self.search_str.starts_with("javascript:")
        {
            return false;
        }
        let matches = if self.has_behavior(SearchBehavior::RESTRICT) {
            (!self.has_behavior(SearchBehavior::HISTORY) || self.visit_count > 0)
                && (!self.has_behavior(SearchBehavior::TYPED) || self.typed)
                && (!self.has_behavior(SearchBehavior::BOOKMARK) || self.bookmarked)
                && (!self.has_behavior(SearchBehavior::TAG) || !self.tags.is_empty())
                && (!self.has_behavior(SearchBehavior::OPENPAGE) || self.open_page_count > 0)
        } else {
            (self.has_behavior(SearchBehavior::HISTORY) && self.visit_count > 0)
                || (self.has_behavior(SearchBehavior::TYPED) && self.typed)
                || (self.has_behavior(SearchBehavior::BOOKMARK) && self.bookmarked)
                || (self.has_behavior(SearchBehavior::TAG) && !self.tags.is_empty())
                || (self.has_behavior(SearchBehavior::OPENPAGE) && self.open_page_count > 0)
        };
        if !matches {
            return false;
        }
        let fixed_url = self.fixup_url_str(self.url_str);
        let search_fn = self.get_search_fn();

        let trimmed_url = util::slice_up_to(fixed_url.as_ref(), MAX_CHARS_TO_SEARCH_THROUGH);
        let trimmed_title = util::slice_up_to(self.title_str, MAX_CHARS_TO_SEARCH_THROUGH);
        for token in self.search_str.split_ascii_whitespace() {
            let matches = match (
                self.has_behavior(SearchBehavior::TITLE),
                self.has_behavior(SearchBehavior::URL),
            ) {
                (true, true) => {
                    (search_fn(token, trimmed_title) || search_fn(token, self.tags))
                        && search_fn(token, trimmed_url)
                }
                (true, false) => search_fn(token, trimmed_title) || search_fn(token, self.tags),
                (false, true) => search_fn(token, trimmed_url),
                (false, false) => {
                    search_fn(token, trimmed_url)
                        || search_fn(token, trimmed_title)
                        || search_fn(token, self.tags)
                }
            };
            if !matches {
                return false;
            }
        }
        true
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_is_ascii_lower_alpha() {
        // just check exhaustively
        for c in 0u8..=255u8 {
            assert_eq!(
                is_ascii_lower_alpha(c),
                b'a' <= c && c <= b'z',
                "is_lower_ascii_alpha is wrong for {}",
                c
            );
        }
    }

    // Test the various dubious things this code assumes about unicode / ascii text
    // in the name of performance. This is mostly a port of the test_casing gtests in places
    #[test]
    fn test_casing_assumptions() {
        use std::char;
        // Verify the assertion in next_search_candidate that the
        // only non-ASCII characters that lower-case to ASCII ones are:
        //  * U+0130 LATIN CAPITAL LETTER I WITH DOT ABOVE
        //  * U+212A KELVIN SIGN
        //
        // It also checks that U+0130 is the only single codepoint that lower cases
        // to multiple characters.
        for c in 128..0x11_0000 {
            if let Some(ch) = char::from_u32(c) {
                // Not quite the same (because codepoints aren't characters), but
                // should serve the same purpose.
                let mut li = ch.to_lowercase();
                let lc = li.next().unwrap();
                if c != 304 && c != 8490 {
                    assert!(
                        (lc as u32) >= 128,
                        "Lower case of non-ascii '{}' ({}) was unexpectedly ascii",
                        ch,
                        c
                    );
                    // This one we added (it's an implicit assumption in the utilities the
                    // places code uses).
                    assert!(
                        li.next().is_none(),
                        "Lower case of '{}' ({}) produced multiple codepoints unexpectedly",
                        ch,
                        c
                    );
                } else {
                    assert!(
                        (lc as u32) < 128,
                        "Lower case of non-ascii '{}' ({}) was unexpectedly not ascii",
                        ch,
                        c
                    );
                }
            }
        }

        // Verify the assertion that all ASCII characters lower-case to ASCII.
        for c in 0..128 {
            let ch = char::from_u32(c).unwrap();
            let mut li = ch.to_lowercase();
            let lc = li.next().unwrap();
            assert!(
                li.next().is_none() && (lc as u32) < 128,
                "Lower case of ascii '{}' ({}) wasn't ascii :(",
                ch,
                c
            );
        }

        for c in (b'a'..=b'z').chain(b'A'..=b'Z') {
            assert_eq!(
                dubious_to_ascii_lower(c),
                c.to_ascii_lowercase(),
                "c: '{}'",
                c as char
            );
        }
    }
}
