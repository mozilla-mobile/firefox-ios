/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::error::{ErrorKind, Result};
use std::path::{Path, PathBuf};
use url::Url;

/// Equivalent to `&s[..max_len.min(s.len())]`, but handles the case where
/// `s.is_char_boundary(max_len)` is false (which would otherwise panic).
pub fn slice_up_to(s: &str, max_len: usize) -> &str {
    if max_len >= s.len() {
        return s;
    }
    let mut idx = max_len;
    while !s.is_char_boundary(idx) {
        idx -= 1;
    }
    &s[..idx]
}

/// `Path` is basically just a `str` with no validation, and so in practice it
/// could contain a file URL. Rusqlite takes advantage of this a bit, and says
/// `AsRef<Path>` but really means "anything sqlite can take as an argument".
///
/// Swift loves using file urls (the only support it has for file manipulation
/// is through file urls), so it's handy to support them if possible.
fn unurl_path(p: impl AsRef<Path>) -> PathBuf {
    p.as_ref()
        .to_str()
        .and_then(|s| Url::parse(s).ok())
        .and_then(|u| {
            if u.scheme() == "file" {
                u.to_file_path().ok()
            } else {
                None
            }
        })
        .unwrap_or_else(|| p.as_ref().to_owned())
}

/// If `p` is a file URL, return it, otherwise try and make it one.
///
/// Errors if `p` is a relative non-url path, or if it's a URL path
/// that's isn't a `file:` URL.
pub fn ensure_url_path(p: impl AsRef<Path>) -> Result<Url> {
    if let Some(u) = p.as_ref().to_str().and_then(|s| Url::parse(s).ok()) {
        if u.scheme() == "file" {
            Ok(u)
        } else {
            Err(ErrorKind::IllegalDatabasePath(p.as_ref().to_owned()).into())
        }
    } else {
        let p = p.as_ref();
        let u = Url::from_file_path(p).map_err(|_| ErrorKind::IllegalDatabasePath(p.to_owned()))?;
        Ok(u)
    }
}

/// As best as possible, convert `p` into an absolute path, resolving
/// all symlinks along the way.
///
/// If `p` is a file url, it's converted to a path before this.
pub fn normalize_path(p: impl AsRef<Path>) -> Result<PathBuf> {
    let path = unurl_path(p);
    if let Ok(canonical) = path.canonicalize() {
        return Ok(canonical);
    }
    // It probably doesn't exist yet. This is an error, although it seems to
    // work on some systems.
    //
    // We resolve this by trying to canonicalize the parent directory, and
    // appending the requested file name onto that. If we can't canonicalize
    // the parent, we return an error.
    //
    // Also, we return errors if the path ends in "..", if there is no
    // parent directory, etc.
    let file_name = path
        .file_name()
        .ok_or_else(|| ErrorKind::IllegalDatabasePath(path.clone()))?;

    let parent = path
        .parent()
        .ok_or_else(|| ErrorKind::IllegalDatabasePath(path.clone()))?;

    let mut canonical = parent.canonicalize()?;
    canonical.push(file_name);
    Ok(canonical)
}

#[cfg(test)]
mod test {
    use super::*;
    #[test]
    fn test_slice_up_to() {
        assert_eq!(slice_up_to("abcde", 4), "abcd");
        assert_eq!(slice_up_to("abcde", 5), "abcde");
        assert_eq!(slice_up_to("abcde", 6), "abcde");
        let s = "abcd😀";
        assert_eq!(s.len(), 8);
        assert_eq!(slice_up_to(s, 4), "abcd");
        assert_eq!(slice_up_to(s, 5), "abcd");
        assert_eq!(slice_up_to(s, 6), "abcd");
        assert_eq!(slice_up_to(s, 7), "abcd");
        assert_eq!(slice_up_to(s, 8), s);
    }
    #[test]
    fn test_unurl_path() {
        assert_eq!(
            unurl_path("file:///foo%20bar/baz").to_string_lossy(),
            "/foo bar/baz"
        );
        assert_eq!(unurl_path("/foo bar/baz").to_string_lossy(), "/foo bar/baz");
        assert_eq!(unurl_path("../baz").to_string_lossy(), "../baz");
    }

    #[test]
    fn test_ensure_url() {
        assert_eq!(
            ensure_url_path("file:///foo%20bar/baz").unwrap().as_str(),
            "file:///foo%20bar/baz"
        );

        assert_eq!(
            ensure_url_path("/foo bar/baz").unwrap().as_str(),
            "file:///foo%20bar/baz"
        );

        assert!(ensure_url_path("bar").is_err());

        assert!(ensure_url_path("http://www.not-a-file.com").is_err());
    }
}
