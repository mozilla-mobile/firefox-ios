// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class NimbusSearchBarLayer {

    // MARK: - Public methods
    public func getDefaultPosition(from nimbus: FxNimbus = FxNimbus.shared) -> SearchBarPosition {
        let isAtBottom = nimbus.features.generalAppFeatures.value().searchBarPosition.isBottom

        return isAtBottom ? .bottom : .top
    }
}
