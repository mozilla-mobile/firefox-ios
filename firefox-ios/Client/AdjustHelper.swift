// swiftlint:disable comment_spacing file_header
//// This Source Code Form is subject to the terms of the Mozilla Public
//// License, v. 2.0. If a copy of the MPL was not distributed with this
//// file, You can obtain one at http://mozilla.org/MPL/2.0/
//
//import Common
//import Foundation
//import Adjust
//import Shared
//
//final class AdjustHelper: NSObject, FeatureFlaggable {
//    private static let adjustAppTokenKey = "AdjustAppToken"
//    private let profile: Profile
//    private let telemetryHelper: AdjustTelemetryProtocol
//
//    init(profile: Profile,
//         telemetryHelper: AdjustTelemetryProtocol = AdjustTelemetryHelper()) {
//        self.profile = profile
//        self.telemetryHelper = telemetryHelper
//        let sendUsageData = profile.prefs.boolForKey(AppConstants.prefSendUsageData) ?? true
//
//        // This is required for adjust to work properly with ASA and we avoid directly disabling
//        // third-party sharing as there is a specific method provided to us by adjust for that.
//        // Note: These settings are persisted on the adjust backend as well
//        if sendUsageData {
//            if let adjustThirdPartySharing = ADJThirdPartySharing(isEnabledNumberBool: true) {
//                Adjust.trackThirdPartySharing(adjustThirdPartySharing)
//            }
//        } else {
//            Adjust.disableThirdPartySharing()
//        }
//    }
//
//    func setupAdjust() {
//        guard let config = getConfig() else { return }
//
//        // Always initialize Adjust if we have a config - otherwise we cannot enable/disable it later. Their SDK must be
//        // initialized through appDidFinishLaunching otherwise it will be in a bad state.
//        Adjust.appDidLaunch(config)
//
//        AdjustHelper.setEnabled(shouldEnable)
//    }
//
//    /// Used to enable or disable Adjust SDK and it's features.
//    /// If user has disabled Send Anonymous Usage Data then we ask Adjust to erase the user's data as well.
//    static func setEnabled(_ enabled: Bool) {
//        Adjust.setEnabled(enabled)
//
//        if !enabled {
//            Adjust.disableThirdPartySharing()
//            Adjust.gdprForgetMe()
//        }
//    }
//
    // MARK: - Private
//
//    private func getConfig() -> ADJConfig? {
//        let bundle = AppInfo.applicationBundle
//        guard let appToken = bundle.object(forInfoDictionaryKey: AdjustHelper.adjustAppTokenKey) as? String,
//                !appToken.isEmpty else {
//            return nil
//        }
//
//        let isProd = featureFlags.isCoreFeatureEnabled(.adjustEnvironmentProd)
//        let environment = isProd ? ADJEnvironmentProduction : ADJEnvironmentSandbox
//        let config = ADJConfig(appToken: appToken, environment: environment)
//        config?.logLevel = isProd ? ADJLogLevelSuppress : ADJLogLevelDebug
//
//        // Record attribution changes
//        // https://help.adjust.com/en/article/ios-sdk-adjconfig-class#set-up-delegate
//        config?.delegate = (self as AdjustHelper)
//
//        return config
//    }
//
//    /// Return true if Adjust should be enabled. If the user has disabled the Send Anonymous Usage Data 
//    /// then we only do one ping to get the attribution and turn it off (i.e. we only enable it if we
//    /// have not seen the attribution data yet).
//    private var shouldEnable: Bool {
//        return shouldTrackRetention || !hasAttribution
//    }
//
//    /// Return true if retention (session) tracking should be enabled.
//    /// This follows the Send Anonymous Usage Data setting.
//    private var shouldTrackRetention: Bool {
//        return profile.prefs.boolForKey(AppConstants.prefSendUsageData) ?? true
//    }
//
    // MARK: - UserDefaults
//
//    private enum UserDefaultsKey: String {
//        case hasAttribution = "com.moz.adjust.hasAttribution.key"
//    }
//
//    private var hasAttribution: Bool {
//        get { UserDefaults.standard.object(forKey: UserDefaultsKey.hasAttribution.rawValue) as? Bool ?? false }
//        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.hasAttribution.rawValue) }
//    }
//}
//
// MARK: - AdjustDelegate
//extension AdjustHelper: AdjustDelegate {
//    /// This is called when Adjust has figured out the attribution. It will call us with a summary
//    /// of all the things it knows. Like the campaign ID. We simply save a boolean that attribution
//    /// has changed so we know the single attribution ping to Adjust was done.
//    ///
//    /// We also disable Adjust based on the Send Anonymous Usage Data setting.
//    func adjustAttributionChanged(_ attribution: ADJAttribution?) {
//        hasAttribution = true
//        if !shouldEnable {
//            AdjustHelper.setEnabled(false)
//        }
//
//        telemetryHelper.setAttributionData(attribution)
//    }
//
//    func adjustDeeplinkResponse(_ deeplink: URL?) -> Bool {
//        guard let url = deeplink else { return true }
//
//        // Send telemetry if url is not nil
//        let attribution = Adjust.attribution()
//        telemetryHelper.sendDeeplinkTelemetry(url: url, attribution: attribution)
//        return true
//    }
//}
// swiftlint:enable comment_spacing file_header
