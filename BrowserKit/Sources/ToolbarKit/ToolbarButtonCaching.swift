// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import UIKit

/// Protocol for caching and providing toolbar buttons with performance optimization.
@MainActor
protocol ToolbarButtonCaching: AnyObject {
    /// A cache of `ToolbarButton` instances keyed by their accessibility identifier (`a11yId`).
    /// This improves performance by reusing buttons instead of creating new instances.
    var cachedButtonReferences: [String: ToolbarButton] { get set }

    /// Retrieves a `ToolbarButton` for the given `ToolbarElement`.
    /// If a cached button exists for the element's accessibility identifier, it returns the cached button.
    /// Otherwise, it creates a new button, caches it, and then returns it.
    /// - Parameter toolbarElement: The `ToolbarElement` for which to retrieve the button.
    /// - Returns: A `ToolbarButton` instance configured for the given `ToolbarElement`.
    func getToolbarButton(for toolbarElement: ToolbarElement) -> ToolbarButton
}

// MARK: - Default Implementation
extension ToolbarButtonCaching {
    func getToolbarButton(for toolbarElement: ToolbarElement) -> ToolbarButton {
        let cacheKey = toolbarElement.a11yId
        let button: ToolbarButton

        if let cachedButton = cachedButtonReferences[cacheKey] {
            button = cachedButton
        } else {
            button = toolbarElement.numberOfTabs != nil ? TabNumberButton() : ToolbarButton()
            cachedButtonReferences[cacheKey] = button
        }

        return button
    }
}
