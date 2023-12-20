// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol NimbusFakespotFeatureLayerProtocol {
    func getSiteConfig(siteName: String) -> WebsiteConfig?
    var relayURL: URL? { get }
    var config: [String: WebsiteConfig] { get }
}

class NimbusFakespotFeatureLayer: NimbusFakespotFeatureLayerProtocol {
    let nimbus: FxNimbus

    var config: [String: WebsiteConfig] {
        nimbus.features.shopping2023.value().config
    }

    init(nimbus: FxNimbus = .shared) {
        self.nimbus = nimbus
    }

    func getSiteConfig(siteName: String) -> WebsiteConfig? {
        config[siteName]
    }

    var relayURL: URL? {
        URL(string: nimbus.features.shopping2023.value().relay)
    }
}
