// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// Protocol for each section view model in Firefox Home page view controller
protocol FXHomeViewModelProtocol {

    var sectionType: FirefoxHomeSectionType { get }

    // Layout section so FirefoxHomeViewController view controller can setup the section
    func section(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection

    func numberOfItemsInSection(for traitCollection: UITraitCollection) -> Int

    // The header view model to setup the header for this section
    var headerViewModel: ASHeaderViewModel { get }

    // Returns true when section needs to load data and show itself
    var isEnabled: Bool { get }

    // Returns true when section has data to show
    var hasData: Bool { get }

    // Returns true when section has data and is enabled
    var shouldShow: Bool { get }

    // Update section data from backend, completes when data has finished loading
    func updateData(completion: @escaping () -> Void)

    // Refresh data after reloadOnRotation, so layout can be adjusted
    // Can also be used to prepare data for a specific trait collection when UI is ready to show
    func refreshData(for traitCollection: UITraitCollection)

    // Update section that are privacy sensitive, only implement when needed
    func updatePrivacyConcernedSection(isPrivate: Bool)
}

extension FXHomeViewModelProtocol {
    var hasData: Bool { return true }

    var shouldShow: Bool {
        return isEnabled && hasData
    }

    func updateData(completion: @escaping () -> Void) {}

    func refreshData(for traitCollection: UITraitCollection) {}

    func updatePrivacyConcernedSection(isPrivate: Bool) {}
}
