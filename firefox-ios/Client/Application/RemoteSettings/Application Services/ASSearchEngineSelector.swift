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

            var searchResultsConfig = try engineSelector.filterEngineConfiguration(userEnvironment: env)

            // We want to be sure that our default engines list is always sorted with the default in position 0
            // This is important in the case of new installs, for example, where the user does not have any
            // search engine ordering preferences saved. Generally the `engines` should already be sorted this
            // way but this code should be very fast on this small collection so we ensure the sort order here.
            searchResultsConfig.sortDefaultEngineToIndex0()

            completion(searchResultsConfig, nil)
        } catch {
            completion(nil, error)
        }
    }
}

extension RefinedSearchConfig {
    /// Ensures that the default engine is always at position 0 in the engines list.
    /// Per AS team we should not rely on the provided sort order of `engines`.
    mutating func sortDefaultEngineToIndex0() {
        guard let defaultEngineID = appDefaultEngineId,
              let idx = engines.firstIndex(where: { $0.identifier == defaultEngineID }),
              idx != 0 else { return }
        let engine = engines[idx]
        engines.remove(at: idx)
        engines.insert(engine, at: 0)
    }
}
