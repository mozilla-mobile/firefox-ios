// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import QuickAnswersKit

/// A `QuickAnswersConfigFetcher` that loads the model prompt from Remote Settings.
/// NOTE: This file should be under QuickAnswersKit near the other fetcher implementations.
/// Since all of RS classes are in Client, we can't move it there yet.
struct RemoteQuickAnswersConfigFetcher: QuickAnswersConfigFetcher {
    /// `getRecords(syncIfEmpty:)` is a synchronous Rust call that can sync over the network and hit
    /// disk, so it must never run on the main thread nor on the Swift concurrency cooperative pool.
    private static let fetchQueue = DispatchQueue(
        label: "org.mozilla.ios.RemoteQuickAnswersConfigFetcher",
        qos: .userInitiated
    )

    let model: QuickAnswersModel
    private let remoteConfig: ASAIRemoteConfig

    init(model: QuickAnswersModel, remoteConfig: ASAIRemoteConfig = ASAIRemoteConfig()) {
        self.model = model
        self.remoteConfig = remoteConfig
    }

    func fetch() async throws -> QuickAnswersConfig {
        let instructions: String? = await withCheckedContinuation { continuation in
            Self.fetchQueue.async {
                continuation.resume(returning: remoteConfig.fetchPrompt(named: recordName))
            }
        }
        return QuickAnswersConfig(model: model, instructions: instructions ?? "")
    }

    private var recordName: String {
        return "quick-answers-\(model.rawValue)"
    }
}
