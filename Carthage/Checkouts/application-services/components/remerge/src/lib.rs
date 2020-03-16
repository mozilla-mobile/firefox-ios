/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![deny(unsafe_code)]
#![warn(rust_2018_idioms)]
#[macro_use]
mod util;
pub mod engine;
pub mod error;
pub mod ms_time;
pub mod schema;
pub mod storage;
pub mod untyped_map;
pub mod vclock;

// Some re-exports we use frequently for local convenience
pub(crate) use sync_guid::Guid;

pub(crate) use serde_json::Value as JsonValue;
pub(crate) type JsonObject<Val = JsonValue> = serde_json::Map<String, Val>;

pub use crate::engine::RemergeEngine;
pub use crate::error::*;
pub use crate::ms_time::MsTime;
pub use crate::vclock::VClock;
