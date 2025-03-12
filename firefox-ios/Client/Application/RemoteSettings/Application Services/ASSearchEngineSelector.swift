// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Account
import Common
import Shared

final class ASSearchEngineSelector {
    private let engineSelector = SearchEngineSelector()
    private let service: RemoteSettingsService

    init(service: RemoteSettingsService) {
        self.service = service
    }

    func fetchSearchEngines(locale: String,
                            region: String,
                            completion: @escaping ((RefinedSearchConfig?, Error?) -> Void)) {
         do {
             try engineSelector.useRemoteSettingsServer(service: service, applyEngineOverrides: false)

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

             let filtered = try engineSelector.filterEngineConfiguration(userEnvironment: env)
             completion(filtered, nil)
         } catch {
             completion(nil, error)
         }
    }
}
