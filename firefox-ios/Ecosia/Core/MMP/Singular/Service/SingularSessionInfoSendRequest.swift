// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

#if os(iOS)

struct SingularSessionInfoSendRequest: BaseRequest {

    struct Parameters: Encodable {
        let identifier: String
        let platform: String
        let bundleId: String
        let osVersion: String
        let deviceManufacturer: String
        let deviceModel: String
        let locale: String
        let country: String?
        let deviceBuildVersion: String?
        let appVersion: String
        let installReceipt: String?
        let attributionToken: String?

        enum CodingKeys: String, CodingKey {
            case identifier = "sing"
            case platform = "p"
            case bundleId = "i"
            case osVersion = "ve"
            case deviceManufacturer = "ma"
            case deviceModel = "mo"
            case locale = "lc"
            case country = "country"
            case deviceBuildVersion = "bd"
            case appVersion = "app_v"
            case installReceipt = "install_receipt"
            case attributionToken = "attribution_token"
        }
    }

    var method: HTTPMethod {
        .get
    }

    var path: String {
        "/v2/attribution/launch"
    }

    var queryParameters: [String: String]?

    var additionalHeaders: [String: String]?

    var body: Data?

    init(identifier: String, info: AppDeviceInfo, skanParameters: [String: String]?) {
        var deviceBuildVersion: String?
        if let deviceBuildVersionString = info.deviceBuildVersion {
            deviceBuildVersion = #"Build\\#(deviceBuildVersionString)"#
        }
        var parameters = Parameters(identifier: identifier,
                                    platform: info.platform,
                                    bundleId: info.bundleId,
                                    osVersion: info.osVersion,
                                    deviceManufacturer: info.deviceManufacturer,
                                    deviceModel: info.deviceModel,
                                    locale: info.locale,
                                    country: info.country,
                                    deviceBuildVersion: deviceBuildVersion,
                                    appVersion: info.appVersion,
                                    installReceipt: info.installReceipt,
                                    attributionToken: info.adServicesAttributionToken).dictionary
        if let skanParameters = skanParameters {
            parameters = parameters.merging(skanParameters) { (current, _) in current }
        }
        self.queryParameters = parameters
    }
}

#endif
