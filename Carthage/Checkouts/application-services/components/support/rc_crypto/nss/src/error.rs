/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use failure::Fail;

#[derive(Debug, Fail)]
pub enum ErrorKind {
    #[fail(display = "NSS could not be initialized")]
    NSSInitFailure,
    #[fail(display = "NSS error: {} {}", _0, _1)]
    NSSError(i32, String),
    #[fail(display = "Internal crypto error")]
    InternalError,
    #[fail(display = "Conversion error: {}", _0)]
    ConversionError(#[fail(cause)] std::num::TryFromIntError),
    #[fail(display = "Base64 decode error: {}", _0)]
    Base64Decode(#[fail(cause)] base64::DecodeError),
}

error_support::define_error! {
    ErrorKind {
        (Base64Decode, base64::DecodeError),
        (ConversionError, std::num::TryFromIntError),
    }
}
