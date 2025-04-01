// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@preconcurrency import class MozillaAppServices.SuggestStore
import class MozillaAppServices.RemoteSettingsService
import class MozillaAppServices.SuggestStoreBuilder
import class MozillaAppServices.Viaduct
import enum MozillaAppServices.SuggestionProvider
import struct MozillaAppServices.SuggestIngestionConstraints
import struct MozillaAppServices.SuggestionQuery

@preconcurrency
public protocol RustFirefoxSuggestProtocol {
    /// Downloads and stores new Firefox Suggest suggestions.
    func ingest() async throws

    /// Searches the store for matching suggestions.
    func query(
        _ keyword: String,
        providers: [SuggestionProvider],
        limit: Int32
    ) async throws -> [RustFirefoxSuggestion]

    /// Interrupts any ongoing queries for suggestions.
    func interruptReader()

    /// Interrupts all ongoing operations.
    func interruptEverything()
}

/// Wraps the synchronous Rust `SuggestStore` binding to execute
/// blocking operations on a dispatch queue.
@preconcurrency
public class RustFirefoxSuggest: RustFirefoxSuggestProtocol {
    private let store: SuggestStore

    // Using a pair of serial queues lets read and write operations run
    // without blocking one another.
    private let writerQueue = DispatchQueue(label: "RustFirefoxSuggest.writer")
    private let readerQueue = DispatchQueue(label: "RustFirefoxSuggest.reader")

    public init(
        dataPath: String,
        cachePath: String,
        remoteSettingsService: RemoteSettingsService
    ) throws {
        var builder = SuggestStoreBuilder()
            .dataPath(path: dataPath)

        builder = builder.remoteSettingsService(rsService: remoteSettingsService)

        store = try builder.build()
    }

    public func ingest() async throws {
        // Ensure that the Rust networking stack has been initialized before
        // downloading new suggestions. This is safe to call multiple times.
        Viaduct.shared.useReqwestBackend()

        try await withCheckedThrowingContinuation { continuation in
            writerQueue.async(qos: .utility) {
                do {
                    _ = try self.store.ingest(constraints: SuggestIngestionConstraints())
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func query(
        _ keyword: String,
        providers: [SuggestionProvider],
        limit: Int32
    ) async throws -> [RustFirefoxSuggestion] {
        return try await withCheckedThrowingContinuation { continuation in
            readerQueue.async(qos: .userInitiated) {
                do {
                    let suggestions = try self.store.query(query: SuggestionQuery(
                        keyword: keyword,
                        providers: providers,
                        limit: limit
                    )).compactMap(RustFirefoxSuggestion.init)
                    continuation.resume(returning: suggestions)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func interruptReader() {
        store.interrupt()
    }

    public func interruptEverything() {
        store.interrupt(kind: .readWrite)
    }
}
