/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use failure::Fail;

#[derive(Debug, Fail)]
pub enum ErrorKind {
    #[fail(display = "NSS error: {}", _0)]
    NSSError(#[fail(cause)] nss::Error),
    #[fail(display = "Internal crypto error")]
    InternalError,
    #[fail(display = "Conversion error: {}", _0)]
    ConversionError(#[fail(cause)] std::num::TryFromIntError),
}

error_support::define_error! {
    ErrorKind {
        (ConversionError, std::num::TryFromIntError),
        (NSSError, nss::Error),
    }
}
