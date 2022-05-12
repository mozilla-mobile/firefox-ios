// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class FxHomeCustomizeButtonViewModel {
    // Customize button is always present at the bottom of the page
}

// MARK: FXHomeViewModelProtocol
extension FxHomeCustomizeButtonViewModel: FXHomeViewModelProtocol {

    var sectionType: FirefoxHomeSectionType {
        return .customizeHome
    }

    var isEnabled: Bool {
        return true
    }
}
