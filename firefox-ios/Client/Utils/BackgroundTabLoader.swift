// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Storage
import Shared

/// `BackgroundTabLoader` loads tabs from users adding tabs to "Load in Background" via the share sheet.
/// In other words, the `ShareViewController` adds the tab to the `Profile.TabQueue`, and the
/// `BackgroundTabLoader` dequeues them to be added as tabs in the application.
protocol BackgroundTabLoader {
    /// Load the background tabs in the application using deeplinks
    func loadBackgroundTabs()
}

final class DefaultBackgroundTabLoader: BackgroundTabLoader, Sendable {
    private let tabQueue: TabQueue
    private let applicationHelper: ApplicationHelper
    private let logger: Logger

    init(tabQueue: TabQueue,
         applicationHelper: ApplicationHelper = DefaultApplicationHelper(),
         logger: Logger = DefaultLogger.shared) {
        self.tabQueue = tabQueue
        self.applicationHelper = applicationHelper
        self.logger = logger
    }

    func loadBackgroundTabs() {
        Task { await dequeueQueuedTabs() }
    }

    private func dequeueQueuedTabs() async {
        let queuedTabs: [ShareItem]
        do {
            // `Deferred.upon` delivers on a global queue, so the read no longer
            // needs an explicit hop off the main thread.
            queuedTabs = try await tabQueue.getQueuedTabs()
        } catch {
            logger.log("Failed to read the background tab queue: \(error)",
                       level: .warning,
                       category: .tabs)
            return
        }

        // This assumes that the DB returns rows in a sane order.
        guard !queuedTabs.isEmpty else { return }

        // Open queued urls
        let queuedURLs = queuedTabs.compactMap { $0.url.asURL }
        if !queuedURLs.isEmpty {
            await open(urls: queuedURLs)
        }

        // Clear after making an attempt to open. We're making a bet that
        // it's better to run the risk of perhaps opening twice on a crash,
        // rather than losing data.
        tabQueue.clearQueuedTabs()
    }

    @MainActor
    private func open(urls: [URL]) {
        for urlToOpen in urls {
            let urlString = URL.mozInternalScheme + "://open-url?url=\(urlToOpen)"
            guard let url = URL(string: urlString) else { continue }
            applicationHelper.open(url)
        }
    }
}
