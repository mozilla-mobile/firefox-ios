// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Core

struct FeatureManagement {
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Configuration
    
    /// Fetches the feature configuration asynchronously.
    static func fetchConfiguration() async {
        do {
            try await start()
        } catch {
            debugPrint(error)
        }
    }
    
    // MARK: - Private Methods
    
    /// Starts the feature management process asynchronously.
    ///
    /// - Throws: An error if the feature management process encounters an issue.
    @MainActor
    private static func start() async throws {
        Self.addRefreshingRules()
        do {
            try await _ = Unleash.start(env: .current, appVersion: AppInfo.ecosiaAppVersion)
        } catch {
            debugPrint(error)
        }
    }
    
    /// Adds refreshing rules for feature management.
    private static func addRefreshingRules() {
        UnleashRefreshConfigurator()
            .withAppUpdateCheckRule(appVersion: AppInfo.ecosiaAppVersion)
            .withDeviceRegionUpdateCheckRule()
            .withTwentyFourHoursCacheExpirationRule()
    }
}
