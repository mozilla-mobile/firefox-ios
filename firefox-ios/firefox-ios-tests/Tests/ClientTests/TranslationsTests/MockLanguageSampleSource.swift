// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

/// Test helper that simulates JS evaluation for language sample extraction.
final class MockLanguageSampleSource: LanguageSampleSource, @unchecked Sendable {
    var mockResult: Any?
    var mockError: Error?

    @MainActor
    func getLanguageSample(scriptEvalExpression: String) async throws -> String? {
        if let error = mockError { throw error }
        return mockResult as? String
    }
}
