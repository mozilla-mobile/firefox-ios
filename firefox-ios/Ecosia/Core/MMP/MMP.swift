// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import AdServices
import Common

public enum MMPEvent: String {
    case onboardingStart = "onboarding_start"
    case onboardingComplete = "onboarding_complete"
    case firstSearch = "first_search"
    case fifthSearch = "fifth_search"
    case tenthSearch = "tenth_search"
}

public struct MMP {

    private init() {}

    static var appDeviceInfo: AppDeviceInfo {
        /// We are hardcoding `iOS` as per the platform parameter
        /// as `Singular` MMP doesn't currently support others like `iPadOS`
        /// We don't want to modify the `DeviceInfo.platform` as other services may need the correct one.
        AppDeviceInfo(platform: "iOS",
                      bundleId: AppInfo.bundleIdentifier,
                      osVersion: DeviceInfo.osVersionNumber,
                      deviceManufacturer: DeviceInfo.manufacturer,
                      deviceModel: DeviceInfo.deviceModelName,
                      locale: DeviceInfo.currentLocale,
                      country: DeviceInfo.currentCountry,
                      deviceBuildVersion: DeviceInfo.osBuildNumber,
                      appVersion: AppInfo.ecosiaAppVersion,
                      installReceipt: AppInfo.installReceipt,
                      adServicesAttributionToken: AppInfo.adServicesAttributionToken)
    }

    public static func sendSession() {
        guard User.shared.sendAnonymousUsageData else { return }

        Task {
            do {
                let mmpProvider: MMPProvider = Singular(includeSKAN: true)
                try await mmpProvider.sendSessionInfo(appDeviceInfo: appDeviceInfo)
            } catch {
                debugPrint(error)
            }
        }
    }

    public static func sendEvent(_ event: MMPEvent) {
        guard User.shared.sendAnonymousUsageData else { return }

        Task {
            do {
                let mmpProvider: MMPProvider = Singular(includeSKAN: true)
                try await mmpProvider.sendEvent(event, appDeviceInfo: appDeviceInfo)
            } catch {
                debugPrint(error)
            }
        }
    }

    public static func handleSearchEvent(_ count: Int) {
        let eventMap: [Int: MMPEvent] = [1: .firstSearch, 5: .fifthSearch, 10: .tenthSearch]
        if let event = eventMap[count] {
            self.sendEvent(event)
        }
    }
}
