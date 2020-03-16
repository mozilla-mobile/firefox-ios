/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![cfg(feature = "serde_support")]

use std::fmt;

use serde::{
    de::{self, Deserialize, Deserializer, Visitor},
    ser::{Serialize, Serializer},
};

use crate::Guid;

struct GuidVisitor;
impl<'de> Visitor<'de> for GuidVisitor {
    type Value = Guid;
    #[inline]
    fn expecting(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("a sync guid")
    }
    #[inline]
    fn visit_str<E: de::Error>(self, s: &str) -> Result<Self::Value, E> {
        Ok(Guid::from_slice(s.as_ref()))
    }
}

impl<'de> Deserialize<'de> for Guid {
    #[inline]
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        deserializer.deserialize_str(GuidVisitor)
    }
}

impl Serialize for Guid {
    #[inline]
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        serializer.serialize_str(self.as_str())
    }
}

#[cfg(test)]
mod test {
    use super::*;
    use serde_test::{assert_tokens, Token};
    #[test]
    fn test_ser_de() {
        let guid = Guid::from("asdffdsa12344321");
        assert_tokens(&guid, &[Token::Str("asdffdsa12344321")]);

        let guid = Guid::from("");
        assert_tokens(&guid, &[Token::Str("")]);

        let guid = Guid::from(&b"abcd43211234"[..]);
        assert_tokens(&guid, &[Token::Str("abcd43211234")]);
    }
}
