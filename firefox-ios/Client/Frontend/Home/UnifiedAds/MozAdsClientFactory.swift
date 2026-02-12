// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices

protocol MozAdsClientFactory {
    func createClient() -> MozAdsClientProtocol
}

final class DefaultMozAdsClientFactory: MozAdsClientFactory, FeatureFlaggable {
    func createClient() -> MozAdsClientProtocol {
        if featureFlags.isCoreFeatureEnabled(.useStagingUnifiedAdsAPI) {
            return RustAdsClient.staging
        }
        return RustAdsClient.production
    }
}
