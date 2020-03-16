/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]

pub mod communications;
pub mod config;
pub mod crypto;
pub mod error;
pub mod ffi;
pub mod storage;
pub mod subscriber;

pub mod msg_types {
    include!(concat!(env!("OUT_DIR"), "/msg_types.rs"));
}
