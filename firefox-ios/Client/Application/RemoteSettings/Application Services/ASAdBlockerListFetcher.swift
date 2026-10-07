// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Common

protocol AdBlockerListFetcherProtocol: Sendable {
    /// Fetches the ad-blocker content blocking list from the `tracking-protection-lists-ios`
    /// Remote Settings collection.
    /// - Returns: the WebKit content-rule JSON as a string, or nil if it could not be fetched.
    func fetchAdBlockerListJSON() async -> String?

    /// Returns the record IDs of all available regional ad-block lists (e.g. `ad-block-regional-de`).
    func fetchAvailableRegionalListIDs() async -> [String]

    /// Fetches the WebKit content-rule JSON for a single regional ad-block record.
    func fetchRegionalListJSON(recordID: String) async -> String?
}

/// Fetches the single `ad-blocker` record (and its attachment) from the
/// `tracking-protection-lists-ios` Remote Settings collection through Application Services.
/// All other content blocking lists are loaded from local JSON and are unaffected by this fetcher.
/// TODO(FXIOS-16233): Migrate the existing ETP lists to also use the AS implementation of RS.
final class ASAdBlockerListFetcher: AdBlockerListFetcherProtocol {
    /// Identifier of the ad-blocker record within the `tracking-protection-lists-ios` collection.
    static let adBlockerRecordID = "ad-block"

    /// Dedicated queue for the blocking Remote Settings FFI calls. `getRecords(syncIfEmpty:)` and
    /// `getAttachment(record:)` are synchronous Rust calls that can sync over the network and hit
    /// disk, so they must never run on the main thread or on the Swift concurrency cooperative
    /// thread pool — blocking the former hangs the UI, blocking the latter can starve every other
    /// task. `fetchAdBlockerListJSON()` hops onto this queue to keep that work fully off both.
    private static let fetchQueue = DispatchQueue(
        label: "org.mozilla.ios.ASAdBlockerListFetcher",
        qos: .utility
    )

    // The client is created lazily (not at init) so constructing this fetcher never touches
    // AppContainer. This keeps `ContentBlocker` construction independent of app bootstrap.
    private let clientProvider: @Sendable () -> RemoteSettingsClientProtocol?
    private let logger: Logger

    init(
        clientProvider: @escaping @Sendable () -> RemoteSettingsClientProtocol? = {
            ASRemoteSettingsCollection.trackingProtectionLists.makeClient()
        },
        logger: Logger = DefaultLogger.shared
    ) {
        self.clientProvider = clientProvider
        self.logger = logger
    }

    static let regionalRecordPrefix = "ad-block-regional-"

    func fetchAdBlockerListJSON() async -> String? {
        return await withCheckedContinuation { continuation in
            Self.fetchQueue.async { [self] in
                continuation.resume(returning: loadAdBlockerListJSON())
            }
        }
    }

    func fetchAvailableRegionalListIDs() async -> [String] {
        return await withCheckedContinuation { continuation in
            Self.fetchQueue.async { [self] in
                continuation.resume(returning: loadAvailableRegionalListIDs())
            }
        }
    }

    func fetchRegionalListJSON(recordID: String) async -> String? {
        return await withCheckedContinuation { continuation in
            Self.fetchQueue.async { [self] in
                continuation.resume(returning: loadRecordJSON(recordID: recordID))
            }
        }
    }

    private func loadAdBlockerListJSON() -> String? {
        return loadRecordJSON(recordID: Self.adBlockerRecordID)
    }

    private func loadAvailableRegionalListIDs() -> [String] {
        guard let client = clientProvider(), let records = client.getRecords(syncIfEmpty: true) else {
            logger.log("Regional list discovery failed: nil client or no records.",
                       level: .warning,
                       category: .remoteSettings)
            return []
        }

        return records
            .filter { $0.id.hasPrefix(Self.regionalRecordPrefix) && !$0.deleted }
            .map { $0.id }
            .sorted()
    }

    private func loadRecordJSON(recordID: String) -> String? {
        guard let client = clientProvider(), let records = client.getRecords(syncIfEmpty: true) else {
            logger.log("Ad-blocker list fetch failed: nil client or no records.",
                       level: .warning,
                       category: .remoteSettings)
            return nil
        }

        guard let record = records.first(where: { $0.id == recordID }) else {
            logger.log("No record found for \(recordID) in tracking protection collection.",
                       level: .warning,
                       category: .remoteSettings)
            return nil
        }

        guard let data = try? client.getAttachment(record: record),
              let json = String(data: data, encoding: .utf8),
              !json.isEmpty else {
            logger.log("Failed to fetch attachment for record \(record.id).",
                       level: .warning,
                       category: .remoteSettings)
            return nil
        }

        return json
    }
}
