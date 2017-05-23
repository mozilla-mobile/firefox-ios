/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Only include Adjust SDK in Focus and NOT in Klar builds.
#if FOCUS
    import Foundation
    import AdjustSdk

    private let AdjustAppTokenKey = "AppToken"

    private enum AdjustEnvironment: String {
        case sandbox = "sandbox"
        case production = "production"
    }

    private struct AdjustSettings {
        var appToken: String
        var environment: AdjustEnvironment

        init?(contentsOf url: URL) {
            guard let config = NSDictionary(contentsOf: url), let appToken = config.object(forKey: AdjustAppTokenKey) as? String else {
                return nil
            }

            self.appToken = appToken
            #if DEBUG
                self.environment = AdjustEnvironment.sandbox
            #else
                self.environment = AdjustEnvironment.production
            #endif
        }
    }

    class AdjustIntegration {
        fileprivate static var adjustSettings: AdjustSettings?

        public static func applicationDidFinishLaunching() {
            if let url = Bundle.main.url(forResource: AppInfo.config.adjustFile, withExtension: "plist"),
               let settings = AdjustSettings(contentsOf: url) {
                adjustSettings = settings

                let config = ADJConfig(appToken: settings.appToken, environment: settings.environment.rawValue)
                #if DEBUG
                    config?.logLevel = ADJLogLevelDebug
                #endif

                Adjust.appDidLaunch(config)
            }
        }

        public static var enabled: Bool {
            get {
                return Adjust.isEnabled()
            }
            set {
                Adjust.setEnabled(newValue)
            }
        }
    }
#endif
