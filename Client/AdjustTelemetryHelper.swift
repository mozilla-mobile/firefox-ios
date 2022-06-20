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
    func setAttribution(_ attribution: AdjustTelemetryData?) -> Bool
    func sendDeeplinkTelemetry(url: URL)
}

class AdjustTelemetryHelper: AdjustTelemetryProtocol {

    // MARK: - UserDefaults

    private enum UserDefaultsKey: String {
        case hasSetAttributionData = "com.moz.adjust.hasSetAttributionData.key"
    }

    var hasSetAttributionData: Bool {
        get { UserDefaults.standard.object(forKey: UserDefaultsKey.hasSetAttributionData.rawValue) as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.hasSetAttributionData.rawValue) }
    }

    func sendDeeplinkTelemetry(url: URL) {
        let extra = [TelemetryWrapper.EventExtraKey.deeplinkURL.rawValue: url.absoluteString]

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .applicationOpenUrl,
                                     object: .deeplinkReceived,
                                     value: nil,
                                     extras: extra)
    }

    @discardableResult
    func setAttribution(_ attribution: AdjustTelemetryData?) -> Bool {
        guard !hasSetAttributionData else { return false }

        guard let campaign = attribution?.campaign,
              let adgroup = attribution?.adgroup,
              let creative = attribution?.creative,
              let network = attribution?.network else { return false}

        GleanMetrics.Adjust.campaign.set(campaign)
        GleanMetrics.Adjust.adGroup.set(adgroup)
        GleanMetrics.Adjust.creative.set(creative)
        GleanMetrics.Adjust.network.set(network)

        hasSetAttributionData = true
        return true
    }
}
