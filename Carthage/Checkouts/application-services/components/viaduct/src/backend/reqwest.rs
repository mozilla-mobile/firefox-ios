/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::settings::GLOBAL_SETTINGS;
use std::io::Read;

// Note: we don't `use` things from reqwest or this crate because it
// would be rather confusing given that we have the same name for
// most things as them.

lazy_static::lazy_static! {
    static ref CLIENT: reqwest::blocking::Client = {
        let mut builder = reqwest::blocking::ClientBuilder::new()
            .timeout(GLOBAL_SETTINGS.read_timeout)
            .connect_timeout(GLOBAL_SETTINGS.connect_timeout)
            .redirect(
                if GLOBAL_SETTINGS.follow_redirects {
                    reqwest::redirect::Policy::default()
                } else {
                    reqwest::redirect::Policy::none()
                }
            );
            if cfg!(target_os = "ios") {
                // The FxA servers rely on the UA agent to filter
                // some push messages directed to iOS devices.
                // This is obviously a terrible hack and we should
                // probably do https://github.com/mozilla/application-services/issues/1326
                // instead, but this will unblock us for now.
                builder = builder.user_agent("Firefox-iOS-FxA/24");
            }
            // Note: no cookie or cache support.
            builder.build()
            .expect("Failed to initialize global reqwest::Client")
    };
}

// Implementing From to do this would end up being public
impl crate::Request {
    fn into_reqwest(self) -> Result<reqwest::blocking::Request, crate::Error> {
        let method = match self.method {
            crate::Method::Get => reqwest::Method::GET,
            crate::Method::Head => reqwest::Method::HEAD,
            crate::Method::Post => reqwest::Method::POST,
            crate::Method::Put => reqwest::Method::PUT,
            crate::Method::Delete => reqwest::Method::DELETE,
            crate::Method::Connect => reqwest::Method::CONNECT,
            crate::Method::Options => reqwest::Method::OPTIONS,
            crate::Method::Trace => reqwest::Method::TRACE,
        };
        let mut result = reqwest::blocking::Request::new(method, self.url);
        for h in self.headers {
            use reqwest::header::{HeaderName, HeaderValue};
            // Unwraps should be fine, we verify these in `Header`
            let value = HeaderValue::from_str(&h.value).unwrap();
            result
                .headers_mut()
                .insert(HeaderName::from_bytes(h.name.as_bytes()).unwrap(), value);
        }
        *result.body_mut() = self.body.map(reqwest::blocking::Body::from);
        Ok(result)
    }
}

pub fn send(request: crate::Request) -> Result<crate::Response, crate::Error> {
    super::note_backend("reqwest (untrusted)");
    let request_method = request.method;
    let req = request.into_reqwest()?;
    let mut resp = CLIENT.execute(req).map_err(|e| {
        log::error!("Reqwest error: {:?}", e);
        crate::Error::NetworkError(e.to_string())
    })?;
    let status = resp.status().as_u16();
    let url = resp.url().clone();
    let mut body = Vec::with_capacity(resp.content_length().unwrap_or_default() as usize);
    resp.read_to_end(&mut body).map_err(|e| {
        log::error!("Failed to get body from response: {:?}", e);
        crate::Error::NetworkError(e.to_string())
    })?;
    let mut headers = crate::Headers::with_capacity(resp.headers().len());
    for (k, v) in resp.headers() {
        let val = String::from_utf8_lossy(v.as_bytes()).to_string();
        let hname = match crate::HeaderName::new(k.as_str().to_owned()) {
            Ok(name) => name,
            Err(e) => {
                // Ignore headers with invalid names, since nobody can look for them anyway.
                log::warn!("Server sent back invalid header name: '{}'", e);
                continue;
            }
        };
        // Not using Header::new intentionally, since the error it returns is
        // for request headers.
        headers.insert_header(crate::Header {
            name: hname,
            value: val,
        });
    }
    Ok(crate::Response {
        request_method,
        body,
        url,
        status,
        headers,
    })
}

/// A dummy symbol we include so that we can detect whether or not the reqwest
/// backend got compiled in.
#[no_mangle]
pub extern "C" fn viaduct_detect_reqwest_backend() {
    ffi_support::abort_on_panic::call_with_output(|| {
        println!("Nothing to see here (reqwest backend available).");
    });
}
