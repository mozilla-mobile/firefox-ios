// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol NimbusSplashScreenFeatureLayerProtocol {
    var maximumDurationMs: Int { get }
}

class NimbusSplashScreenFeatureLayer: NimbusSplashScreenFeatureLayerProtocol {
    private let nimbus: FxNimbus

    var maximumDurationMs: Int {
        return nimbus.features.splashScreen.value().maximumDurationMs
    }

    init(nimbus: FxNimbus = .shared) {
        self.nimbus = nimbus
    }
}
