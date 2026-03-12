// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// Pexels API credentials.
///
/// The loader tries three sources in order:
/// 1. A bundled `PexelsConfig.json` (added to Copy Bundle Resources, gitignored).
/// 2. The value saved via Feature Flags debug settings (Settings → Feature Flags →
///    Wallpaper Provider — Pexels API Key). Stored in UserDefaults, never committed.
/// 3. The placeholder constant below — edit locally for quick testing.
///
/// **Do NOT commit real keys.** The placeholders and UserDefaults values are safe to commit.
struct PexelsConfig: Codable {
    let apiKey: String

    // MARK: - Local Testing Placeholder
    // Replace with your Pexels API key for local dev/testing.
    // Only used when PexelsConfig.json and UserDefaults are both empty.
    private static let placeholderApiKey = "REPLACE_ME_PEXELS_API_KEY"

    /// Loads config from the bundled JSON, then UserDefaults debug override,
    /// then placeholder constant. Returns `nil` if no real key is available.
    static func load() -> PexelsConfig? {
        // 1. Try bundled JSON first
        if let url = Bundle.main.url(forResource: "PexelsConfig", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let config = try? JSONDecoder().decode(PexelsConfig.self, from: data) {
            return config
        }

        // 2. Try value saved via Feature Flags debug settings
        let debugKey = UserDefaults.standard.string(
            forKey: PrefsKeys.CustomTheming.pexelsApiKey
        ) ?? ""
        if !debugKey.isEmpty {
            return PexelsConfig(apiKey: debugKey)
        }

        // 3. Fall back to placeholder (edit locally, don't commit real key)
        guard placeholderApiKey != "REPLACE_ME_PEXELS_API_KEY" else { return nil }
        return PexelsConfig(apiKey: placeholderApiKey)
    }
}
