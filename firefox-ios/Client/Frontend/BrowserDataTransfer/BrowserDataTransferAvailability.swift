// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

enum BrowserDataTransferDirection: CaseIterable, Sendable {
    case `import`
    case export

    init?(activityType: String) {
        guard let direction = Self.allCases.first(where: { $0.activityType == activityType }) else { return nil }
        self = direction
    }

    /// Values of `BEBrowserDataImportManager.userActivityType` and `BEBrowserDataExportManager.userActivityType`,
    /// spelled out because those symbols only exist on iOS 26.4 and newer.
    var activityType: String {
        switch self {
        case .import: return "BEBrowserDataExchangeImportActivity"
        case .export: return "BEBrowserDataExchangeExportActivity"
        }
    }

    var featureFlag: FeatureFlagID {
        switch self {
        case .import: return .browserDataImport
        case .export: return .browserDataExport
        }
    }
}

/// Decides whether a browser data transfer direction may run.
struct BrowserDataTransferAvailability {
    /// Directions whose live handling exists. A direction stays hidden and ignored until it is listed here.
    static let implementedDirections: Set<BrowserDataTransferDirection> = []

    /// Standard developer and Beta builds, matched by bundle identifier because enterprise shares the developer channel.
    /// FirefoxStaging shares the FirefoxBeta bundle identifier; its archives strip the activities, so the
    /// registration check excludes it.
    static let eligibleSchemes: Set<String> = ["Fennec", "FirefoxBeta"]

    static var isSupportedOS: Bool {
        guard !ProcessInfo.processInfo.isiOSAppOnMac,
              #available(iOS 26.4, *) else { return false }
        return true
    }

    private let featureFlags: FeatureFlagProviding
    private let isOperatingSystemSupported: Bool
    private let isEligibleBuild: Bool
    private let registeredActivityTypes: Set<String>
    private let implementedDirections: Set<BrowserDataTransferDirection>

    init(
        featureFlags: FeatureFlagProviding = AppContainer.shared.resolve(),
        isOperatingSystemSupported: Bool = BrowserDataTransferAvailability.isSupportedOS,
        isEligibleBuild: Bool = BrowserDataTransferAvailability.eligibleSchemes.contains(AppConstants.scheme),
        registeredActivityTypes: Set<String> = Set(
            Bundle.main.object(forInfoDictionaryKey: "NSUserActivityTypes") as? [String] ?? []
        ),
        implementedDirections: Set<BrowserDataTransferDirection> = BrowserDataTransferAvailability.implementedDirections
    ) {
        self.featureFlags = featureFlags
        self.isOperatingSystemSupported = isOperatingSystemSupported
        self.isEligibleBuild = isEligibleBuild
        self.registeredActivityTypes = registeredActivityTypes
        self.implementedDirections = implementedDirections
    }

    func isAvailable(_ direction: BrowserDataTransferDirection) -> Bool {
        return isOperatingSystemSupported
            && isEligibleBuild
            && implementedDirections.contains(direction)
            && registeredActivityTypes.contains(direction.activityType)
            && featureFlags.isEnabled(direction.featureFlag)
    }
}
