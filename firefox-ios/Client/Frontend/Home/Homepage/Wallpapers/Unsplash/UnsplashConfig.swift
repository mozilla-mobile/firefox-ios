// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// Unsplash API credentials.
///
/// The loader tries three sources in order:
/// 1. A bundled `UnsplashConfig.json` (added to Copy Bundle Resources, gitignored).
/// 2. Values saved locally via the Feature Flags debug settings (Settings → Feature Flags →
///    Custom Theming — Unsplash Keys). These are stored in UserDefaults and never committed.
/// 3. The placeholder constants below — edit them locally for quick testing.
///
/// **Do NOT commit real keys.** The placeholders and UserDefaults values are safe to commit.
struct UnsplashConfig: Codable {
    let appId: String
    let accessKey: String
    let secretKey: String

    // MARK: - Local Testing Placeholders
    // Replace these with your Unsplash API credentials for local dev/testing.
    // They are only used when UnsplashConfig.json and UserDefaults are both empty.
    private static let placeholderAppId     = "REPLACE_ME_APP_ID"
    private static let placeholderAccessKey = "REPLACE_ME_ACCESS_KEY"
    private static let placeholderSecretKey = "REPLACE_ME_SECRET_KEY"

    /// Loads config from the bundled JSON, then UserDefaults debug overrides,
    /// then placeholder constants. Returns `nil` if no real keys are available.
    static func load() -> UnsplashConfig? {
        // 1. Try bundled JSON first
        if let url = Bundle.main.url(forResource: "UnsplashConfig", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let config = try? JSONDecoder().decode(UnsplashConfig.self, from: data) {
            return config
        }

        // 2. Try values saved via Feature Flags debug settings
        let defaults = UserDefaults.standard
        let debugAppId = defaults.string(forKey: PrefsKeys.CustomTheming.unsplashAppId) ?? ""
        let debugAccessKey = defaults.string(forKey: PrefsKeys.CustomTheming.unsplashAccessKey) ?? ""
        let debugSecretKey = defaults.string(forKey: PrefsKeys.CustomTheming.unsplashSecretKey) ?? ""
        if !debugAccessKey.isEmpty {
            return UnsplashConfig(
                appId: debugAppId,
                accessKey: debugAccessKey,
                secretKey: debugSecretKey
            )
        }

        // 3. Fall back to placeholder constants (edit locally, don't commit real keys)
        guard placeholderAccessKey != "REPLACE_ME_ACCESS_KEY" else { return nil }
        return UnsplashConfig(
            appId: placeholderAppId,
            accessKey: placeholderAccessKey,
            secretKey: placeholderSecretKey
        )
    }
}
