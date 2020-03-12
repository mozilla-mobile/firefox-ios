/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

pub mod bookmarks;
pub mod history;
pub use bookmarks::import as import_bookmarks;
pub use bookmarks::import_pinned_sites;
pub use history::import as import_history;
