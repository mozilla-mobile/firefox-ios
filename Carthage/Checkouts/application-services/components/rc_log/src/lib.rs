/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

//! This crate allows users from the other side of the FFI to hook into Rust's
//! `log` crate, which is used by us and several of our dependencies. The
//! primary use case is providing logs to Android and iOS in a way that is more
//! flexible than writing to liblog (which goes to logcat, which cannot be
//! accessed by programs on the device, short of rooting it), or stdout/stderr.
//!
//! See the header comment in android.rs and fallback.rs for details.
//!
//! It's worth noting that the log crate is rather inflexable, in that
//! it does not allow users to change loggers after the first initialization. We
//! work around this using our `settable_log` module.

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]
// We always include both modules when doing test builds, so for test builds,
// allow dead code.
#![cfg_attr(test, allow(dead_code))]

use std::ffi::CString;

// Import this in tests (even on non-android builds / cases where the
// force_android feature is not enabled) so we can check that it compiles
// easily.
#[cfg(any(test, os = "android", feature = "force_android"))]
pub mod android;
// Import this in tests (even if we're building for android or force_android is
// turned on) so we can check that it compiles easily
#[cfg(any(test, not(any(os = "android", feature = "force_android"))))]
pub mod ios;

mod settable_log;

cfg_if::cfg_if! {
    if #[cfg(any(os = "android", feature = "force_android"))] {
        use crate::android as imp;
    } else {
        use crate::ios as imp;
    }
}

pub(crate) fn string_to_cstring_lossy(s: String) -> CString {
    let mut bytes = s.into_bytes();
    for byte in bytes.iter_mut() {
        if *byte == 0 {
            *byte = b'?';
        }
    }
    CString::new(bytes).expect("Bug in string_to_cstring_lossy!")
}

#[derive(Clone, Copy)]
#[repr(i32)]
pub enum LogLevel {
    // Android logger levels
    VERBOSE = 2,
    DEBUG = 3,
    INFO = 4,
    WARN = 5,
    ERROR = 6,
}

impl From<log::Level> for LogLevel {
    fn from(l: log::Level) -> Self {
        match l {
            log::Level::Trace => LogLevel::VERBOSE,
            log::Level::Debug => LogLevel::DEBUG,
            log::Level::Info => LogLevel::INFO,
            log::Level::Warn => LogLevel::WARN,
            log::Level::Error => LogLevel::ERROR,
        }
    }
}

#[no_mangle]
pub extern "C" fn rc_log_adapter_create(
    callback: imp::LogCallback,
    out_err: &mut ffi_support::ExternError,
) -> *mut imp::LogAdapterState {
    ffi_support::call_with_output(out_err, || imp::LogAdapterState::init(callback))
}

// Note: keep in sync with LogLevelFilter in kotlin.
fn level_filter_from_i32(level_arg: i32) -> log::LevelFilter {
    match level_arg {
        4 => log::LevelFilter::Debug,
        3 => log::LevelFilter::Info,
        2 => log::LevelFilter::Warn,
        1 => log::LevelFilter::Error,
        // We clamp out of bounds level values.
        n if n <= 0 => log::LevelFilter::Off,
        n if n >= 5 => log::LevelFilter::Trace,
        _ => unreachable!("This is actually exhaustive"),
    }
}

#[no_mangle]
pub extern "C" fn rc_log_adapter_set_max_level(level: i32, out_err: &mut ffi_support::ExternError) {
    ffi_support::call_with_output(out_err, || log::set_max_level(level_filter_from_i32(level)))
}

// Can't use define_box_destructor because this can panic. TODO: Maybe we should
// keep this around globally (as lazy_static or something) and basically just
// turn it on/off in create/destroy... Might be more reliable?
#[no_mangle]
pub extern "C" fn rc_log_adapter_destroy(to_destroy: Option<Box<imp::LogAdapterState>>) {
    ffi_support::abort_on_panic::call_with_output(move || {
        log::set_max_level(log::LevelFilter::Off);
        drop(to_destroy);
        settable_log::unset_logger();
    })
}

// Used just to allow tests to produce logs.
#[no_mangle]
pub extern "C" fn rc_log_adapter_test__log_msg(msg: ffi_support::FfiStr<'_>) {
    ffi_support::abort_on_panic::call_with_output(|| {
        log::info!("testing: {}", msg.as_str());
    });
}

ffi_support::define_string_destructor!(rc_log_adapter_destroy_string);
