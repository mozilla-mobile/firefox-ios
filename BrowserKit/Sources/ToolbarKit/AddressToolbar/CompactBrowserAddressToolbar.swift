// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public class CompactBrowserAddressToolbar: BrowserAddressToolbar {
    override internal func updateActions(config: AddressToolbarConfiguration, animated: Bool) {
        // In compact mode no browser actions will be displayed
        let compactConfig = AddressToolbarConfiguration(
            locationViewConfiguration: config.locationViewConfiguration,
            navigationActions: config.navigationActions,
            leadingPageActions: config.leadingPageActions,
            trailingPageActions: config.trailingPageActions,
            browserActions: [],
            borderPosition: config.borderPosition,
            uxConfiguration: config.uxConfiguration,
            shouldAnimate: config.shouldAnimate
        )
        super.updateActions(config: compactConfig, animated: animated)
    }
}
