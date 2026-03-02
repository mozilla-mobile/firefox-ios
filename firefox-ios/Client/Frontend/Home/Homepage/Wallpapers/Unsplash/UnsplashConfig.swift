// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Reads Unsplash API credentials from a bundled JSON file.
/// The file `UnsplashConfig.json` must be added to the Xcode project's
/// Copy Bundle Resources build phase. It is gitignored and never committed.
struct UnsplashConfig: Codable {
    let appId: String
    let accessKey: String
    let secretKey: String

    /// Loads the config from the bundled `UnsplashConfig.json`.
    /// Returns nil if the file is missing or malformed.
    static func load() -> UnsplashConfig? {
        guard let url = Bundle.main.url(forResource: "UnsplashConfig", withExtension: "json") else {
            return nil
        }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(UnsplashConfig.self, from: data)
    }
}
