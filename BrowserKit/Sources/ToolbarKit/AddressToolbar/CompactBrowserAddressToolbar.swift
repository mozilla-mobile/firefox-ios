// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public class CompactBrowserAddressToolbar: BrowserAddressToolbar {
    override internal func updateActions(config: AddressToolbarConfiguration) {
        // In compact mode no browser actions will be displayed
        let compactConfig = AddressToolbarConfiguration(
            locationViewConfiguration: config.locationViewConfiguration,
            navigationActions: config.navigationActions,
            pageActions: config.pageActions,
            browserActions: [],
            borderPosition: config.borderPosition
        )
        super.updateActions(config: compactConfig)
    }
}
