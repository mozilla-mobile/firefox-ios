// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client
import MozillaAppServices

class NimbusMock: FxNimbus {

    ///
    /// This should be populated at app launch.
    ///
    public var api: FeaturesInterface? {
        fatalError("Not implemented in mock yet")
    }

    ///
    /// Represents all the features supported by Nimbus
    ///
    public let features = MockFeatures()

    ///
    /// A singleton instance of FxNimbus
    ///
    public static let shared = NimbusMock()
}

class MockFeatures: Features {
    
}
