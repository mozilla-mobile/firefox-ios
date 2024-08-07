// swiftlint:disable comment_spacing file_header
//// This Source Code Form is subject to the terms of the Mozilla Public
//// License, v. 2.0. If a copy of the MPL was not distributed with this
//// file, You can obtain one at http://mozilla.org/MPL/2.0/
//
//import Foundation
//import Adjust
//
//protocol AdjustTelemetryData {
//    var campaign: String? { get set }
//    var adgroup: String? { get set }
//    var creative: String? { get set }
//    var network: String? { get set }
//}
//
//extension ADJAttribution: AdjustTelemetryData {
//}
//
//protocol AdjustTelemetryProtocol {
//    func setAttributionData(_ attribution: AdjustTelemetryData?)
//    func sendDeeplinkTelemetry(url: URL, attribution: AdjustTelemetryData?)
//}
//
//class AdjustTelemetryHelper: AdjustTelemetryProtocol {
//    var gleanWrapper: GleanWrapper
//    var telemetry: AdjustWrapper
//
//    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper(),
//         telemetry: AdjustWrapper = DefaultAdjustWrapper()) {
//        self.gleanWrapper = gleanWrapper
//        self.telemetry = telemetry
//    }
//
//    func sendDeeplinkTelemetry(url: URL, attribution: AdjustTelemetryData?) {
//        telemetry.recordDeeplink(url: url)
//
//        setAttributionData(attribution)
//    }
//
//    func setAttributionData(_ attribution: AdjustTelemetryData?) {
//        if let campaign = attribution?.campaign {
//            telemetry.record(campaign: campaign)
//        }
//
//        if let adgroup = attribution?.adgroup {
//            telemetry.record(adgroup: adgroup)
//        }
//
//        if let creative = attribution?.creative {
//            telemetry.record(creative: creative)
//        }
//
//        if let network = attribution?.network {
//            telemetry.record(network: network)
//        }
//
//        gleanWrapper.submitPing()
//    }
//}
// swiftlint:enable comment_spacing file_header
