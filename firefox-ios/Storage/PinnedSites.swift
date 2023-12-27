// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

/// A protocol to manage pinned sites in BrowserDB
public protocol PinnedSites {
    // Pinning top sites
    func removeFromPinnedTopSites(_ site: Site) -> Success
    func addPinnedTopSite(_ site: Site) -> Success
    func getPinnedTopSites() -> Deferred<Maybe<Cursor<Site>>>
    func isPinnedTopSite(_ url: String) -> Deferred<Maybe<Bool>>
}
