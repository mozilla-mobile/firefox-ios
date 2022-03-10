// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol FXHomeViewModelProtocol {

    // In an ideal world all section would comform perfectly to this protocol,
    // But we're still in between. This check is to ensure we update data with
    // protocol only for sections that are ready to conform.
    var isComformanceUpdateDataReady: Bool { get }

    var sectionType: FirefoxHomeSectionType { get }

    // Returns true when section needs to load data and show itself
    var isEnabled: Bool { get }

    // Returns true when section has data to show
    var hasData: Bool { get }

    // Returns true when section has data and is enabled
    var shouldShow: Bool { get }

    // Update section data, completes when data has finished loading
    func updateData(completion: @escaping () -> Void)

    // Update section that are privacy sensitive, only implement when needed
    func updatePrivacyConcernedSection(isPrivate: Bool)
}

extension FXHomeViewModelProtocol {
    var hasData: Bool { return true }

    var shouldShow: Bool {
        return isEnabled && hasData
    }

    func updateData(completion: @escaping () -> Void) {}

    func updatePrivacyConcernedSection(isPrivate: Bool) {}
}
