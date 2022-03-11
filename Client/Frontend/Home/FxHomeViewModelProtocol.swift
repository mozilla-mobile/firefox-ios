// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// Protocol for each section view model in Firefox Home page view controller
protocol FXHomeViewModelProtocol {

    var sectionType: FirefoxHomeSectionType { get }

    // Returns true when section needs to load data and show itself
    var isEnabled: Bool { get }

    // Returns true when section has data to show
    var hasData: Bool { get }

    // Returns true when section has data and is enabled
    var shouldShow: Bool { get }

    // Update section data, completes when data has finished loading
    func updateData(completion: @escaping () -> Void)

    // If we need to reload the section after data was loaded
    var shouldReloadSection: Bool { get }

    // Update section that are privacy sensitive, only implement when needed
    func updatePrivacyConcernedSection(isPrivate: Bool)
}

extension FXHomeViewModelProtocol {
    var hasData: Bool { return true }

    var shouldShow: Bool {
        return isEnabled && hasData
    }

    func updateData(completion: @escaping () -> Void) {}

    var shouldReloadSection: Bool { return false }

    func updatePrivacyConcernedSection(isPrivate: Bool) {}
}
