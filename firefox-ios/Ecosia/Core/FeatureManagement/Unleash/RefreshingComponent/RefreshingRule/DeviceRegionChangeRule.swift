// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct DeviceRegionChangeRule: RefreshingRule {

    private var currentRegion: String

    init(localeProvider: RegionLocatable = Locale.current) {
        currentRegion = localeProvider.regionIdentifierLowercasedWithFallbackValue
    }

    var shouldRefresh: Bool {
        currentRegion != Unleash.model.deviceRegion
    }
}
