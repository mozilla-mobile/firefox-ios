// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

public protocol AddressToolbarDelegate: AnyObject {
    func searchSuggestions(searchTerm: String)
    func didClearSearch()
    func openBrowser(searchTerm: String)
    func addressToolbarDidBeginEditing(searchTerm: String, shouldShowSuggestions: Bool)
    func addressToolbarAccessibilityActions() -> [UIAccessibilityCustomAction]?
    func configureContextualHint(_ addressToolbar: BrowserAddressToolbar,
                                 for button: UIButton,
                                 with contextualHintType: String)
    func addressToolbarDidBeginDragInteraction()
    func addressToolbarDidProvideItemsForDragInteraction()
    func addressToolbarDidTapSearchEngine(_ searchEngineView: UIView)
    func addressToolbarNeedsSearchReset()
}
