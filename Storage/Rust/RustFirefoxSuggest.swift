// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

/// An actor that wraps the synchronous Rust `SuggestStore` binding to execute
/// blocking operations on the default global concurrent executor.
public actor RustFirefoxSuggest {
    private let store: SuggestStore

    public init(databasePath: String, remoteSettingsConfig: RemoteSettingsConfig? = nil) throws {
        store = try SuggestStore(path: databasePath, settingsConfig: remoteSettingsConfig)
    }

    /// Downloads and stores new Firefox Suggest suggestions.
    public func ingest() async throws {
        // Ensure that the Rust networking stack has been initialized before
        // downloading new suggestions. This is safe to call multiple times.
        Viaduct.shared.useReqwestBackend()

        try store.ingest(constraints: SuggestIngestionConstraints())
    }

    /// Searches the store for matching suggestions.
    public func query(
        _ keyword: String,
        includeSponsored: Bool,
        includeNonSponsored: Bool
    ) async throws -> [RustFirefoxSuggestion] {
        return try store.query(query: SuggestionQuery(
            keyword: keyword,
            includeSponsored: includeSponsored,
            includeNonSponsored: includeNonSponsored
        )).compactMap(RustFirefoxSuggestion.init)
    }

    /// Interrupts any ongoing queries for suggestions.
    public nonisolated func interruptReader() {
        store.interrupt()
    }
}
