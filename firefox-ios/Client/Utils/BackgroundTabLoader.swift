// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Storage
import Shared

/// `BackgroundTabLoader` loads tabs from users adding tabs to "Load in Background" via the share sheet. In other words, the `ShareViewController`
/// adds the tab to the `Profile.TabQueue`, and the `BackgroundTabLoader` dequeues them to be added as tabs in the application.
protocol BackgroundTabLoader {
    /// Load the background tabs in the application using deeplinks
    func loadBackgroundTabs()
}

final class DefaultBackgroundTabLoader: BackgroundTabLoader {
    private var tabQueue: TabQueue
    private var backgroundQueue: DispatchQueueInterface
    private var applicationHelper: ApplicationHelper

    init(tabQueue: TabQueue,
         applicationHelper: ApplicationHelper = DefaultApplicationHelper(),
         backgroundQueue: DispatchQueueInterface = DispatchQueue.global()) {
        self.tabQueue = tabQueue
        self.applicationHelper = applicationHelper
        self.backgroundQueue = backgroundQueue
    }

    func loadBackgroundTabs() {
        // Make sure we load queued tabs on a background thread
        backgroundQueue.async { [weak self] in
            guard let self = self else { return }
            self.dequeueQueuedTabs()
        }
    }

    private func dequeueQueuedTabs() {
        tabQueue.getQueuedTabs { [weak self] urls in
            guard let self = self else { return }
            // This assumes that the DB returns rows in a sane order.
            guard !urls.isEmpty else { return }

            // Open queued urls
            let queuedURLs = urls.compactMap { $0.url.asURL }
            if !queuedURLs.isEmpty {
                self.open(urls: queuedURLs)
            }

            // Clear after making an attempt to open. We're making a bet that
            // it's better to run the risk of perhaps opening twice on a crash,
            // rather than losing data.
            self.tabQueue.clearQueuedTabs()
        }
    }

    private func open(urls: [URL]) {
        for urlToOpen in urls {
            let urlString = URL.mozInternalScheme + "://open-url?url=\(urlToOpen)"
            guard let url = URL(string: urlString) else { continue }
            applicationHelper.open(url)
        }
    }
}
