// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// Unsplash API credentials.
///
/// Key resolution priority:
/// 1. **CI/CD env vars** — set in Bitrise (or any CI) as secret environment variables:
///    - `WALLPAPER_UNSPLASH_APP_ID`
///    - `WALLPAPER_UNSPLASH_ACCESS_KEY`  ← required; others are optional
///    - `WALLPAPER_UNSPLASH_SECRET_KEY`
/// 2. **Bundled JSON** — `UnsplashConfig.json` in Copy Bundle Resources (gitignored).
/// 3. **Feature Flags debug UI** — Settings → Feature Flags → Wallpaper Provider.
///    Stored in UserDefaults, never committed.
/// 4. **Local placeholder** — edit `placeholder*` constants below for quick dev testing.
///
/// **Do NOT commit real keys.**
struct UnsplashConfig: Codable {
    let appId: String
    let accessKey: String
    let secretKey: String

    // MARK: - Bitrise / CI Environment Variable Names
    static let envAppId     = "WALLPAPER_UNSPLASH_APP_ID"
    static let envAccessKey = "WALLPAPER_UNSPLASH_ACCESS_KEY"
    static let envSecretKey = "WALLPAPER_UNSPLASH_SECRET_KEY"

    // MARK: - Local Testing Placeholders
    private static let placeholderAppId     = "REPLACE_ME_APP_ID"
    private static let placeholderAccessKey = "REPLACE_ME_ACCESS_KEY"
    private static let placeholderSecretKey = "REPLACE_ME_SECRET_KEY"

    /// Returns a configured `UnsplashConfig` using the first available source, or `nil`.
    static func load() -> UnsplashConfig? {
        // 1. CI/CD environment variables (Bitrise secret env vars)
        let env = ProcessInfo.processInfo.environment
        let ciAccessKey = env[envAccessKey] ?? ""
        if !ciAccessKey.isEmpty {
            return UnsplashConfig(
                appId: env[envAppId] ?? "",
                accessKey: ciAccessKey,
                secretKey: env[envSecretKey] ?? ""
            )
        }

        // 2. Bundled JSON (gitignored, for local dev with real keys)
        if let url = Bundle.main.url(forResource: "UnsplashConfig", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let config = try? JSONDecoder().decode(UnsplashConfig.self, from: data) {
            return config
        }

        // 3. Feature Flags debug settings (UserDefaults)
        let defaults = UserDefaults.standard
        let debugAccessKey = defaults.string(forKey: PrefsKeys.CustomTheming.unsplashAccessKey) ?? ""
        if !debugAccessKey.isEmpty {
            return UnsplashConfig(
                appId: defaults.string(forKey: PrefsKeys.CustomTheming.unsplashAppId) ?? "",
                accessKey: debugAccessKey,
                secretKey: defaults.string(forKey: PrefsKeys.CustomTheming.unsplashSecretKey) ?? ""
            )
        }

        // 4. Local placeholder (never commit real keys)
        guard placeholderAccessKey != "REPLACE_ME_ACCESS_KEY" else { return nil }
        return UnsplashConfig(appId: placeholderAppId, accessKey: placeholderAccessKey, secretKey: placeholderSecretKey)
    }
}
