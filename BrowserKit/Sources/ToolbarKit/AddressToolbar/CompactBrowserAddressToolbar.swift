// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public class CompactBrowserAddressToolbar: BrowserAddressToolbar {
<<<<<<< HEAD
    override internal func updateActions(state: AddressToolbarState) {
        // In compact mode no browser actions will be displayed
        let compactState = AddressToolbarState(locationViewState: state.locationViewState,
                                               navigationActions: state.navigationActions,
                                               pageActions: state.pageActions,
                                               browserActions: [],
                                               borderPosition: state.borderPosition)
        super.updateActions(state: compactState)
=======
    override internal func updateActions(config: AddressToolbarConfiguration, animated: Bool) {
        // In compact mode no browser actions will be displayed
        let compactConfig = AddressToolbarConfiguration(
            locationViewConfiguration: config.locationViewConfiguration,
            navigationActions: config.navigationActions,
            pageActions: config.pageActions,
            browserActions: [],
            borderPosition: config.borderPosition,
            shouldAnimate: config.shouldAnimate
        )
        super.updateActions(config: compactConfig, animated: animated)
>>>>>>> 68cacdc07 (Bugfix FXIOS-9857 Normal tabs appear in private top tabs tray briefly during launch (#24667))
    }
}
