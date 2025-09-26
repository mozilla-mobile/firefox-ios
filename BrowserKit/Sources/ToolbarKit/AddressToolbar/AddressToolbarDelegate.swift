// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

public protocol AddressToolbarDelegate: AnyObject {
    @MainActor
    func searchSuggestions(searchTerm: String)
    @MainActor
    func didClearSearch()
    @MainActor
    func openBrowser(searchTerm: String)
    @MainActor
    func addressToolbarDidBeginEditing(searchTerm: String, shouldShowSuggestions: Bool)
    @MainActor
    func addressToolbarAccessibilityActions() -> [UIAccessibilityCustomAction]?
    @MainActor
    func configureContextualHint(_ addressToolbar: BrowserAddressToolbar,
                                 for button: UIButton,
                                 with contextualHintType: String)
    @MainActor
    func addressToolbarDidBeginDragInteraction()
    @MainActor
    func addressToolbarDidProvideItemsForDragInteraction()
    @MainActor
    func addressToolbarDidTapSearchEngine(_ searchEngineView: UIView)
    @MainActor
    func addressToolbarNeedsSearchReset()
}
