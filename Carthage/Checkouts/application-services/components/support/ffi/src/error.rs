/* Copyright 2018-2019 Mozilla Foundation
 *
 * Licensed under the Apache License (Version 2.0), or the MIT license,
 * (the "Licenses") at your option. You may not use this file except in
 * compliance with one of the Licenses. You may obtain copies of the
 * Licenses at:
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *    http://opensource.org/licenses/MIT
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the Licenses is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the Licenses for the specific language governing permissions and
 * limitations under the Licenses. */

use crate::string::{destroy_c_string, rust_string_to_c};
use std::os::raw::c_char;
use std::{self, ptr};

/// Represents an error that occured within rust, storing both an error code, and additional data
/// that may be used by the caller.
///
/// Misuse of this type can cause numerous issues, so please read the entire documentation before
/// usage.
///
/// ## Rationale
///
/// This library encourages a pattern of taking a `&mut ExternError` as the final parameter for
/// functions exposed over the FFI. This is an "out parameter" which we use to write error/success
/// information that occurred during the function's execution.
///
/// To be clear, this means instances of `ExternError` will be created on the other side of the FFI,
/// and passed (by mutable reference) into Rust.
///
/// While this pattern is not particularly ergonomic in Rust (although hopefully this library
/// helps!), it offers two main benefits over something more ergonomic (which might be `Result`
/// shaped).
///
/// 1. It avoids defining a large number of `Result`-shaped types in the FFI consumer, as would
///    be required with something like an `struct ExternResult<T> { ok: *mut T, err:... }`
///
/// 2. It offers additional type safety over `struct ExternResult { ok: *mut c_void, err:... }`,
///    which helps avoid memory safety errors. It also can offer better performance for returning
///    primitives and repr(C) structs (no boxing required).
///
/// It also is less tricky to use properly than giving consumers a `get_last_error()` function, or
/// similar.
///
/// ## Caveats
///
/// Note that the order of the fields is `code` (an i32) then `message` (a `*mut c_char`), getting
/// this wrong on the other side of the FFI will cause memory corruption and crashes.
///
/// The fields are public largely for documentation purposes, but you should use
/// [`ExternError::new_error`] or [`ExternError::success`] to create these.
///
/// ## Layout/fields
///
/// This struct's field are not `pub` (mostly so that we can soundly implement `Send`, but also so
/// that we can verify rust users are constructing them appropriately), the fields, their types, and
/// their order are *very much* a part of the public API of this type. Consumers on the other side
/// of the FFI will need to know its layout.
///
/// If this were a C struct, it would look like
///
/// ```c,no_run
/// struct ExternError {
///     int32_t code;
///     char *message; // note: nullable
/// };
/// ```
///
/// In rust, there are two fields, in this order: `code: ErrorCode`, and `message: *mut c_char`.
/// Note that ErrorCode is a `#[repr(transparent)]` wrapper around an `i32`, so the first property
/// is equivalent to an `i32`.
///
/// #### The `code` field.
///
/// This is the error code, 0 represents success, all other values represent failure. If the `code`
/// field is nonzero, there should always be a message, and if it's zero, the message will always be
/// null.
///
/// #### The `message` field.
///
/// This is a null-terminated C string containing some amount of additional information about the
/// error. If the `code` property is nonzero, there should always be an error message. Otherwise,
/// this should will be null.
///
/// This string (when not null) is allocated on the rust heap (using this crate's
/// [`rust_string_to_c`]), and must be freed on it as well. Critically, if there are multiple rust
/// packages using being used in the same application, it *must be freed on the same heap that
/// allocated it*, or you will corrupt both heaps.
///
/// Typically, this object is managed on the other side of the FFI (on the "FFI consumer"), which
/// means you must expose a function to release the resources of `message` which can be done easily
/// using the [`define_string_destructor!`] macro provided by this crate.
///
/// If, for some reason, you need to release the resources directly, you may call
/// `ExternError::release()`. Note that you probably do not need to do this, and it's
/// intentional that this is not called automatically by implementing `drop`.
///
/// ## Example
///
/// ```rust,no_run
/// use ffi_support::{ExternError, ErrorCode};
///
/// #[derive(Debug)]
/// pub enum MyError {
///     IllegalFoo(String),
///     InvalidBar(i64),
///     // ...
/// }
///
/// // Putting these in a module is obviously optional, but it allows documentation, and helps
/// // avoid accidental reuse.
/// pub mod error_codes {
///     // note: -1 and 0 are reserved by ffi_support
///     pub const ILLEGAL_FOO: i32 = 1;
///     pub const INVALID_BAR: i32 = 2;
///     // ...
/// }
///
/// fn get_code(e: &MyError) -> ErrorCode {
///     match e {
///         MyError::IllegalFoo(_) => ErrorCode::new(error_codes::ILLEGAL_FOO),
///         MyError::InvalidBar(_) => ErrorCode::new(error_codes::INVALID_BAR),
///         // ...
///     }
/// }
///
/// impl From<MyError> for ExternError {
///     fn from(e: MyError) -> ExternError {
///         ExternError::new_error(get_code(&e), format!("{:?}", e))
///     }
/// }
/// ```
#[repr(C)]
// Note: We're intentionally not implementing Clone -- it's too risky.
#[derive(Debug, PartialEq)]
pub struct ExternError {
    // Don't reorder or add anything here!
    code: ErrorCode,
    message: *mut c_char,
}

impl std::panic::UnwindSafe for ExternError {}
impl std::panic::RefUnwindSafe for ExternError {}

/// This is sound so long as our fields are private.
unsafe impl Send for ExternError {}

impl ExternError {
    /// Construct an ExternError representing failure from a code and a message.
    #[inline]
    pub fn new_error(code: ErrorCode, message: impl Into<String>) -> Self {
        assert!(
            !code.is_success(),
            "Attempted to construct a success ExternError with a message"
        );
        Self {
            code,
            message: rust_string_to_c(message),
        }
    }

    /// Returns a ExternError representing a success. Also returned by ExternError::default()
    #[inline]
    pub fn success() -> Self {
        Self {
            code: ErrorCode::SUCCESS,
            message: ptr::null_mut(),
        }
    }

    /// Helper for the case where we aren't exposing this back over the FFI and
    /// we just want to warn if an error occurred and then release the allocated
    /// memory.
    ///
    /// Typically, this is done if the error will still be detected and reported
    /// by other channels.
    ///
    /// We assume we're not inside a catch_unwind, and so we wrap inside one
    /// ourselves.
    pub fn consume_and_log_if_error(self) {
        if !self.code.is_success() {
            // in practice this should never panic, but you never know...
            crate::abort_on_panic::call_with_output(|| {
                log::error!("Unhandled ExternError({:?}) {:?}", self.code, unsafe {
                    crate::FfiStr::from_raw(self.message)
                });
                unsafe {
                    self.manually_release();
                }
            })
        }
    }

    /// Get the `code` property.
    #[inline]
    pub fn get_code(&self) -> ErrorCode {
        self.code
    }

    /// Get the `message` property as a pointer to c_char.
    #[inline]
    pub fn get_raw_message(&self) -> *const c_char {
        self.message as *const _
    }

    /// Get the `message` property as an [`FfiStr`]
    #[inline]
    pub fn get_message(&self) -> crate::FfiStr<'_> {
        // Safe because the lifetime is the same as our lifetime.
        unsafe { crate::FfiStr::from_raw(self.get_raw_message()) }
    }

    /// Get the `message` property as a String, or None if this is not an error result.
    ///
    /// ## Safety
    ///
    /// You should only call this if you are certain that the other side of the FFI doesn't have a
    /// reference to this result (more specifically, to the `message` property) anywhere!
    #[inline]
    pub unsafe fn get_and_consume_message(self) -> Option<String> {
        if self.code.is_success() {
            None
        } else {
            let res = self.get_message().into_string();
            self.manually_release();
            Some(res)
        }
    }

    /// Manually release the memory behind this string. You probably don't want to call this.
    ///
    /// ## Safety
    ///
    /// You should only call this if you are certain that the other side of the FFI doesn't have a
    /// reference to this result (more specifically, to the `message` property) anywhere!
    pub unsafe fn manually_release(self) {
        if !self.message.is_null() {
            destroy_c_string(self.message)
        }
    }
}

impl Default for ExternError {
    #[inline]
    fn default() -> Self {
        ExternError::success()
    }
}

// This is the `Err` of std::thread::Result, which is what
// `panic::catch_unwind` returns.
impl From<Box<dyn std::any::Any + Send + 'static>> for ExternError {
    fn from(e: Box<dyn std::any::Any + Send + 'static>) -> Self {
        // The documentation suggests that it will *usually* be a str or String.
        let message = if let Some(s) = e.downcast_ref::<&'static str>() {
            (*s).to_string()
        } else if let Some(s) = e.downcast_ref::<String>() {
            s.clone()
        } else {
            "Unknown panic!".to_string()
        };
        log::error!("Caught a panic calling rust code: {:?}", message);
        ExternError::new_error(ErrorCode::PANIC, message)
    }
}

/// A wrapper around error codes, which is represented identically to an i32 on the other side of
/// the FFI. Essentially exists to check that we don't accidentally reuse success/panic codes for
/// other things.
#[repr(transparent)]
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Default)]
pub struct ErrorCode(i32);

impl ErrorCode {
    /// The ErrorCode used for success.
    pub const SUCCESS: ErrorCode = ErrorCode(0);

    /// The ErrorCode used for panics. It's unlikely you need to ever use this.
    // TODO: Consider moving to the reserved region...
    pub const PANIC: ErrorCode = ErrorCode(-1);

    /// The ErrorCode used for handle map errors.
    pub const INVALID_HANDLE: ErrorCode = ErrorCode(-1000);

    /// Construct an error code from an integer code.
    ///
    /// ## Panics
    ///
    /// Panics if you call it with 0 (reserved for success, but you can use `ErrorCode::SUCCESS` if
    /// that's what you want), or -1 (reserved for panics, but you can use `ErrorCode::PANIC` if
    /// that's what you want).
    pub fn new(code: i32) -> Self {
        assert!(code > ErrorCode::INVALID_HANDLE.0 && code != ErrorCode::PANIC.0 && code != ErrorCode::SUCCESS.0,
            "Error: The ErrorCodes `{success}`, `{panic}`, and all error codes less than or equal \
            to `{reserved}` are reserved (got {code}). You may use the associated constants on this \
            type (`ErrorCode::PANIC`, etc) if you'd like instances of those error codes.",
            panic = ErrorCode::PANIC.0,
            success = ErrorCode::SUCCESS.0,
            reserved = ErrorCode::INVALID_HANDLE.0,
            code = code,
        );

        ErrorCode(code)
    }

    /// Get the raw numeric value of this ErrorCode.
    #[inline]
    pub fn code(self) -> i32 {
        self.0
    }

    /// Returns whether or not this is a success code.
    #[inline]
    pub fn is_success(self) -> bool {
        self.code() == 0
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    #[should_panic]
    fn test_code_new_reserved_success() {
        ErrorCode::new(0);
    }

    #[test]
    #[should_panic]
    fn test_code_new_reserved_panic() {
        ErrorCode::new(-1);
    }

    #[test]
    #[should_panic]
    fn test_code_new_reserved_handle_error() {
        ErrorCode::new(-1000);
    }
    #[test]
    #[should_panic]
    fn test_code_new_reserved_unknown() {
        // Everything below -1000 should be reserved.
        ErrorCode::new(-1043);
    }

    #[test]
    fn test_code_new_allowed() {
        // Should not panic
        ErrorCode::new(-2);
    }

    #[test]
    fn test_code() {
        assert!(!ErrorCode::PANIC.is_success());
        assert!(!ErrorCode::INVALID_HANDLE.is_success());
        assert!(ErrorCode::SUCCESS.is_success());
        assert_eq!(ErrorCode::default(), ErrorCode::SUCCESS);
    }
}
