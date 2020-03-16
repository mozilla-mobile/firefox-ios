/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]

#[macro_use]
pub mod error;
mod ffi;
mod storage;
mod sync;

pub mod msg_types {
    include!(concat!(env!("OUT_DIR"), "/msg_types.rs"));
}

pub use crate::storage::{ClientRemoteTabs, RemoteTab};
pub use crate::sync::engine::TabsEngine;
pub use crate::sync::store::TabsStore;
pub use error::{Error, ErrorKind, Result};

// Re-export `DeviceType`, so that it's easier for consumers to make
// `ClientRemoteTabs` structs without importing `sync15`.
pub use sync15::clients::DeviceType;
