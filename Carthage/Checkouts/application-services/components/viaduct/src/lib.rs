/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]

use url::Url;
#[macro_use]
mod headers;

mod backend;
pub mod error;
mod settings;
pub use error::*;

pub use backend::force_enable_ffi_backend;
pub use headers::{consts as header_names, Header, HeaderName, Headers, InvalidHeaderName};

pub(crate) mod msg_types {
    include!(concat!(env!("OUT_DIR"), "/msg_types.rs"));
}

/// HTTP Methods.
///
/// The supported methods are the limited to what's supported by android-components.
#[derive(Clone, Debug, Copy, PartialEq, PartialOrd, Eq, Ord, Hash)]
#[repr(u8)]
pub enum Method {
    Get,
    Head,
    Post,
    Put,
    Delete,
    Connect,
    Options,
    Trace,
}

impl Method {
    pub fn as_str(self) -> &'static str {
        match self {
            Method::Get => "GET",
            Method::Head => "HEAD",
            Method::Post => "POST",
            Method::Put => "PUT",
            Method::Delete => "DELETE",
            Method::Connect => "CONNECT",
            Method::Options => "OPTIONS",
            Method::Trace => "TRACE",
        }
    }
}

impl std::fmt::Display for Method {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(self.as_str())
    }
}

#[must_use = "`Request`'s \"builder\" functions take by move, not by `&mut self`"]
#[derive(Clone, Debug, PartialEq)]
pub struct Request {
    pub method: Method,
    pub url: Url,
    pub headers: Headers,
    pub body: Option<Vec<u8>>,
}

impl Request {
    /// Construct a new request to the given `url` using the given `method`.
    /// Note that the request is not made until `send()` is called.
    pub fn new(method: Method, url: Url) -> Self {
        Self {
            method,
            url,
            headers: Headers::new(),
            body: None,
        }
    }

    pub fn send(self) -> Result<Response, Error> {
        crate::backend::send(self)
    }

    /// Alias for `Request::new(Method::Get, url)`, for convenience.
    pub fn get(url: Url) -> Self {
        Self::new(Method::Get, url)
    }

    /// Alias for `Request::new(Method::Post, url)`, for convenience.
    pub fn post(url: Url) -> Self {
        Self::new(Method::Post, url)
    }

    /// Alias for `Request::new(Method::Put, url)`, for convenience.
    pub fn put(url: Url) -> Self {
        Self::new(Method::Put, url)
    }

    /// Alias for `Request::new(Method::Delete, url)`, for convenience.
    pub fn delete(url: Url) -> Self {
        Self::new(Method::Delete, url)
    }

    /// Append the provided query parameters to the URL
    ///
    /// ## Example
    /// ```
    /// # use viaduct::{Request, header_names};
    /// # use url::Url;
    /// let some_url = url::Url::parse("https://www.example.com/xyz").unwrap();
    ///
    /// let req = Request::post(some_url).query(&[("a", "1234"), ("b", "qwerty")]);
    /// assert_eq!(req.url.as_str(), "https://www.example.com/xyz?a=1234&b=qwerty");
    ///
    /// // This appends to the query query instead of replacing `a`.
    /// let req = req.query(&[("a", "5678")]);
    /// assert_eq!(req.url.as_str(), "https://www.example.com/xyz?a=1234&b=qwerty&a=5678");
    /// ```
    pub fn query(mut self, pairs: &[(&str, &str)]) -> Self {
        let mut append_to = self.url.query_pairs_mut();
        for (k, v) in pairs {
            append_to.append_pair(k, v);
        }
        drop(append_to);
        self
    }

    /// Set the query string of the URL. Note that `req.set_query(None)` will
    /// clear the query.
    ///
    /// See also `Request::query` which appends a slice of query pairs, which is
    /// typically more ergonomic when usable.
    ///
    /// ## Example
    /// ```
    /// # use viaduct::{Request, header_names};
    /// # use url::Url;
    /// let some_url = url::Url::parse("https://www.example.com/xyz").unwrap();
    ///
    /// let req = Request::post(some_url).set_query("a=b&c=d");
    /// assert_eq!(req.url.as_str(), "https://www.example.com/xyz?a=b&c=d");
    ///
    /// let req = req.set_query(None);
    /// assert_eq!(req.url.as_str(), "https://www.example.com/xyz");
    /// ```
    pub fn set_query<'a, Q: Into<Option<&'a str>>>(mut self, query: Q) -> Self {
        self.url.set_query(query.into());
        self
    }

    /// Add all the provided headers to the list of headers to send with this
    /// request.
    pub fn headers<I>(mut self, to_add: I) -> Self
    where
        I: IntoIterator<Item = Header>,
    {
        self.headers.extend(to_add);
        self
    }

    /// Add the provided header to the list of headers to send with this request.
    ///
    /// This returns `Err` if `val` contains characters that may not appear in
    /// the body of a header.
    ///
    /// ## Example
    /// ```
    /// # use viaduct::{Request, header_names};
    /// # use url::Url;
    /// # fn main() -> Result<(), viaduct::Error> {
    /// # let some_url = url::Url::parse("https://www.example.com").unwrap();
    /// Request::post(some_url)
    ///     .header(header_names::CONTENT_TYPE, "application/json")?
    ///     .header("My-Header", "Some special value")?;
    /// // ...
    /// # Ok(())
    /// # }
    /// ```
    pub fn header<Name, Val>(mut self, name: Name, val: Val) -> Result<Self, crate::Error>
    where
        Name: Into<HeaderName> + PartialEq<HeaderName>,
        Val: Into<String> + AsRef<str>,
    {
        self.headers.insert(name, val)?;
        Ok(self)
    }

    /// Set this request's body.
    pub fn body(mut self, body: impl Into<Vec<u8>>) -> Self {
        self.body = Some(body.into());
        self
    }

    /// Set body to the result of serializing `val`, and, unless it has already
    /// been set, set the Content-Type header to "application/json".
    ///
    /// Note: This panics if serde_json::to_vec fails. This can only happen
    /// in a couple cases:
    ///
    /// 1. Trying to serialize a map with non-string keys.
    /// 2. We wrote a custom serializer that fails.
    ///
    /// Neither of these are things we do. If they happen, it seems better for
    /// this to fail hard with an easy to track down panic, than for e.g. `sync`
    /// to fail with a JSON parse error (which we'd probably attribute to
    /// corrupt data on the server, or something).
    pub fn json<T: ?Sized + serde::Serialize>(mut self, val: &T) -> Self {
        self.body =
            Some(serde_json::to_vec(val).expect("Rust component bug: serde_json::to_vec failure"));
        self.headers
            .insert_if_missing(header_names::CONTENT_TYPE, "application/json")
            .unwrap(); // We know this has to be valid.
        self
    }
}

/// A response from the server.
#[derive(Clone, Debug, PartialEq)]
pub struct Response {
    /// The method used to request this response.
    pub request_method: Method,
    /// The URL of this response.
    pub url: Url,
    /// The HTTP Status code of this response.
    pub status: u16,
    /// The headers returned with this response.
    pub headers: Headers,
    /// The body of the response. Note that responses with binary bodies are
    /// currently unsupported.
    pub body: Vec<u8>,
}

impl Response {
    /// Parse the body as JSON.
    pub fn json<'a, T>(&'a self) -> Result<T, serde_json::Error>
    where
        T: serde::Deserialize<'a>,
    {
        serde_json::from_slice(&self.body)
    }

    /// Get the body as a string. Assumes UTF-8 encoding. Any non-utf8 bytes
    /// are replaced with the replacement character.
    pub fn text(&self) -> std::borrow::Cow<'_, str> {
        String::from_utf8_lossy(&self.body)
    }

    /// Returns true if the status code is in the interval `[200, 300)`.
    #[inline]
    pub fn is_success(&self) -> bool {
        status_codes::is_success_code(self.status)
    }

    /// Returns true if the status code is in the interval `[500, 600)`.
    #[inline]
    pub fn is_server_error(&self) -> bool {
        status_codes::is_server_error_code(self.status)
    }

    /// Returns true if the status code is in the interval `[400, 500)`.
    #[inline]
    pub fn is_client_error(&self) -> bool {
        status_codes::is_client_error_code(self.status)
    }

    /// Returns an [`UnexpectedStatus`] error if `self.is_success()` is false,
    /// otherwise returns `Ok(self)`.
    #[inline]
    pub fn require_success(self) -> Result<Self, UnexpectedStatus> {
        if self.is_success() {
            Ok(self)
        } else {
            Err(UnexpectedStatus {
                method: self.request_method,
                // XXX We probably should try and sanitize this. Replace the user id
                // if it's a sync token server URL, for example.
                url: self.url,
                status: self.status,
            })
        }
    }
}

/// A module containing constants for all HTTP status codes.
pub mod status_codes {

    /// Is it a 2xx status?
    #[inline]
    pub fn is_success_code(c: u16) -> bool {
        200 <= c && c < 300
    }

    /// Is it a 4xx error?
    #[inline]
    pub fn is_client_error_code(c: u16) -> bool {
        400 <= c && c < 500
    }

    /// Is it a 5xx error?
    #[inline]
    pub fn is_server_error_code(c: u16) -> bool {
        500 <= c && c < 600
    }

    macro_rules! define_status_codes {
        ($(($val:expr, $NAME:ident)),* $(,)?) => {
            $(pub const $NAME: u16 = $val;)*
        };
    }
    // From https://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
    define_status_codes![
        (100, CONTINUE),
        (101, SWITCHING_PROTOCOLS),
        // 2xx
        (200, OK),
        (201, CREATED),
        (202, ACCEPTED),
        (203, NONAUTHORITATIVE_INFORMATION),
        (204, NO_CONTENT),
        (205, RESET_CONTENT),
        (206, PARTIAL_CONTENT),
        // 3xx
        (300, MULTIPLE_CHOICES),
        (301, MOVED_PERMANENTLY),
        (302, FOUND),
        (303, SEE_OTHER),
        (304, NOT_MODIFIED),
        (305, USE_PROXY),
        // no 306
        (307, TEMPORARY_REDIRECT),
        // 4xx
        (400, BAD_REQUEST),
        (401, UNAUTHORIZED),
        (402, PAYMENT_REQUIRED),
        (403, FORBIDDEN),
        (404, NOT_FOUND),
        (405, METHOD_NOT_ALLOWED),
        (406, NOT_ACCEPTABLE),
        (407, PROXY_AUTHENTICATION_REQUIRED),
        (408, REQUEST_TIMEOUT),
        (409, CONFLICT),
        (410, GONE),
        (411, LENGTH_REQUIRED),
        (412, PRECONDITION_FAILED),
        (413, REQUEST_ENTITY_TOO_LARGE),
        (414, REQUEST_URI_TOO_LONG),
        (415, UNSUPPORTED_MEDIA_TYPE),
        (416, REQUESTED_RANGE_NOT_SATISFIABLE),
        (417, EXPECTATION_FAILED),
        // 5xx
        (500, INTERNAL_SERVER_ERROR),
        (501, NOT_IMPLEMENTED),
        (502, BAD_GATEWAY),
        (503, SERVICE_UNAVAILABLE),
        (504, GATEWAY_TIMEOUT),
        (505, HTTP_VERSION_NOT_SUPPORTED),
    ];
}
