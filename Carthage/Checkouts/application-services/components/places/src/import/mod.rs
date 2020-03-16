/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

pub mod common;
pub mod fennec;
pub use fennec::import_bookmarks as import_fennec_bookmarks;
pub use fennec::import_history as import_fennec_history;
pub use fennec::import_pinned_sites as import_fennec_pinned_sites;
pub mod ios_bookmarks;
pub use ios_bookmarks::import_ios_bookmarks;
