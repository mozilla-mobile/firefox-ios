/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
use crate::{JsonObject, JsonValue};
use std::io::{Error as IoError, ErrorKind as IoErrorKind, Result as IoResult, Write};
/// For use with `#[serde(skip_serializing_if = )]`
#[inline]
pub fn is_default<T: PartialEq + Default>(v: &T) -> bool {
    *v == T::default()
}

/// Returns true if the byte `b` is a valid base64url byte.
#[inline]
#[rustfmt::skip]
pub fn is_base64url_byte(b: u8) -> bool {
    // For some reason, if this is indented the way rustfmt wants,
    // the next time this file is opened, VSCode deduces it *must*
    // actually use 8 space indent, and converts the whole file on
    // save. This is a VSCode bug, but is really annoying, so I'm
    // just preventing rustfmt from reformatting this to avoid it.
    (b'A' <= b && b <= b'Z') ||
    (b'a' <= b && b <= b'z') ||
    (b'0' <= b && b <= b'9') ||
    b == b'-' ||
    b == b'_'
}

/// Return with the provided Err(error) after invoking Into conversions
///
/// Essentially equivalent to explicitly writing `Err(e)?`, but logs the error,
/// and is more well-behaved from a type-checking perspective.
macro_rules! throw {
    ($e:expr $(,)?) => {{
        let e = $e;
        log::error!("Error: {}", e);
        return Err(std::convert::Into::into(e));
    }};
}

/// Like assert! but with `throw!` and not `panic!`.
///
/// Equivalent to explicitly writing `if !cond { throw!(e) }`, but logs what the
/// failed condition was (at warning levels).
macro_rules! ensure {
    ($cond:expr, $e:expr $(,)?) => {
        if !($cond) {
            log::warn!(concat!("Ensure ", stringify!($cond), " failed!"));
            throw!($e)
        }
    };
}

/// Like `serde_json::json!` but produces a `JsonObject` (aka a
/// `serde_json::Map<String, serde_json::Value>`).
#[cfg(test)]
macro_rules! json_obj {
    ($($toks:tt)*) => {
        match serde_json::json!($($toks)*) {
            serde_json::Value::Object(o) => o,
            _ => panic!("bad arg to json_obj!"),
        }
    };
}

pub(crate) fn into_obj(v: JsonValue) -> crate::Result<JsonObject, crate::InvalidRecord> {
    match v {
        JsonValue::Object(o) => Ok(o),
        x => {
            log::error!("Expected json object");
            log::trace!("   Got: {:?}", x);
            Err(crate::InvalidRecord::NotJsonObject)
        }
    }
}

/// Helper to allow passing a std::fmt::Formatter to a function needing
/// std::io::Write.
///
/// Mainly used to implement std::fmt::Display for the Record types without
/// requiring cloning them (which would be needed because serde_json::Value is
/// the one that impls Display, not serde_json::Map, aka JsonObject).
///
/// Alternatively we could have done `serde_json::to_string(self).unwrap()` or
/// something, but this this is cleaner.
pub struct FormatWriter<'a, 'b>(pub &'a mut std::fmt::Formatter<'b>);

impl<'a, 'b> Write for FormatWriter<'a, 'b> {
    fn write(&mut self, buf: &[u8]) -> IoResult<usize> {
        std::str::from_utf8(buf)
            .ok()
            .and_then(|s| self.0.write_str(s).ok())
            .ok_or_else(|| IoError::new(IoErrorKind::Other, std::fmt::Error))?;
        Ok(buf.len())
    }

    fn flush(&mut self) -> IoResult<()> {
        Ok(())
    }
}
