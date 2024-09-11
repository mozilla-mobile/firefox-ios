// swiftlint:disable comment_spacing file_header
//// This Source Code Form is subject to the terms of the Mozilla Public
//// License, v. 2.0. If a copy of the MPL was not distributed with this
//// file, You can obtain one at http://mozilla.org/MPL/2.0/
//
//import Foundation
//import Glean
//
//protocol AdjustWrapper {
//    func recordDeeplink(url: URL)
//    func record(campaign: String)
//    func record(adgroup: String)
//    func record(creative: String)
//    func record(network: String)
//}
//
//struct DefaultAdjustWrapper: AdjustWrapper {
//    func recordDeeplink(url: URL) {
//        let extra = GleanMetrics.Adjust.DeeplinkReceivedExtra(receivedUrl: url.absoluteString)
//        GleanMetrics.Adjust.deeplinkReceived.record(extra)
//    }
//
//    func record(campaign: String) {
//        GleanMetrics.Adjust.campaign.set(campaign)
//    }
//
//    func record(adgroup: String) {
//        GleanMetrics.Adjust.adGroup.set(adgroup)
//    }
//
//    func record(creative: String) {
//        GleanMetrics.Adjust.creative.set(creative)
//    }
//
//    func record(network: String) {
//        GleanMetrics.Adjust.network.set(network)
//    }
//}
// swiftlint:enable comment_spacing file_header
