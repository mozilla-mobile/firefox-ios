// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct AppDeviceInfo: Equatable {

    public let platform: String
    public let bundleId: String
    public let osVersion: String
    public let deviceManufacturer: String
    public let deviceModel: String
    public let locale: String
    public let country: String?
    public let deviceBuildVersion: String?
    public let appVersion: String
    public let installReceipt: String?
    public let adServicesAttributionToken: String?

    public init(platform: String,
                bundleId: String,
                osVersion: String,
                deviceManufacturer: String,
                deviceModel: String,
                locale: String,
                country: String? = nil,
                deviceBuildVersion: String? = nil,
                appVersion: String,
                installReceipt: String? = nil,
                adServicesAttributionToken: String? = nil) {
        self.platform = platform
        self.bundleId = bundleId
        self.osVersion = osVersion
        self.deviceManufacturer = deviceManufacturer
        self.deviceModel = deviceModel
        self.locale = locale
        self.country = country
        self.deviceBuildVersion = deviceBuildVersion
        self.appVersion = appVersion
        self.installReceipt = installReceipt
        self.adServicesAttributionToken = adServicesAttributionToken
    }
}
