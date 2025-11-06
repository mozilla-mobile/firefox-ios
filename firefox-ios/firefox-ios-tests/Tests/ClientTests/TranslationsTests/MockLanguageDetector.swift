// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Foundation
@testable import Client

/// Test helper that simulates language detection.
final class MockLanguageDetector: LanguageDetectorProvider, @unchecked Sendable {
    var detectLanguageCallCount = 0
    func detectLanguage(from source: LanguageSampleSource) async throws -> String? {
        detectLanguageCallCount += 1
        return "ja"
    }
}
