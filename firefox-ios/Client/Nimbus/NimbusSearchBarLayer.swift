// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class NimbusSearchBarLayer {
    // MARK: - Public methods
    public func getDefaultPosition(from nimbus: FxNimbus = FxNimbus.shared) -> SearchBarPosition {
        let layout = nimbus.features.toolbarRefactorFeature.value().layout

        guard UIDevice.current.userInterfaceIdiom != .pad, layout == .version1 else {
            let isAtBottom = nimbus.features.search.value().awesomeBar.position.isBottom
            return isAtBottom ? .bottom : .top
        }

        // Set the address bar to the bottom for new users enrolled in `version1` toolbar experiment.
        return .bottom
    }
}
