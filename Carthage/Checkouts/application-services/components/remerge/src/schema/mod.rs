/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

pub mod desc;

pub mod error;
pub mod json;
pub mod merge_kinds;

pub use desc::*;
pub use error::SchemaError;
pub use json::parse_from_string;
pub use merge_kinds::*;
