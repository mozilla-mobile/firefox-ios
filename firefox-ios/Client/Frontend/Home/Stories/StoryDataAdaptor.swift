// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

protocol StoryDataAdaptor {
    @MainActor
    func getMerinoData() -> [MerinoStory]
}

protocol StoryDelegate: AnyObject {
    @MainActor
    func didLoadNewData()
}

@MainActor
final class StoryDataAdaptorImplementation: StoryDataAdaptor, FeatureFlaggable, Notifiable {
    let notificationCenter: NotificationProtocol
    private let merinoAPI: MerinoStoriesProviding
    private let storyProvider: StoryProvider
    private var merinoStories = [MerinoStory]()

    weak var delegate: StoryDelegate?

    init(
        merinoAPI: MerinoStoriesProviding,
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.merinoAPI = merinoAPI
        self.notificationCenter = notificationCenter
        self.storyProvider = StoryProvider(merinoAPI: merinoAPI)
        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [UIApplication.didBecomeActiveNotification]
        )

        Task { [weak self] in
            await self?.updateMerinoSites()
        }
    }

    func getMerinoData() -> [MerinoStory] {
        return merinoStories
    }

    private func updateMerinoSites() async {
        let stories = await storyProvider.fetchHomepageStories()
        merinoStories = stories
        delegate?.didLoadNewData()
    }

    // MARK: - Notifiable
    nonisolated func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIApplication.willEnterForegroundNotification:
            Task { [weak self] in
                await self?.updateMerinoSites()
            }
        default: break
        }
    }
}
