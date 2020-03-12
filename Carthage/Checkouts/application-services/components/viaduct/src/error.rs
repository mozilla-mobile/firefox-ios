/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use failure::Fail;

#[derive(Debug, Fail)]
pub enum Error {
    #[fail(display = "Illegal characters in request header '{}'", _0)]
    RequestHeaderError(crate::HeaderName),

    #[fail(display = "Backend error: {}", _0)]
    BackendError(String),

    #[fail(display = "Network error: {}", _0)]
    NetworkError(String),

    #[fail(display = "The rust-components network backend must be initialized before use!")]
    BackendNotInitialized,

    /// Note: we return this if the server returns a bad URL with
    /// its response. This *probably* should never happen, but who knows.
    #[fail(display = "URL Parse Error: {}", _0)]
    UrlError(#[fail(cause)] url::ParseError),

    #[fail(display = "Validation error: URL does not use TLS protocol.")]
    NonTlsUrl,
}

impl From<url::ParseError> for Error {
    fn from(u: url::ParseError) -> Self {
        Error::UrlError(u)
    }
}

/// This error is returned as the `Err` result from
/// [`Response::require_success`].
///
/// Note that it's not a variant on `Error` to distinguish between errors
/// caused by the network, and errors returned from the server.
#[derive(failure::Fail, Debug, Clone, PartialEq)]
#[fail(display = "Error: {} {} returned {}", method, url, status)]
pub struct UnexpectedStatus {
    pub status: u16,
    pub method: crate::Method,
    pub url: url::Url,
}
