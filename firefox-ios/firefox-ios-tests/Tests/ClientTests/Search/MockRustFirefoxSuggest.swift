// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import MozillaAppServices

class MockRustFirefoxSuggest: RustFirefoxSuggestProtocol {
    func ingest(emptyOnly: Bool) async throws {
    }
    func query(
        _ keyword: String,
        providers: [SuggestionProvider],
        limit: Int32
    ) async throws -> [RustFirefoxSuggestion] {
        var suggestions = [RustFirefoxSuggestion]()
        if providers.contains(.amp) {
            suggestions.append(RustFirefoxSuggestion(
                title: "Mozilla",
                url: URL(string: "https://mozilla.org")!,
                isSponsored: true,
                iconImage: nil
            ))
        }
        if providers.contains(.wikipedia) {
            suggestions.append(RustFirefoxSuggestion(
                title: "California",
                url: URL(string: "https://wikipedia.org/California")!,
                isSponsored: false,
                iconImage: nil
            ))
        }
        return suggestions
    }
    func interruptReader() {
    }
    func interruptEverything() {
    }
}
