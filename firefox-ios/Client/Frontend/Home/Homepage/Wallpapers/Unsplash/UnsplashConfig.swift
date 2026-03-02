// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Reads Unsplash API credentials from a local JSON file that is not committed to source control.
/// The file `UnsplashConfig.json` should be placed at the root of the `firefox-ios` directory.
struct UnsplashConfig: Codable {
    let appId: String
    let accessKey: String
    let secretKey: String

    /// Loads the config from the bundled `UnsplashConfig.json` file.
    /// Returns nil if the file is missing or malformed.
    static func load() -> UnsplashConfig? {
        // Try loading from main bundle first (for when it's added to the Xcode project resources)
        if let url = Bundle.main.url(forResource: "UnsplashConfig", withExtension: "json") {
            return loadFrom(url: url)
        }

        // Fallback: try loading from the app's documents or project directory
        // This handles development scenarios where the file is at the project root
        let fileManager = FileManager.default
        let possiblePaths = [
            // In the app bundle's resource directory
            Bundle.main.bundlePath + "/UnsplashConfig.json",
        ]

        for path in possiblePaths {
            if fileManager.fileExists(atPath: path) {
                return loadFrom(url: URL(fileURLWithPath: path))
            }
        }

        return nil
    }

    private static func loadFrom(url: URL) -> UnsplashConfig? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(UnsplashConfig.self, from: data)
    }
}
