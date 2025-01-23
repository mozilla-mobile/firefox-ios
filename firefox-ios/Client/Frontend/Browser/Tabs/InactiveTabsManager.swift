// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

protocol InactiveTabsManagerProtocol {
    /// Returns inactive normal (non-private) tabs filtered from the given tabs array.
    /// - Parameter tabs: The array of tabs to filter.
    /// - Returns: The non-private, inactive tabs inside the `tabs` array.
    func getInactiveTabs(tabs: [Tab]) -> [Tab]
}

class InactiveTabsManager: InactiveTabsManagerProtocol {
    func getInactiveTabs(tabs: [Tab]) -> [Tab] {
        return tabs.filter({ !$0.isPrivate && $0.isInactive })
    }
}
