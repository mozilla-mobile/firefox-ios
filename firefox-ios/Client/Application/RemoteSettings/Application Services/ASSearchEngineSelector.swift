// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Account
import Common
import Shared

/// Describes public API for search engine selector wrapper for Application Services.
protocol ASSearchEngineSelectorProtocol {
    /// Fetches search engines from Remote Settings based on the current locale and region.
    /// - Parameters:
    ///   - locale: the locale (e.g. 'en-US')
    ///   - region: the region (e.g. 'US')
    ///   - completion: a RefinedSearchConfig object describing the search engine results and/or an error.
    func fetchSearchEngines(locale: String,
                            region: String,
                            completion: @escaping ((RefinedSearchConfig?, Error?) -> Void))
}

final class ASSearchEngineSelector: ASSearchEngineSelectorProtocol {
    private let engineSelector = SearchEngineSelector()
    private let service: RemoteSettingsService

    init(service: RemoteSettingsService) {
        self.service = service
    }

    // MARK: - ASSearchEngineSelectorProtocol

    func fetchSearchEngines(locale: String,
                            region: String,
                            completion: @escaping ((RefinedSearchConfig?, Error?) -> Void)) {
         do {
             try engineSelector.useRemoteSettingsServer(service: service, applyEngineOverrides: false)
             if SearchEngineFlagManager.temp_dbg_forceASSync { _ = try? service.sync() }

<<<<<<< HEAD
             let deviceType: SearchDeviceType = UIDevice.current.userInterfaceIdiom == .pad ? .tablet : .smartphone
             // TODO: What happens if the locale or region changes during app runtime?
             let env = SearchUserEnvironment(locale: locale,
                                             region: region,
                                             updateChannel: SearchUpdateChannel.release,
                                             distributionId: "",    // Confirmed with AS: leave empty, no distr on iOS
                                             experiment: "",        // Confirmed with AS: leave empty
                                             appName: .firefoxIos,
                                             version: AppInfo.appVersion,
                                             deviceType: deviceType)
=======
            let deviceType: SearchDeviceType = UIDevice.current.userInterfaceIdiom == .pad ? .tablet : .smartphone
            // TODO: [FXIOS-11885] What happens if the locale or region changes during app runtime?
            let env = SearchUserEnvironment(locale: locale,
                                            region: region,
                                            updateChannel: SearchUpdateChannel.release,
                                            distributionId: "",    // Confirmed with AS: leave empty, no distr on iOS
                                            experiment: "",        // Confirmed with AS: leave empty
                                            appName: .firefoxIos,
                                            version: AppInfo.appVersion,
                                            deviceType: deviceType)
>>>>>>> dd1953509 (Refactor FXIOS-11428 [SEC] [WIP] Search engine telemetry updates (#25957))

             let filtered = try engineSelector.filterEngineConfiguration(userEnvironment: env)
             completion(filtered, nil)
         } catch {
             completion(nil, error)
         }
    }
}
