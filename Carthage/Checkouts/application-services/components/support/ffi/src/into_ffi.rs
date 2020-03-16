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

use crate::string::*;
use std::os::raw::c_char;
use std::ptr;

/// This trait is used to return types over the FFI. It essentially is a mapping between a type and
/// version of that type we can pass back to C (`IntoFfi::Value`).
///
/// The main wrinkle is that we need to be able to pass a value back to C in both the success and
/// error cases. In the error cases, we don't want there to need to be any cleanup for the foreign
/// code to do, and we want the API to be relatively easy to use.
///
/// Additionally, the mapping is not consistent for different types. For some rust types, we want to
/// convert them to JSON. For some, we want to return an opaque `*mut T` handle. For others,
/// we'd like to return by value.
///
/// This trait supports those cases by adding some type-level indirection, and allowing both cases
/// to be provided (both cases what is done in the error and success cases).
///
/// We implement this for the following types:
///
/// - `String`, by conversion to `*mut c_char`. Note that the caller (on the other side of the FFI)
///   is expected to free this, so you will need to provide them with a destructor for strings,
///   which can be done with the [`define_string_destructor!`] macro.
///
/// - `()`: as a no-op conversion -- this just allows us to expose functions without a return type
///   over the FFI.
///
/// - `bool`: is implemented by conversion to `u8` (`0u8` is `false`, `1u8` is `true`, and
///   `ffi_default()` is `false`). This is because it doesn't seem to be safe to pass over the FFI
///   directly (or at least, doing so might hit a bug in JNA).
///
/// - All numeric primitives except  `isize`, `usize`, `char`, `i128`, and `u128` are implememented
///   by passing directly through (and using `Default::default()` for `ffi_default()`).
///     - `isize`, `usize` could be added, but they'd be quite easy to accidentally misuse, so we
///       currently omit them.
///     - `char` is less easy to misuse, but it's also less clear why you'd want to be doing this.
///       If we did ever add this, we'd probably want to convert to a `u32` (similar to how we
///       convert `bool` to `u8`) for better ABI stability.
///     - `i128` and `u128` do not have a stable ABI, so they cannot be returned across the FFI.
///
/// - `Option<T>` where `T` is `IntoFfi`, by returning `IntoFfi::ffi_default()` for `None`.
///
/// None of these are directly helpful for user types though, so macros are provided for the
/// following cases:
///
/// 1. For types which are passed around by an opaque pointer, the macro
///    [`implement_into_ffi_by_pointer!`] is provided.
///
/// 2. For types which should be returned as a JSON string, the macro
///    [`implement_into_ffi_by_json!`] is provided.
///
/// See the "Examples" section below for some other cases, such as returning by value.
///
/// ## Safety
///
/// This is an unsafe trait (implementing it requires `unsafe impl`). This is because we cannot
/// guarantee that your type is safe to pass to C. The helpers we've provided as macros should be
/// safe to use, and in the cases where a common pattern can't be done both safely and generically,
/// we've opted not to provide a macro for it. That said, many of these cases are still safe if you
/// meet some relatively basic requirements, see below for examples.
///
/// ## Examples
///
/// ### Returning types by value
///
/// If you want to return a type by value, we don't provide a macro for this, primarially because
/// doing so cannot be statically guarantee that it is safe. However, it *is* safe for the cases
/// where the type is either `#[repr(C)]` or `#[repr(transparent)]`. If this doesn't hold, you will
/// want to use a different option!
///
/// Regardless, if this holds, it's fairly simple to implement, for example:
///
/// ```rust
/// # use ffi_support::IntoFfi;
/// #[derive(Default)]
/// #[repr(C)]
/// pub struct Point {
///     pub x: i32,
///     pub y: i32,
/// }
///
/// unsafe impl IntoFfi for Point {
///     type Value = Self;
///     #[inline] fn ffi_default() -> Self { Default::default() }
///     #[inline] fn into_ffi_value(self) -> Self { self }
/// }
/// ```
///
/// ### Conversion to another type (which is returned over the FFI)
///
/// In the FxA FFI, we used to have a `SyncKeys` type, which was converted to a different type before
/// returning over the FFI. (The real FxA FFI is a little different, and more complex, but this is
/// relatively close, and more widely recommendable than the one the FxA FFI uses):
///
/// This is fairly easy to do by performing the conversion inside `IntoFfi`.
///
/// ```rust
/// # use ffi_support::{self, IntoFfi};
/// # use std::{ptr, os::raw::c_char};
/// pub struct SyncKeys(pub String, pub String);
///
/// #[repr(C)]
/// pub struct SyncKeysC {
///     pub sync_key: *mut c_char,
///     pub xcs: *mut c_char,
/// }
///
/// unsafe impl IntoFfi for SyncKeys {
///     type Value = SyncKeysC;
///     #[inline]
///     fn ffi_default() -> SyncKeysC {
///         SyncKeysC {
///             sync_key: ptr::null_mut(),
///             xcs: ptr::null_mut(),
///         }
///     }
///
///     #[inline]
///     fn into_ffi_value(self) -> SyncKeysC {
///         SyncKeysC {
///             sync_key: ffi_support::rust_string_to_c(self.0),
///             xcs:      ffi_support::rust_string_to_c(self.1),
///         }
///     }
/// }
///
/// // Note: this type manages memory, so you still will want to expose a destructor for this,
/// // and possibly implement Drop as well.
/// ```
pub unsafe trait IntoFfi: Sized {
    /// This type must be:
    ///
    /// 1. Compatible with C, which is to say `#[repr(C)]`, a numeric primitive,
    ///    another type that has guarantees made about it's layout, or a
    ///    `#[repr(transparent)]` wrapper around one of those.
    ///
    ///    One could even use `&T`, so long as `T: Sized`, although it's
    ///    extremely dubious to return a reference to borrowed memory over the
    ///    FFI, since it's very difficult for the caller to know how long it
    ///    remains valid.
    ///
    /// 2. Capable of storing an empty/ignorable/default value.
    ///
    /// 3. Capable of storing the actual value.
    ///
    /// Valid examples include:
    ///
    /// - Primitive numbers (other than i128/u128)
    ///
    /// - #[repr(C)] structs containing only things on this list.
    ///
    /// - `Option<Box<T>>`, but only if `T` is `Sized`. (Internally this is
    ///   guaranteed to be represented equivalently to a pointer)
    ///
    /// - Raw pointers such as `*const T`, and `*mut T`, but again, only if `T`
    ///   is `Sized` (`*const [T]`, `*mut dyn SomeTrait` etc are not valid).
    ///
    /// - Enums with a fixed `repr`, although it's a good idea avoid
    ///   `#[repr(C)]` enums in favor of, say, `#[repr(i32)]` (for example, any
    ///   fixed type there should be fine), as it's potentially error prone to
    ///   access `#[repr(C)]` enums from Android over JNA (it's only safe if C's
    ///   `sizeof(int) == 4`, which is very common, but not universally true).
    ///
    /// - `&T`/`&mut T` where `T: Sized` but only if you really know what you're
    ///   doing, because this is probably a mistake.
    ///
    /// Invalid examples include things like `&str`, `&[T]`, `String`, `Vec<T>`,
    /// `std::ffi::CString`, `&std::ffi::CStr`, etc.
    type Value;

    /// Return an 'empty' value. This is what's passed back to C in the case of an error,
    /// so it doesn't actually need to be "empty", so much as "ignorable". Note that this
    /// is also used when an empty `Option<T>` is returned.
    fn ffi_default() -> Self::Value;

    /// Convert ourselves into a value we can pass back to C with confidence.
    fn into_ffi_value(self) -> Self::Value;
}

unsafe impl IntoFfi for String {
    type Value = *mut c_char;

    #[inline]
    fn ffi_default() -> Self::Value {
        ptr::null_mut()
    }

    #[inline]
    fn into_ffi_value(self) -> Self::Value {
        rust_string_to_c(self)
    }
}

// Implement IntoFfi for Option<T> by falling back to ffi_default for None.
unsafe impl<T: IntoFfi> IntoFfi for Option<T> {
    type Value = <T as IntoFfi>::Value;

    #[inline]
    fn ffi_default() -> Self::Value {
        T::ffi_default()
    }

    #[inline]
    fn into_ffi_value(self) -> Self::Value {
        if let Some(s) = self {
            s.into_ffi_value()
        } else {
            T::ffi_default()
        }
    }
}

// We've had problems in the past returning booleans over the FFI (specifically to JNA), and so
// we convert them to `u8`.
unsafe impl IntoFfi for bool {
    type Value = u8;
    #[inline]
    fn ffi_default() -> Self::Value {
        0u8
    }
    #[inline]
    fn into_ffi_value(self) -> Self::Value {
        self as u8
    }
}

unsafe impl IntoFfi for crate::ByteBuffer {
    type Value = crate::ByteBuffer;
    #[inline]
    fn ffi_default() -> Self::Value {
        crate::ByteBuffer::default()
    }
    #[inline]
    fn into_ffi_value(self) -> Self::Value {
        self
    }
}

// just cuts down on boilerplate. Not public.
macro_rules! impl_into_ffi_for_primitive {
    ($($T:ty),+) => {$(
        unsafe impl IntoFfi for $T {
            type Value = Self;
            #[inline] fn ffi_default() -> Self { Default::default() }
            #[inline] fn into_ffi_value(self) -> Self { self }
        }
    )+}
}

// See IntoFfi docs for why this is not exhaustive
impl_into_ffi_for_primitive![(), i8, u8, i16, u16, i32, u32, i64, u64, f32, f64];

// just cuts down on boilerplate. Not public.
macro_rules! impl_into_ffi_for_pointer {
    ($($T:ty),+) => {$(
        unsafe impl IntoFfi for $T {
            type Value = Self;
            #[inline] fn ffi_default() -> Self { ptr::null_mut() }
            #[inline] fn into_ffi_value(self) -> Self { self }
        }
    )+}
}

impl_into_ffi_for_pointer![*mut i8, *const i8, *mut u8, *const u8];
