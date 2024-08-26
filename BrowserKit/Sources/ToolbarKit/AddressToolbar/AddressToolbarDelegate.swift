// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

public protocol AddressToolbarDelegate: AnyObject {
    func searchSuggestions(searchTerm: String)
    func openBrowser(searchTerm: String)
    func openSuggestions(searchTerm: String)
    func addressToolbarAccessibilityActions() -> [UIAccessibilityCustomAction]?
    func configureCFR(_ addressToolbar: BrowserAddressToolbar, for button: ToolbarButton)
}
