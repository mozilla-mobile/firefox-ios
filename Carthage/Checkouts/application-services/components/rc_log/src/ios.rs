/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::LogLevel;
use std::ffi::CString;
use std::os::raw::c_char;
use std::sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
};

/// Type of the log callback provided to us by swift. Takes the following
/// arguments:
///
/// - Log level (an i32).
///
/// - Tag: a (nullable) nul terminated c string. The callback must not free this
///   string, which is only valid until the the callback returns. If you need
///   it past that, you must copy it into an internal buffer!
///
/// - Message: a (non-nullable) nul terminated c string. The callback must not free this
///   string, which is only valid until the the callback returns. If you need
///   it past that, you must copy it into an internal buffer!
///
/// This is equivalent to the callback java uses **except** it cannot return 1/0
/// for disabling. Instead, the swift bindings allow calling disable from the
/// callback (which is more difficult for the java bindings).
pub type LogCallback = unsafe extern "C" fn(i32, *const c_char, *const c_char);

pub struct LogAdapterState {
    stop: Arc<AtomicBool>,
}

struct Logger {
    callback: LogCallback,
    stop: Arc<AtomicBool>,
}

impl log::Log for Logger {
    fn enabled(&self, _metadata: &log::Metadata<'_>) -> bool {
        !self.stop.load(Ordering::SeqCst)
    }

    fn flush(&self) {}
    fn log(&self, record: &log::Record<'_>) {
        if self.stop.load(Ordering::SeqCst) {
            // Note: `enabled` is not automatically called.
            return;
        }
        let tag = record
            .module_path()
            .and_then(|mp| CString::new(mp.as_bytes()).ok());

        // TODO: use SmallVec<[u8; 4096]> or something?
        let msg_str = crate::string_to_cstring_lossy(format!("{}", record.args()));

        let tag_ptr = tag
            .as_ref()
            .map(|s| s.as_ptr())
            .unwrap_or_else(std::ptr::null);
        let msg_ptr = msg_str.as_ptr() as *const c_char;

        let level: LogLevel = record.level().into();

        unsafe { (self.callback)(level as i32, tag_ptr, msg_ptr) };
    }
}

impl LogAdapterState {
    pub fn init(callback: LogCallback) -> Self {
        let stop = Arc::new(AtomicBool::new(false));
        let log = Logger {
            callback,
            stop: stop.clone(),
        };
        crate::settable_log::set_logger(Box::new(log));
        log::set_max_level(log::LevelFilter::Debug);
        log::info!("rc_log adapter initialized!");
        Self { stop }
    }
}

impl Drop for LogAdapterState {
    fn drop(&mut self) {
        self.stop.store(true, Ordering::SeqCst);
    }
}

ffi_support::implement_into_ffi_by_pointer!(LogAdapterState);
