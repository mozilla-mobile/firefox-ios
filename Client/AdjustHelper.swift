// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import AdjustSdk
import Shared

private let log = Logger.browserLogger

final class AdjustHelper {

    private static let adjustAppTokenKey = "AdjustAppToken"

    static func setupAdjust() {
        let bundle = AppInfo.applicationBundle
        guard let appToken = bundle.object(forInfoDictionaryKey: AdjustHelper.adjustAppTokenKey) as? String, !appToken.isEmpty else {
            log.debug("Not enabling Adjust; Not configured in Info.plist")
            return
        }

        let isProd = FeatureFlagsManager.shared.isFeatureActiveForBuild(.adjustEnvironmentProd)
        let environment = isProd ? ADJEnvironmentProduction : ADJEnvironmentSandbox
        let adjustConfig = ADJConfig(appToken: appToken, environment: environment)

        Adjust.appDidLaunch(adjustConfig)
    }
}
