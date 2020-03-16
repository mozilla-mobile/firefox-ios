/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/// Define a wrapper around the the provided ErrorKind type.
/// See also `define_error` which is more likely to be what you want.
#[macro_export]
macro_rules! define_error_wrapper {
    ($Kind:ty) => {
        /// Re-exported, so that using crate::error::* gives you the .context()
        /// method, which we don't use much but should *really* use more.
        pub use failure::ResultExt;

        pub type Result<T, E = Error> = std::result::Result<T, E>;

        #[derive(Debug)]
        pub struct Error(Box<failure::Context<$Kind>>);

        impl failure::Fail for Error {
            fn cause(&self) -> Option<&dyn failure::Fail> {
                self.0.cause()
            }

            fn backtrace(&self) -> Option<&failure::Backtrace> {
                self.0.backtrace()
            }

            fn name(&self) -> Option<&str> {
                self.0.name()
            }
        }

        impl std::fmt::Display for Error {
            fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
                std::fmt::Display::fmt(&*self.0, f)
            }
        }

        impl Error {
            pub fn kind(&self) -> &$Kind {
                &*self.0.get_context()
            }
        }

        impl From<failure::Context<$Kind>> for Error {
            // Cold to optimize in favor of non-error cases.
            #[cold]
            fn from(ctx: failure::Context<$Kind>) -> Error {
                Error(Box::new(ctx))
            }
        }

        impl From<$Kind> for Error {
            // Cold to optimize in favor of non-error cases.
            #[cold]
            fn from(kind: $Kind) -> Self {
                Error(Box::new(failure::Context::new(kind)))
            }
        }
    };
}

/// Define a set of conversions from external error types into the provided
/// error kind. Use `define_error` to do this at the same time as
/// `define_error_wrapper`.
#[macro_export]
macro_rules! define_error_conversions {
    ($Kind:ident { $(($variant:ident, $type:ty)),* $(,)? }) => ($(
        impl From<$type> for $Kind {
            // Cold to optimize in favor of non-error cases.
            #[cold]
            fn from(e: $type) -> $Kind {
                $Kind::$variant(e)
            }
        }

        impl From<$type> for Error {
            // Cold to optimize in favor of non-error cases.
            #[cold]
            fn from(e: $type) -> Self {
                Error::from($Kind::$variant(e))
            }
        }
    )*);
}

/// All the error boilerplate (okay, with a couple exceptions in some cases) in
/// one place.
#[macro_export]
macro_rules! define_error {
    ($Kind:ident { $(($variant:ident, $type:ty)),* $(,)? }) => {
        $crate::define_error_wrapper!($Kind);
        $crate::define_error_conversions! {
            $Kind {
                $(($variant, $type)),*
            }
        }
    };
}
