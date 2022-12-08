// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Adjust
import Glean

protocol AdjustTelemetryData {
    var campaign: String? { get set }
    var adgroup: String? { get set }
    var creative: String? { get set }
    var network: String? { get set }
}

extension ADJAttribution: AdjustTelemetryData {
}

protocol AdjustTelemetryProtocol {
    func setAttributionData(_ attribution: AdjustTelemetryData?)
    func sendDeeplinkTelemetry(url: URL, attribution: AdjustTelemetryData?)
}

class AdjustTelemetryHelper: AdjustTelemetryProtocol {
    func sendDeeplinkTelemetry(url: URL, attribution: AdjustTelemetryData?) {
        let extra = GleanMetrics.Adjust.DeeplinkReceivedExtra(receivedUrl: url.absoluteString)
        GleanMetrics.Adjust.deeplinkReceived.record(extra)

        setAttributionData(attribution)
    }

    func setAttributionData(_ attribution: AdjustTelemetryData?) {
        guard let campaign = attribution?.campaign,
              let adgroup = attribution?.adgroup,
              let creative = attribution?.creative,
              let network = attribution?.network else { return }

        GleanMetrics.Adjust.campaign.set(campaign)
        GleanMetrics.Adjust.adGroup.set(adgroup)
        GleanMetrics.Adjust.creative.set(creative)
        GleanMetrics.Adjust.network.set(network)
        GleanMetrics.Pings.shared.firstSession.submit()
    }
}
