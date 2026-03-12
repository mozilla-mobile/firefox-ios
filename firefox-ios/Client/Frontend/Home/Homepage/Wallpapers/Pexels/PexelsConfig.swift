// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// Pexels API credentials.
///
/// Key resolution priority:
/// 1. **CI/CD env var** — set in Bitrise (or any CI) as a secret environment variable:
///    - `WALLPAPER_PEXELS_API_KEY`
/// 2. **Bundled JSON** — `PexelsConfig.json` in Copy Bundle Resources (gitignored).
/// 3. **Feature Flags debug UI** — Settings → Feature Flags → Wallpaper Provider.
///    Stored in UserDefaults, never committed.
/// 4. **Local placeholder** — edit `placeholderApiKey` below for quick dev testing.
///
/// **Do NOT commit real keys.**
struct PexelsConfig: Codable {
    let apiKey: String

    // MARK: - Bitrise / CI Environment Variable Name
    static let envApiKey = "WALLPAPER_PEXELS_API_KEY"

    // MARK: - Local Testing Placeholder
    private static let placeholderApiKey = "REPLACE_ME_PEXELS_API_KEY"

    /// Returns a configured `PexelsConfig` using the first available source, or `nil`.
    static func load() -> PexelsConfig? {
        // 1. CI/CD environment variable (Bitrise secret env var)
        let ciKey = ProcessInfo.processInfo.environment[envApiKey] ?? ""
        if !ciKey.isEmpty { return PexelsConfig(apiKey: ciKey) }

        // 2. Bundled JSON (gitignored, for local dev with real key)
        if let url = Bundle.main.url(forResource: "PexelsConfig", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let config = try? JSONDecoder().decode(PexelsConfig.self, from: data) {
            return config
        }

        // 3. Feature Flags debug settings (UserDefaults)
        let debugKey = UserDefaults.standard.string(forKey: PrefsKeys.CustomTheming.pexelsApiKey) ?? ""
        if !debugKey.isEmpty { return PexelsConfig(apiKey: debugKey) }

        // 4. Local placeholder (never commit real key)
        guard placeholderApiKey != "REPLACE_ME_PEXELS_API_KEY" else { return nil }
        return PexelsConfig(apiKey: placeholderApiKey)
    }
}
