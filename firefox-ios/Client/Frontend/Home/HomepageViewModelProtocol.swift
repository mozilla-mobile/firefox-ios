// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

// Protocol for each section view model in Firefox Home page view controller
protocol HomepageViewModelProtocol {
    var sectionType: HomepageSectionType { get }

    // Layout section so FirefoxHomeViewController view controller can setup the section
    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection

    func numberOfItemsInSection() -> Int

    // The header view model to setup the header for this section
    var headerViewModel: LabelButtonHeaderViewModel { get }

    // Returns true when section needs to load data and show itself
    var isEnabled: Bool { get }

    // Returns true when section has data to show
    var hasData: Bool { get }

    // Returns true when section has data and is enabled
    var shouldShow: Bool { get }

    // Refresh data from adaptor to ensure it refresh the right state before laying itself out
    func refreshData(for traitCollection: UITraitCollection,
                     size: CGSize,
                     isPortrait: Bool,
                     device: UIUserInterfaceIdiom,
                     orientation: UIDeviceOrientation)

    // Update section that are privacy sensitive, only implement when needed
    func updatePrivacyConcernedSection(isPrivate: Bool)

    // Called anytime the screen is shown
    func screenWasShown()

    // Theme management
    var theme: Theme { get set }
    func setTheme(theme: Theme)
}

extension HomepageViewModelProtocol {
    var hasData: Bool { return true }

    var shouldShow: Bool {
        return isEnabled && hasData
    }

    func updatePrivacyConcernedSection(isPrivate: Bool) {}

    func refreshData(for traitCollection: UITraitCollection,
                     size: CGSize,
                     isPortrait: Bool,
                     device: UIUserInterfaceIdiom,
                     orientation: UIDeviceOrientation) {}

    func screenWasShown() {}
}
