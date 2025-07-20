// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

protocol PocketDataAdaptor {
    @MainActor
    func getMerinoData() -> [MerinoStory]
}

protocol PocketDelegate: AnyObject {
    @MainActor
    func didLoadNewData()
}

@MainActor
final class PocketDataAdaptorImplementation: PocketDataAdaptor, FeatureFlaggable, Notifiable {
    let notificationCenter: NotificationProtocol
    private let merinoAPI: MerinoStoriesProviding
    private let storyProvider: StoryProvider
    private var merinoStories = [MerinoStory]()

    weak var delegate: PocketDelegate?

    init(merinoAPI: MerinoStoriesProviding,
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.merinoAPI = merinoAPI
        self.notificationCenter = notificationCenter
        self.storyProvider = StoryProvider(merinoAPI: merinoAPI)
        setupNotifications(forObserver: self, observing: [UIApplication.didBecomeActiveNotification])

        Task {
            await updatePocketSites()
        }
    }

    func getMerinoData() -> [MerinoStory] {
        return merinoStories
    }

    private func updatePocketSites() async {
        let stories = await storyProvider.fetchStories()
        merinoStories = stories
        delegate?.didLoadNewData()
    }

    // MARK: - Notifiable

    nonisolated func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIApplication.willEnterForegroundNotification:
            Task {
                await updatePocketSites()
            }
        default: break
        }
    }
}
