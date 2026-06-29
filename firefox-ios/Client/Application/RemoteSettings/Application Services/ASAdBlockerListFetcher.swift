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
}

/// Fetches the single `ad-blocker` record (and its attachment) from the
/// `tracking-protection-lists-ios` Remote Settings collection through Application Services.
/// All other content blocking lists are loaded from local JSON and are unaffected by this fetcher.
final class ASAdBlockerListFetcher: AdBlockerListFetcherProtocol {
    /// Identifier of the ad-blocker record within the `tracking-protection-lists-ios` collection.
    static let adBlockerRecordID = "ad-block.json"

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

    func fetchAdBlockerListJSON() async -> String? {
        guard let client = clientProvider(), let records = client.getRecords(syncIfEmpty: true) else {
            logger.log("Ad-blocker list fetch failed: nil client or no records.",
                       level: .warning,
                       category: .remoteSettings)
            return nil
        }

        guard let record = records.first(where: { $0.attachment?.filename == Self.adBlockerRecordID }) else {
            logger.log("No ad-blocker record found in tracking protection collection.",
                       level: .warning,
                       category: .remoteSettings)
            return nil
        }

        // getAttachment is a synchronous Rust FFI call; it runs off the main thread because this
        // method is reached through an async, non-MainActor context.
        guard let data = try? client.getAttachment(record: record),
              let json = String(data: data, encoding: .utf8) else {
            logger.log("Failed to fetch ad-blocker list attachment for record \(record.id).",
                       level: .warning,
                       category: .remoteSettings)
            return nil
        }

        return json
    }
}
