/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]

#[macro_use]
mod error;
mod login;

mod db;
mod engine;
pub mod schema;
mod update_plan;
mod util;

mod ffi;

// Mostly exposed for the sync manager.
pub use crate::db::LoginDb;
pub use crate::db::LoginStore;
pub use crate::engine::*;
pub use crate::error::*;
pub use crate::login::*;

pub mod msg_types {
    include!(concat!(env!("OUT_DIR"), "/msg_types.rs"));
}
