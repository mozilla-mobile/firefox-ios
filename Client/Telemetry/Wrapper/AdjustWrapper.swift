// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
// Ecosia: remove Glean dependency // import Glean

protocol AdjustWrapper {
    func recordDeeplink(url: URL)
    func record(campaign: String)
    func record(adgroup: String)
    func record(creative: String)
    func record(network: String)
}

struct DefaultAdjustWrapper: AdjustWrapper {
    func recordDeeplink(url: URL) {
        /* Ecosia: remove Glean dependency
        let extra = GleanMetrics.Adjust.DeeplinkReceivedExtra(receivedUrl: url.absoluteString)
        GleanMetrics.Adjust.deeplinkReceived.record(extra)
         */
    }

    func record(campaign: String) {
        // Ecosia: remove Glean dependency
        // GleanMetrics.Adjust.campaign.set(campaign)
    }

    func record(adgroup: String) {
        // Ecosia: remove Glean dependency
        // GleanMetrics.Adjust.adGroup.set(adgroup)
    }

    func record(creative: String) {
        // Ecosia: remove Glean dependency
        // GleanMetrics.Adjust.creative.set(creative)
    }

    func record(network: String) {
        // Ecosia: remove Glean dependency
        // GleanMetrics.Adjust.network.set(network)
    }
}
