// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import TabDataStore

protocol TabRestorerDelegate: AnyObject {
    /// Creates and configures a `Tab` from persisted `TabData`, without loading its web content.
    @MainActor
    func createTab(with tabData: TabData) -> Tab

    /// Asynchronously loads a tab's screenshot from disk and sets it on the tab.
    @MainActor
    func restoreScreenshot(for tab: Tab)
}
