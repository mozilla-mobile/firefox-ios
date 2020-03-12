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

#![deny(missing_docs)]
#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]

//! # FFI Support
//!
//! This crate implements a support library to simplify implementing the patterns that the
//! `mozilla/application-services` repository uses for it's "Rust Component" FFI libraries.
//!
//! It is *strongly encouraged* that anybody writing FFI code in this repository read this
//! documentation before doing so, as it is a subtle, difficult, and error prone process.
//!
//! ## Terminology
//!
//! For each library, there are currently three parts we're concerned with. There's no clear correct
//! name for these, so this documentation will attempt to use the following terminology:
//!
//! - **Rust Component**: A Rust crate which does not expose an FFI directly, but may be may be
//!   wrapped by one that does. These have a `crate-type` in their Cargo.toml (see
//!   https://doc.rust-lang.org/reference/linkage.html) of `lib`, and not `staticlib` or `cdylib`
//!   (Note that `lib` is the default if `crate-type` is not specified). Examples include the
//!   `fxa-client`, and `logins` crates.
//!
//! - **FFI Component**: A wrapper crate that takes a Rust component, and exposes an FFI from it.
//!   These typically have `ffi` in the name, and have `crate-type = ["lib", "staticlib", "cdylib"]`
//!   in their Cargo.toml. For example, the `fxa-client/ffi` and `logins/ffi` crates (note:
//!   paths are subject to change). When built, these produce a native library that is consumed by
//!   the "FFI Consumer".
//!
//! - **FFI Consumer**: This is a low level library, typically implemented in Kotlin (for Android)
//!   or Swift (for iOS), that exposes a memory-safe wrapper around the memory-unsafe C API produced
//!   by the FFI component. It's expected that the maintainers of the FFI Component and FFI Consumer
//!   be the same (or at least, the author of the consumer should be completely comfortable with the
//!   API exposed by, and code in the FFI component), since the code in these is extremely tightly
//!   coupled, and very easy to get wrong.
//!
//! Note that while there are three parts, there may be more than three libraries relevant here, for
//! example there may be more than one FFI consumer (one for Android, one for iOS).
//!
//! ## Usage
//!
//! This library will typically be used in both the Rust component, and the FFI component, however
//! it frequently will be an optional dependency in the Rust component that's only available when a
//! feature flag (which the FFI component will always require) is used.
//!
//! The reason it's required inside the Rust component (and not solely in the FFI component, which
//! would be nice), is so that types provided by that crate may implement the traits provided by
//! this crate (this is because Rust does not allow crate `C` to implement a trait defined in crate
//! `A` for a type defined in crate `B`).
//!
//! In general, examples should be provided for the most important types and functions
//! ([`call_with_result`], [`IntoFfi`],
//! [`ExternError`], etc), but you should also look at the code of
//! consumers of this library.
//!
//! ### Usage in the Rust Component
//!
//! Inside the Rust component, you will implement:
//!
//! 1. [`IntoFfi`] for all types defined in that crate that you want to return
//!    over the FFI. For most common cases, the [`implement_into_ffi_by_json!`] and
//!    [`implement_into_ffi_by_protobuf!`] macros will do the job here, however you
//!    can see that trait's documentation for discussion and examples of
//!    implementing it manually.
//!
//! 2. Conversion to [`ExternError`] for the error type(s) exposed by that
//!    rust component, that is, `impl From<MyError> for ExternError`.
//!
//! ### Usage in the FFI Component
//!
//! Inside the FFI component, you will use this library in a few ways:
//!
//! 1. Destructors will be exposed for each types that had [`implement_into_ffi_by_pointer!`] called
//!    on it (using [`define_box_destructor!`]), and a destructor for strings should be exposed as
//!    well, using [`define_string_destructor`]
//!
//! 2. The body of every / nearly every FFI function will be wrapped in either a
//!    [`call_with_result`] or [`call_with_output`].
//!
//!    This is required because if we `panic!` (e.g. from an `assert!`, `unwrap()`, `expect()`, from
//!    indexing past the end of an array, etc) across the FFI boundary, the behavior is undefined
//!    and in practice very weird things tend to happen (we aren't caught by the caller, since they
//!    don't have the same exception behavior as us).
//!
//!    If you don't think your program (or possibly just certain calls) can handle panics, you may
//!    also use the versions of these functions in the [`abort_on_panic`] module, which
//!    do as their name suggest.
//!
//! Additionally, c strings that are passed in as arguments may be represented using [`FfiStr`],
//! which contains several helpful inherent methods for extracting their data.
//!

use std::{panic, thread};

mod error;
mod ffistr;
pub mod handle_map;
mod into_ffi;
#[macro_use]
mod macros;
mod string;

pub use crate::error::*;
pub use crate::ffistr::FfiStr;
pub use crate::into_ffi::*;
pub use crate::macros::*;
pub use crate::string::*;

// We export most of the types from this, but some constants
// (MAX_CAPACITY) don't make sense at the top level.
pub use crate::handle_map::{ConcurrentHandleMap, Handle, HandleError, HandleMap};

/// Call a callback that returns a `Result<T, E>` while:
///
/// - Catching panics, and reporting them to C via [`ExternError`].
/// - Converting `T` to a C-compatible type using [`IntoFfi`].
/// - Converting `E` to a C-compatible error via `Into<ExternError>`.
///
/// This (or [`call_with_output`]) should be in the majority of the FFI functions, see the crate
/// top-level docs for more info.
///
/// If your function doesn't produce an error, you may use [`call_with_output`] instead, which
/// doesn't require you return a Result.
///
/// ## Example
///
/// A few points about the following example:
///
/// - We need to mark it as `#[no_mangle] pub extern "C"`.
///
/// - We prefix it with a unique name for the library (e.g. `mylib_`). Foreign functions are not
///   namespaced, and symbol collisions can cause a large number of problems and subtle bugs,
///   including memory safety issues in some cases.
///
/// ```rust,no_run
/// # use ffi_support::{ExternError, ErrorCode, FfiStr};
/// # use std::os::raw::c_char;
///
/// # #[derive(Debug)]
/// # struct BadEmptyString;
/// # impl From<BadEmptyString> for ExternError {
/// #     fn from(e: BadEmptyString) -> Self {
/// #         ExternError::new_error(ErrorCode::new(1), "Bad empty string")
/// #     }
/// # }
///
/// #[no_mangle]
/// pub extern "C" fn mylib_print_string(
///     // Strings come in as an `FfiStr`, which is a wrapper around a null terminated C string.
///     thing_to_print: FfiStr<'_>,
///     // Note that taking `&mut T` and `&T` is both allowed and encouraged, so long as `T: Sized`,
///     // (e.g. it can't be a trait object, `&[T]`, a `&str`, etc). Also note that `Option<&T>` and
///     // `Option<&mut T>` are also allowed, if you expect the caller to sometimes pass in null, but
///     // that's the only case when it's currently to use `Option` in an argument list like this).
///     error: &mut ExternError
/// ) {
///     // You should try to to do as little as possible outside the call_with_result,
///     // to avoid a case where a panic occurs.
///     ffi_support::call_with_result(error, || {
///         let s = thing_to_print.as_str();
///         if s.is_empty() {
///             // This is a silly example!
///             return Err(BadEmptyString);
///         }
///         println!("{}", s);
///         Ok(())
///     })
/// }
/// ```
pub fn call_with_result<R, E, F>(out_error: &mut ExternError, callback: F) -> R::Value
where
    F: panic::UnwindSafe + FnOnce() -> Result<R, E>,
    E: Into<ExternError>,
    R: IntoFfi,
{
    call_with_result_impl(out_error, callback)
}

/// Call a callback that returns a `T` while:
///
/// - Catching panics, and reporting them to C via [`ExternError`]
/// - Converting `T` to a C-compatible type using [`IntoFfi`]
///
/// Note that you still need to provide an [`ExternError`] to this function, to report panics.
///
/// See [`call_with_result`] if you'd like to return a `Result<T, E>` (Note: `E` must
/// be convertible to [`ExternError`]).
///
/// This (or [`call_with_result`]) should be in the majority of the FFI functions, see
/// the crate top-level docs for more info.
pub fn call_with_output<R, F>(out_error: &mut ExternError, callback: F) -> R::Value
where
    F: panic::UnwindSafe + FnOnce() -> R,
    R: IntoFfi,
{
    // We need something that's `Into<ExternError>`, even though we never return it, so just use
    // `ExternError` itself.
    call_with_result(out_error, || -> Result<_, ExternError> { Ok(callback()) })
}

fn call_with_result_impl<R, E, F>(out_error: &mut ExternError, callback: F) -> R::Value
where
    F: panic::UnwindSafe + FnOnce() -> Result<R, E>,
    E: Into<ExternError>,
    R: IntoFfi,
{
    *out_error = ExternError::success();
    let res: thread::Result<(ExternError, R::Value)> = panic::catch_unwind(|| {
        init_panic_handling_once();
        match callback() {
            Ok(v) => (ExternError::default(), v.into_ffi_value()),
            Err(e) => (e.into(), R::ffi_default()),
        }
    });
    match res {
        Ok((err, o)) => {
            *out_error = err;
            o
        }
        Err(e) => {
            *out_error = e.into();
            R::ffi_default()
        }
    }
}

/// This module exists just to expose a variant of [`call_with_result`] and [`call_with_output`]
/// that aborts, instead of unwinding, on panic.
pub mod abort_on_panic {
    use super::*;

    // Struct that exists to automatically process::abort if we don't call
    // `std::mem::forget()` on it. This can have substantial performance
    // benefits over calling `std::panic::catch_unwind` and aborting if a panic
    // was caught, in addition to not requiring AssertUnwindSafe (for example).
    struct AbortOnDrop;
    impl Drop for AbortOnDrop {
        fn drop(&mut self) {
            std::process::abort();
        }
    }

    /// A helper function useful for cases where you'd like to abort on panic,
    /// but aren't in a position where you'd like to return an FFI-compatible
    /// type.
    #[inline]
    pub fn with_abort_on_panic<R, F>(callback: F) -> R
    where
        F: FnOnce() -> R,
    {
        let aborter = AbortOnDrop;
        let res = callback();
        std::mem::forget(aborter);
        res
    }

    /// Same as the root `call_with_result`, but aborts on panic instead of unwinding. See the
    /// `call_with_result` documentation for more.
    pub fn call_with_result<R, E, F>(out_error: &mut ExternError, callback: F) -> R::Value
    where
        F: FnOnce() -> Result<R, E>,
        E: Into<ExternError>,
        R: IntoFfi,
    {
        with_abort_on_panic(|| match callback() {
            Ok(v) => {
                *out_error = ExternError::default();
                v.into_ffi_value()
            }
            Err(e) => {
                *out_error = e.into();
                R::ffi_default()
            }
        })
    }

    /// Same as the root `call_with_output`, but aborts on panic instead of unwinding. As a result,
    /// it doesn't require a [`ExternError`] out argument. See the `call_with_output` documentation
    /// for more info.
    pub fn call_with_output<R, F>(callback: F) -> R::Value
    where
        F: FnOnce() -> R,
        R: IntoFfi,
    {
        with_abort_on_panic(callback).into_ffi_value()
    }
}

#[cfg(feature = "log_panics")]
fn init_panic_handling_once() {
    use std::sync::Once;
    static INIT_BACKTRACES: Once = Once::new();
    INIT_BACKTRACES.call_once(move || {
        #[cfg(all(feature = "log_backtraces", not(target_os = "android")))]
        {
            std::env::set_var("RUST_BACKTRACE", "1");
        }
        // Turn on a panic hook which logs both backtraces and the panic
        // "Location" (file/line). We do both in case we've been stripped,
        // ).
        std::panic::set_hook(Box::new(move |panic_info| {
            let (file, line) = if let Some(loc) = panic_info.location() {
                (loc.file(), loc.line())
            } else {
                // Apparently this won't happen but rust has reserved the
                // ability to start returning None from location in some cases
                // in the future.
                ("<unknown>", 0)
            };
            log::error!("### Rust `panic!` hit at file '{}', line {}", file, line);
            #[cfg(all(feature = "log_backtraces", not(target_os = "android")))]
            {
                log::error!("  Complete stack trace:\n{:?}", backtrace::Backtrace::new());
            }
        }));
    });
}

#[cfg(not(feature = "log_panics"))]
fn init_panic_handling_once() {}

/// ByteBuffer is a struct that represents an array of bytes to be sent over the FFI boundaries.
/// There are several cases when you might want to use this, but the primary one for us
/// is for returning protobuf-encoded data to Swift and Java. The type is currently rather
/// limited (implementing almost no functionality), however in the future it may be
/// more expanded.
///
/// ## Caveats
///
/// Note that the order of the fields is `len` (an i64) then `data` (a `*mut u8`), getting
/// this wrong on the other side of the FFI will cause memory corruption and crashes.
/// `i64` is used for the length instead of `u64` and `usize` because JNA has interop
/// issues with both these types.
///
/// ByteBuffer does not implement Drop. This is intentional. Memory passed into it will
/// be leaked if it is not explicitly destroyed by calling [`ByteBuffer::destroy`]. This
/// is because in the future, we may allow it's use for passing data into Rust code.
/// ByteBuffer assuming ownership of the data would make this a problem.
///
/// Note that alling `destroy` manually is not typically needed or recommended,
/// and instead you should use [`define_bytebuffer_destructor!`].
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
/// struct ByteBuffer {
///     int64_t len;
///     uint8_t *data; // note: nullable
/// };
/// ```
///
/// In rust, there are two fields, in this order: `len: i64`, and `data: *mut u8`.
///
/// ### Description of fields
///
/// `data` is a pointer to an array of `len` bytes. Not that data can be a null pointer and therefore
/// should be checked.
///
/// The bytes array is allocated on the heap and must be freed on it as well. Critically, if there
/// are multiple rust packages using being used in the same application, it *must be freed on the
/// same heap that allocated it*, or you will corrupt both heaps.
///
/// Typically, this object is managed on the other side of the FFI (on the "FFI consumer"), which
/// means you must expose a function to release the resources of `data` which can be done easily
/// using the [`define_bytebuffer_destructor!`] macro provided by this crate.
#[repr(C)]
pub struct ByteBuffer {
    len: i64,
    data: *mut u8,
}

impl From<Vec<u8>> for ByteBuffer {
    #[inline]
    fn from(bytes: Vec<u8>) -> Self {
        Self::from_vec(bytes)
    }
}

impl ByteBuffer {
    /// Creates a `ByteBuffer` of the requested size, zero-filled.
    ///
    /// The contents of the vector will not be dropped. Instead, `destroy` must
    /// be called later to reclaim this memory or it will be leaked.
    ///
    /// ## Caveats
    ///
    /// This will panic if the buffer length (`usize`) cannot fit into a `i64`.
    #[inline]
    pub fn new_with_size(size: usize) -> Self {
        let mut buf = vec![];
        buf.reserve_exact(size);
        buf.resize(size, 0);
        ByteBuffer::from_vec(buf)
    }

    /// Creates a `ByteBuffer` instance from a `Vec` instance.
    ///
    /// The contents of the vector will not be dropped. Instead, `destroy` must
    /// be called later to reclaim this memory or it will be leaked.
    ///
    /// ## Caveats
    ///
    /// This will panic if the buffer length (`usize`) cannot fit into a `i64`.
    #[inline]
    pub fn from_vec(bytes: Vec<u8>) -> Self {
        use std::convert::TryFrom;
        let mut buf = bytes.into_boxed_slice();
        let data = buf.as_mut_ptr();
        let len = i64::try_from(buf.len()).expect("buffer length cannot fit into a i64.");
        std::mem::forget(buf);
        Self { data, len }
    }

    /// Convert this `ByteBuffer` into a Vec<u8>. This is the only way
    /// to access the data from inside the buffer.
    #[inline]
    pub fn into_vec(self) -> Vec<u8> {
        if self.data.is_null() {
            vec![]
        } else {
            // This is correct because we convert to a Box<[u8]> first, which is
            // a design constraint of RawVec.
            unsafe { Vec::from_raw_parts(self.data, self.len as usize, self.len as usize) }
        }
    }

    /// Reclaim memory stored in this ByteBuffer.
    ///
    /// You typically should not call this manually, and instead expose a
    /// function that does so via [`define_bytebuffer_destructor!`].
    ///
    /// ## Caveats
    ///
    /// This is safe so long as the buffer is empty, or the data was allocated
    /// by Rust code, e.g. this is a ByteBuffer created by
    /// `ByteBuffer::from_vec` or `Default::default`.
    ///
    /// If the ByteBuffer were passed into Rust (which you shouldn't do, since
    /// theres no way to see the data in Rust currently), then calling `destroy`
    /// is fundamentally broken.
    #[inline]
    pub fn destroy(self) {
        drop(self.into_vec())
    }
}

impl Default for ByteBuffer {
    #[inline]
    fn default() -> Self {
        Self {
            len: 0 as i64,
            data: std::ptr::null_mut(),
        }
    }
}
