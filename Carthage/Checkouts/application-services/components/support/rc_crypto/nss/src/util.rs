/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::error::*;
use nss_sys::*;
use std::{convert::TryFrom, ffi::CString, os::raw::c_char, sync::Once};

static NSS_INIT: Once = Once::new();

pub fn ensure_nss_initialized() {
    NSS_INIT.call_once(|| {
        let version_ptr = CString::new(nss_sys::COMPATIBLE_NSS_VERSION).unwrap();
        if unsafe { NSS_VersionCheck(version_ptr.as_ptr()) == PR_FALSE } {
            panic!("Incompatible NSS version!")
        }
        let empty = CString::default();
        let flags = NSS_INIT_READONLY
            | NSS_INIT_NOCERTDB
            | NSS_INIT_NOMODDB
            | NSS_INIT_FORCEOPEN
            | NSS_INIT_OPTIMIZESPACE;
        let context = unsafe {
            NSS_InitContext(
                empty.as_ptr(),
                empty.as_ptr(),
                empty.as_ptr(),
                empty.as_ptr(),
                std::ptr::null_mut(),
                flags,
            )
        };
        if context.is_null() {
            let error = get_last_error();
            panic!("Could not initialize NSS: {}", error);
        }
    })
}

pub fn map_nss_secstatus<F>(callback: F) -> Result<()>
where
    F: FnOnce() -> SECStatus,
{
    if callback() == SECSuccess {
        return Ok(());
    }
    Err(get_last_error())
}

/// Retrieve and wrap the last NSS/NSPR error in the current thread.
#[cold]
pub fn get_last_error() -> Error {
    let error_code = unsafe { PR_GetError() };
    let error_text: String = usize::try_from(unsafe { PR_GetErrorTextLength() })
        .map(|error_text_len| {
            let mut out_str = vec![0u8; error_text_len + 1];
            unsafe { PR_GetErrorText(out_str.as_mut_ptr() as *mut c_char) };
            CString::new(&out_str[0..error_text_len])
                .unwrap_or_else(|_| CString::default())
                .to_str()
                .unwrap_or_else(|_| "")
                .to_owned()
        })
        .unwrap_or_else(|_| "".to_string());
    ErrorKind::NSSError(error_code, error_text).into()
}

pub(crate) trait ScopedPtr
where
    Self: std::marker::Sized,
{
    type RawType;
    unsafe fn from_ptr(ptr: *mut Self::RawType) -> Result<Self>;
    fn as_ptr(&self) -> *const Self::RawType;
    fn as_mut_ptr(&self) -> *mut Self::RawType;
}

// The macro defines a wrapper around pointers refering to types allocated by NSS,
// calling their NSS destructor method when they go out of scope to avoid memory leaks.
// The `as_ptr`/`as_mut_ptr` are provided to retrieve the raw pointers to pass to
// NSS functions that consume them.
#[macro_export]
macro_rules! scoped_ptr {
    ($scoped:ident, $target:ty, $dtor:path) => {
        pub struct $scoped {
            ptr: *mut $target,
        }

        impl crate::util::ScopedPtr for $scoped {
            type RawType = $target;

            #[allow(dead_code)]
            unsafe fn from_ptr(ptr: *mut $target) -> crate::error::Result<$scoped> {
                if !ptr.is_null() {
                    Ok($scoped { ptr: ptr })
                } else {
                    Err(crate::error::ErrorKind::InternalError.into())
                }
            }

            #[inline]
            fn as_ptr(&self) -> *const $target {
                self.ptr
            }

            #[inline]
            fn as_mut_ptr(&self) -> *mut $target {
                self.ptr
            }
        }

        impl Drop for $scoped {
            fn drop(&mut self) {
                assert!(!self.ptr.is_null());
                unsafe { $dtor(self.ptr) };
            }
        }
    };
}

pub(crate) unsafe fn sec_item_as_slice(sec_item: &mut SECItem) -> Result<&mut [u8]> {
    let sec_item_buf_len = usize::try_from(sec_item.len)?;
    let buf = std::slice::from_raw_parts_mut(sec_item.data, sec_item_buf_len);
    Ok(buf)
}
