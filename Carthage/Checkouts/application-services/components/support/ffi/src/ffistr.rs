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

use std::ffi::CStr;
use std::marker::PhantomData;
use std::os::raw::c_char;

/// `FfiStr<'a>` is a safe (`#[repr(transparent)]`) wrapper around a
/// nul-terminated `*const c_char` (e.g. a C string). Conceptually, it is
/// similar to [`std::ffi::CStr`], except that it may be used in the signatures
/// of extern "C" functions.
///
/// Functions accepting strings should use this instead of accepting a C string
/// directly. This allows us to write those functions using safe code without
/// allowing safe Rust to cause memory unsafety.
///
/// A single function for constructing these from Rust ([`FfiStr::from_raw`])
/// has been provided. Most of the time, this should not be necessary, and users
/// should accept `FfiStr` in the parameter list directly.
///
/// ## Caveats
///
/// An effort has been made to make this struct hard to misuse, however it is
/// still possible, if the `'static` lifetime is manually specified in the
/// struct. E.g.
///
/// ```rust,no_run
/// # use ffi_support::FfiStr;
/// // NEVER DO THIS
/// #[no_mangle]
/// extern "C" fn never_do_this(s: FfiStr<'static>) {
///     // save `s` somewhere, and access it after this
///     // function returns.
/// }
/// ```
///
/// Instead, one of the following patterns should be used:
///
/// ```
/// # use ffi_support::FfiStr;
/// #[no_mangle]
/// extern "C" fn valid_use_1(s: FfiStr<'_>) {
///     // Use of `s` after this function returns is impossible
/// }
/// // Alternative:
/// #[no_mangle]
/// extern "C" fn valid_use_2(s: FfiStr) {
///     // Use of `s` after this function returns is impossible
/// }
/// ```
#[repr(transparent)]
pub struct FfiStr<'a> {
    cstr: *const c_char,
    _boo: PhantomData<&'a ()>,
}

impl<'a> FfiStr<'a> {
    /// Construct an `FfiStr` from a raw pointer.
    ///
    /// This should not be needed most of the time, and users should instead
    /// accept `FfiStr` in function parameter lists.
    ///
    /// # Safety
    ///
    /// Dereferences a pointer and is thus unsafe.
    #[inline]
    pub unsafe fn from_raw(ptr: *const c_char) -> Self {
        Self {
            cstr: ptr,
            _boo: PhantomData,
        }
    }

    /// Construct a FfiStr from a `std::ffi::CStr`. This is provided for
    /// completeness, as a safe method of producing an `FfiStr` in Rust.
    #[inline]
    pub fn from_cstr(cstr: &'a CStr) -> Self {
        Self {
            cstr: cstr.as_ptr(),
            _boo: PhantomData,
        }
    }

    /// Get an `&str` out of the `FfiStr`. This will panic in any case that
    /// [`FfiStr::as_opt_str`] would return `None` (e.g. null pointer or invalid
    /// UTF-8).
    ///
    /// If the string should be optional, you should use [`FfiStr::as_opt_str`]
    /// instead. If an owned string is desired, use [`FfiStr::into_string`] or
    /// [`FfiStr::into_opt_string`].
    #[inline]
    pub fn as_str(&self) -> &'a str {
        self.as_opt_str()
            .expect("Unexpected null string pointer passed to rust")
    }

    /// Get an `Option<&str>` out of the `FfiStr`. If this stores a null
    /// pointer, then None will be returned. If a string containing invalid
    /// UTF-8 was passed, then an error will be logged and `None` will be
    /// returned.
    ///
    /// If the string is a required argument, use [`FfiStr::as_str`], or
    /// [`FfiStr::into_string`] instead. If `Option<String>` is desired, use
    /// [`FfiStr::into_opt_string`] (which will handle invalid UTF-8 by
    /// replacing with the replacement character).
    pub fn as_opt_str(&self) -> Option<&'a str> {
        if self.cstr.is_null() {
            return None;
        }
        unsafe {
            match std::ffi::CStr::from_ptr(self.cstr).to_str() {
                Ok(s) => Some(s),
                Err(e) => {
                    log::error!("Invalid UTF-8 was passed to rust! {:?}", e);
                    None
                }
            }
        }
    }

    /// Get an `Option<String>` out of the `FfiStr`. Returns `None` if this
    /// `FfiStr` holds a null pointer. Note that unlike [`FfiStr::as_opt_str`],
    /// invalid UTF-8 is replaced with the replacement character instead of
    /// causing us to return None.
    ///
    /// If the string should be mandatory, you should use
    /// [`FfiStr::into_string`] instead. If an owned string is not needed, you
    /// may want to use [`FfiStr::as_str`] or [`FfiStr::as_opt_str`] instead,
    /// (however, note the differences in how invalid UTF-8 is handled, should
    /// this be relevant to your use).
    pub fn into_opt_string(self) -> Option<String> {
        if !self.cstr.is_null() {
            unsafe { Some(CStr::from_ptr(self.cstr).to_string_lossy().to_string()) }
        } else {
            None
        }
    }

    /// Get a `String` out of a `FfiStr`. This function is essential a
    /// convenience wrapper for `ffi_str.into_opt_string().unwrap()`, with a
    /// message that indicates that a null argument was passed to rust when it
    /// should be mandatory. As with [`FfiStr::into_opt_string`], invalid UTF-8
    /// is replaced with the replacement character if encountered.
    ///
    /// If the string should *not* be mandatory, you should use
    /// [`FfiStr::into_opt_string`] instead. If an owned string is not needed,
    /// you may want to use [`FfiStr::as_str`] or [`FfiStr::as_opt_str`]
    /// instead, (however, note the differences in how invalid UTF-8 is handled,
    /// should this be relevant to your use).
    #[inline]
    pub fn into_string(self) -> String {
        self.into_opt_string()
            .expect("Unexpected null string pointer passed to rust")
    }
}

impl<'a> std::fmt::Debug for FfiStr<'a> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        if let Some(s) = self.as_opt_str() {
            write!(f, "FfiStr({:?})", s)
        } else {
            write!(f, "FfiStr(null)")
        }
    }
}

// Conversions...

impl<'a> From<FfiStr<'a>> for String {
    #[inline]
    fn from(f: FfiStr<'a>) -> Self {
        f.into_string()
    }
}

impl<'a> From<FfiStr<'a>> for Option<String> {
    #[inline]
    fn from(f: FfiStr<'a>) -> Self {
        f.into_opt_string()
    }
}

impl<'a> From<FfiStr<'a>> for Option<&'a str> {
    #[inline]
    fn from(f: FfiStr<'a>) -> Self {
        f.as_opt_str()
    }
}

impl<'a> From<FfiStr<'a>> for &'a str {
    #[inline]
    fn from(f: FfiStr<'a>) -> Self {
        f.as_str()
    }
}

// TODO: `AsRef<str>`?

// Comparisons...

// Compare FfiStr with eachother
impl<'a> PartialEq for FfiStr<'a> {
    #[inline]
    fn eq(&self, other: &FfiStr<'a>) -> bool {
        self.as_opt_str() == other.as_opt_str()
    }
}

// Compare FfiStr with str
impl<'a> PartialEq<str> for FfiStr<'a> {
    #[inline]
    fn eq(&self, other: &str) -> bool {
        self.as_opt_str() == Some(other)
    }
}

// Compare FfiStr with &str
impl<'a, 'b> PartialEq<&'b str> for FfiStr<'a> {
    #[inline]
    fn eq(&self, other: &&'b str) -> bool {
        self.as_opt_str() == Some(*other)
    }
}

// rhs/lhs swap version of above
impl<'a> PartialEq<FfiStr<'a>> for str {
    #[inline]
    fn eq(&self, other: &FfiStr<'a>) -> bool {
        Some(self) == other.as_opt_str()
    }
}

// rhs/lhs swap...
impl<'a, 'b> PartialEq<FfiStr<'a>> for &'b str {
    #[inline]
    fn eq(&self, other: &FfiStr<'a>) -> bool {
        Some(*self) == other.as_opt_str()
    }
}
