// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol NimbusFakespotFeatureLayerProtocol {
    func getSiteConfig(siteName: String) -> WebsiteConfig?
}

class NimbusFakespotFeatureLayer: NimbusFakespotFeatureLayerProtocol {
    let nimbus: FxNimbus

    init(nimbus: FxNimbus = .shared) {
        self.nimbus = nimbus
    }

    func getSiteConfig(siteName: String) -> WebsiteConfig? {
        nimbus.features.shopping2023.value().config[siteName]
    }
}
