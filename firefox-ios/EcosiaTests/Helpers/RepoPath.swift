// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Locates the repository root from a test file's `#filePath`, so tests can read
/// source/config files directly off disk rather than as bundled test resources.
/// Used by tests that assert a Firefox-fork customization is still present after
/// an upstream merge, where the thing being checked isn't observable at runtime.
enum RepoPath {
    static func root(from filePath: String = #filePath) -> String {
        var url = URL(fileURLWithPath: filePath)
        while url.pathComponents.count > 1 {
            url.deleteLastPathComponent()
            if FileManager.default.fileExists(atPath: url.appendingPathComponent("firefox-ios").path) {
                return url.path
            }
        }
        fatalError("Could not locate repo root from \(filePath)")
    }
}
