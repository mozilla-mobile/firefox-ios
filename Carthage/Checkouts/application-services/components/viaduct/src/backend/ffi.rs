/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::settings::GLOBAL_SETTINGS;
use crate::{msg_types, Error};
use ffi_support::{ByteBuffer, FfiStr};

ffi_support::implement_into_ffi_by_protobuf!(msg_types::Request);

impl From<crate::Request> for msg_types::Request {
    fn from(request: crate::Request) -> Self {
        msg_types::Request {
            url: request.url.into_string(),
            body: request.body,
            // Real weird that this needs to be specified as an i32, but
            // it certainly makes it convenient for us...
            method: request.method as i32,
            headers: request.headers.into(),
            follow_redirects: GLOBAL_SETTINGS.follow_redirects,
            include_cookies: GLOBAL_SETTINGS.include_cookies,
            use_caches: GLOBAL_SETTINGS.use_caches,
            connect_timeout_secs: GLOBAL_SETTINGS
                .connect_timeout
                .map_or(0, |d| d.as_secs() as i32),
            read_timeout_secs: GLOBAL_SETTINGS
                .read_timeout
                .map_or(0, |d| d.as_secs() as i32),
        }
    }
}

macro_rules! backend_error {
    ($($args:tt)*) => {{
        let msg = format!($($args)*);
        log::error!("{}", msg);
        Error::BackendError(msg)
    }};
}

pub fn send(request: crate::Request) -> Result<crate::Response, Error> {
    use ffi_support::IntoFfi;
    use prost::Message;
    super::note_backend("FFI (trusted)");

    let method = request.method;
    let fetch = callback_holder::get_callback().ok_or_else(|| Error::BackendNotInitialized)?;
    let proto_req: msg_types::Request = request.into();
    let buf = proto_req.into_ffi_value();
    let response = unsafe { fetch(buf) };
    // This way we'll Drop it if we panic, unlike if we just got a slice into
    // it. Besides, we already own it.
    let response_bytes = response.into_vec();

    let response: msg_types::Response = match Message::decode(response_bytes.as_slice()) {
        Ok(v) => v,
        Err(e) => {
            panic!(
                "Failed to parse protobuf returned from fetch callback! {}",
                e
            );
        }
    };

    if let Some(exn) = response.exception_message {
        log::error!(
            // Well, we caught *something* java wanted to tell us about, anyway.
            "Caught network error (presumably). Message: {:?}",
            exn
        );
        return Err(Error::NetworkError(format!("Java error: {:?}", exn)));
    }
    let status = response
        .status
        .ok_or_else(|| backend_error!("Missing HTTP status"))?;

    if status < 0 || status > i32::from(u16::max_value()) {
        return Err(backend_error!("Illegal HTTP status: {}", status));
    }

    let mut headers = crate::Headers::with_capacity(response.headers.len());
    for (name, val) in response.headers {
        let hname = match crate::HeaderName::new(name) {
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

    let url = url::Url::parse(
        &response
            .url
            .ok_or_else(|| backend_error!("Response has no URL"))?,
    )
    .map_err(|e| backend_error!("Response has illegal URL: {}", e))?;

    Ok(crate::Response {
        url,
        request_method: method,
        body: response.body.unwrap_or_default(),
        status: status as u16,
        headers,
    })
}

/// Type of the callback we need callers on the other side of the FFI to
/// provide.
///
/// Takes and returns a ffi_support::ByteBuffer. (TODO: it would be nice if we could
/// make this take/return pointers, so that we could use JNA direct mapping. Maybe
/// we need some kind of ThinBuffer?)
///
/// This is a bit weird, since it requires us to allow code on the other side of
/// the FFI to allocate a ByteBuffer from us, but it works.
///
/// The code on the other side of the FFI is responsible for freeing the ByteBuffer
/// it's passed using `viaduct_destroy_bytebuffer`.
type FetchCallback = unsafe extern "C" fn(ByteBuffer) -> ByteBuffer;

/// Module that manages get/set of the global fetch callback pointer.
mod callback_holder {
    use super::FetchCallback;
    use std::sync::atomic::{AtomicUsize, Ordering};

    /// Note: We only assign to this once.
    static CALLBACK_PTR: AtomicUsize = AtomicUsize::new(0);

    // Overly-paranoid sanity checking to ensure that these types are
    // convertible between each-other. `transmute` actually should check this for
    // us too, but this helps document the invariants we rely on in this code.
    //
    // Note that these are guaranteed by
    // https://rust-lang.github.io/unsafe-code-guidelines/layout/function-pointers.html
    // and thus this is a little paranoid.
    ffi_support::static_assert!(
        STATIC_ASSERT_USIZE_EQ_FUNC_SIZE,
        std::mem::size_of::<usize>() == std::mem::size_of::<FetchCallback>()
    );

    ffi_support::static_assert!(
        STATIC_ASSERT_USIZE_EQ_OPT_FUNC_SIZE,
        std::mem::size_of::<usize>() == std::mem::size_of::<Option<FetchCallback>>()
    );

    /// Get the function pointer to the FetchCallback. Panics if the callback
    /// has not yet been initialized.
    pub(super) fn get_callback() -> Option<FetchCallback> {
        let ptr_value = CALLBACK_PTR.load(Ordering::SeqCst);
        unsafe { std::mem::transmute::<usize, Option<FetchCallback>>(ptr_value) }
    }

    /// Set the function pointer to the FetchCallback. Returns false if we did nothing because the callback had already been initialized
    pub(super) fn set_callback(h: FetchCallback) -> bool {
        let as_usize = h as usize;
        let old_ptr = CALLBACK_PTR.compare_and_swap(0, as_usize, Ordering::SeqCst);
        if old_ptr != 0 {
            // This is an internal bug, the other side of the FFI should ensure
            // it sets this only once. Note that this is actually going to be
            // before logging is initialized in practice, so there's not a lot
            // we can actually do here.
            log::error!("Bug: Initialized CALLBACK_PTR multiple times");
        }
        old_ptr == 0
    }
}

/// Return a ByteBuffer of the requested size. This is used to store the
/// response from the callback.
#[no_mangle]
pub extern "C" fn viaduct_alloc_bytebuffer(sz: i32) -> ByteBuffer {
    let mut error = ffi_support::ExternError::default();
    let buffer =
        ffi_support::call_with_output(&mut error, || ByteBuffer::new_with_size(sz.max(0) as usize));
    error.consume_and_log_if_error();
    buffer
}

#[no_mangle]
pub extern "C" fn viaduct_log_error(s: FfiStr<'_>) {
    let mut error = ffi_support::ExternError::default();
    ffi_support::call_with_output(&mut error, || {
        log::error!("Viaduct Ffi Error: {}", s.as_str())
    });
    error.consume_and_log_if_error();
}

#[no_mangle]
pub extern "C" fn viaduct_initialize(callback: FetchCallback) -> u8 {
    ffi_support::abort_on_panic::call_with_output(|| callback_holder::set_callback(callback))
}

#[no_mangle]
pub extern "C" fn viaduct_force_enable_ffi_backend(v: u8) {
    ffi_support::abort_on_panic::call_with_output(|| super::force_enable_ffi_backend(v != 0));
}

ffi_support::define_bytebuffer_destructor!(viaduct_destroy_bytebuffer);
