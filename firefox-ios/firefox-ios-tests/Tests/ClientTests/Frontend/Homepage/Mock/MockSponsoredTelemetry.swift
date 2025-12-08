// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

@testable import Client

class MockUnifiedAdsCallbackTelemetry: UnifiedAdsCallbackTelemetry {
    var sendImpressionTelemetryCalled = 0
    var sendClickTelemetryCalled = 0
    func sendImpressionTelemetry(tileSite: Storage.Site, position: Int) {
        sendImpressionTelemetryCalled += 1
    }

    func sendClickTelemetry(tileSite: Storage.Site, position: Int) {
        sendClickTelemetryCalled += 1
    }
}

class MockSponsoredTileTelemetry: SponsoredTileTelemetry {
    var sendImpressionTelemetryCalled = 0
    var sendClickTelemetryCalled = 0

    func sendImpressionTelemetry(tileSite: Site,
                                 position: Int,
                                 isUnifiedAdsEnabled: Bool) {
        sendImpressionTelemetryCalled += 1
    }
    func sendClickTelemetry(tileSite: Site,
                            position: Int,
                            isUnifiedAdsEnabled: Bool) {
        sendClickTelemetryCalled += 1
    }
}
