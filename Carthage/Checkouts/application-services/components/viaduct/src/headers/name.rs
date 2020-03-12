/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use std::borrow::Cow;

/// Represents a header name that we know to be both valid and lowercase.
/// Internally, this avoids allocating for headers that are constant strings,
/// like the predefined ones in this crate, however even without that
/// optimization, we would still likely have an equivalent of this for use
/// as a case-insensitive string guaranteed to only have valid characters.
#[derive(Debug, Clone, PartialEq, PartialOrd, Hash, Eq, Ord)]
pub struct HeaderName(pub(super) Cow<'static, str>);

/// Indicates an invalid header name. Note that we only emit
/// this for response headers, for request headers, we panic
/// instead. This is because it would likely come through as
/// a network error if we emitted it for local headers, when
/// it's actually a bug that we'd need to fix.
#[derive(failure::Fail, Debug, Clone, PartialEq)]
#[fail(display = "Invalid header name: {:?}", _0)]
pub struct InvalidHeaderName(Cow<'static, str>);

impl From<&'static str> for HeaderName {
    fn from(s: &'static str) -> HeaderName {
        match HeaderName::new(s) {
            Ok(v) => v,
            Err(e) => {
                panic!("Illegal locally specified header {}", e);
            }
        }
    }
}

impl From<String> for HeaderName {
    fn from(s: String) -> HeaderName {
        match HeaderName::new(s) {
            Ok(v) => v,
            Err(e) => {
                panic!("Illegal locally specified header {}", e);
            }
        }
    }
}

impl From<Cow<'static, str>> for HeaderName {
    fn from(s: Cow<'static, str>) -> HeaderName {
        match HeaderName::new(s) {
            Ok(v) => v,
            Err(e) => {
                panic!("Illegal locally specified header {}", e);
            }
        }
    }
}

impl InvalidHeaderName {
    pub fn name(&self) -> &str {
        &self.0[..]
    }
}

fn validate_header(mut name: Cow<'static, str>) -> Result<HeaderName, InvalidHeaderName> {
    if name.len() == 0 {
        return Err(invalid_header_name(name));
    }
    let mut need_lower_case = false;
    for b in name.bytes() {
        let validity = VALID_HEADER_LUT[b as usize];
        if validity == 0 {
            return Err(invalid_header_name(name));
        }
        if validity == 2 {
            need_lower_case = true;
        }
    }
    if need_lower_case {
        // Only do this if needed, since it causes us to own the header.
        name.to_mut().make_ascii_lowercase();
    }
    Ok(HeaderName(name))
}

impl HeaderName {
    /// Create a new header. In general you likely want to use `HeaderName::from(s)`
    /// instead for headers being specified locally (This will panic instead of
    /// returning a Result, since we have control over headers we specify locally,
    /// and want to know if we specify an illegal one).
    #[inline]
    pub fn new<S: Into<Cow<'static, str>>>(s: S) -> Result<Self, InvalidHeaderName> {
        validate_header(s.into())
    }

    #[inline]
    pub fn as_str(&self) -> &str {
        &self.0[..]
    }
}

impl std::fmt::Display for HeaderName {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(self.as_str())
    }
}

// Separate for dumb micro-optimization reasons.
#[cold]
#[inline(never)]
fn invalid_header_name(s: Cow<'static, str>) -> InvalidHeaderName {
    log::warn!("Invalid header name: {}", s);
    InvalidHeaderName(s)
}
// Note: 0 = invalid, 1 = valid, 2 = valid but needs lowercasing. I'd use an
// enum for this, but it would make this LUT *way* harder to look at. This
// includes 0-9, a-z, A-Z (as 2), and ('!' | '#' | '$' | '%' | '&' | '\'' | '*'
// | '+' | '-' | '.' | '^' | '_' | '`' | '|' | '~'), matching the field-name
// token production defined at https://tools.ietf.org/html/rfc7230#section-3.2.
static VALID_HEADER_LUT: [u8; 256] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0,
    0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
];

impl std::ops::Deref for HeaderName {
    type Target = str;
    #[inline]
    fn deref(&self) -> &str {
        self.as_str()
    }
}

impl AsRef<str> for HeaderName {
    #[inline]
    fn as_ref(&self) -> &str {
        self.as_str()
    }
}

impl AsRef<[u8]> for HeaderName {
    #[inline]
    fn as_ref(&self) -> &[u8] {
        self.as_str().as_bytes()
    }
}

impl From<HeaderName> for String {
    #[inline]
    fn from(h: HeaderName) -> Self {
        h.0.into()
    }
}

impl From<HeaderName> for Cow<'static, str> {
    #[inline]
    fn from(h: HeaderName) -> Self {
        h.0
    }
}

impl From<HeaderName> for Vec<u8> {
    #[inline]
    fn from(h: HeaderName) -> Self {
        String::from(h.0).into()
    }
}

macro_rules! partialeq_boilerplate {
    ($T0:ty, $T1:ty) => {
        impl<'a> PartialEq<$T0> for $T1 {
            fn eq(&self, other: &$T0) -> bool {
                // The &* should invoke Deref::deref if it exists, no-op otherwise.
                (&*self).eq_ignore_ascii_case(&*other)
            }
        }
        impl<'a> PartialEq<$T1> for $T0 {
            fn eq(&self, other: &$T1) -> bool {
                PartialEq::eq(other, self)
            }
        }
    };
}

partialeq_boilerplate!(HeaderName, str);
partialeq_boilerplate!(HeaderName, &'a str);
partialeq_boilerplate!(HeaderName, String);
partialeq_boilerplate!(HeaderName, &'a String);
partialeq_boilerplate!(HeaderName, Cow<'a, str>);

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_lut() {
        let mut expect = [0u8; 256];
        for b in b'0'..=b'9' {
            expect[b as usize] = 1;
        }
        for b in b'a'..=b'z' {
            expect[b as usize] = 1;
        }
        for b in b'A'..=b'Z' {
            expect[b as usize] = 2;
        }
        for b in b"!#$%&'*+-.^_`|~" {
            expect[*b as usize] = 1;
        }
        assert_eq!(&VALID_HEADER_LUT[..], &expect[..]);
    }
    #[test]
    fn test_validate() {
        assert!(validate_header("".into()).is_err());
        assert!(validate_header(" foo ".into()).is_err());
        assert!(validate_header("a=b".into()).is_err());
        assert_eq!(
            validate_header("content-type".into()),
            Ok(HeaderName("content-type".into()))
        );
        assert_eq!(
            validate_header("Content-Type".into()),
            Ok(HeaderName("content-type".into()))
        );
    }
}
