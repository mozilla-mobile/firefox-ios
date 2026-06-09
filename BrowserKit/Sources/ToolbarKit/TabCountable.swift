// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

private struct UX {
    static let maxTabCount = 99
    static let infinitySymbol = "\u{221E}"
}

/// Adds tab-count display capability to any ToolbaButton subclass.
protocol TabCountable: AnyObject {
    /// Updates accessibility value, large-content title, and returns the
    /// display string for the current tab count.
    @MainActor
    @discardableResult
    func updateTabCount(for element: ToolbarElement) -> String?
}

extension TabCountable where Self: ToolbarButton {
    @MainActor
    @discardableResult
    func updateTabCount(for element: ToolbarElement) -> String? {
        guard let numberOfTabs = element.numberOfTabs,
              let largeContentTitle = element.largeContentTitle else { return nil }
        let count = max(numberOfTabs, 1)
        let countToBe = (count <= UX.maxTabCount) ? count.description : UX.infinitySymbol
        accessibilityValue = countToBe
        self.largeContentTitle = largeContentTitle

        return countToBe
    }
}
