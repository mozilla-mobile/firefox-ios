// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

protocol PocketDataAdaptor {
    @MainActor
    func getPocketData() -> [PocketStory]
}

protocol PocketDelegate: AnyObject {
    func didLoadNewData()
}

@MainActor
final class PocketDataAdaptorImplementation: PocketDataAdaptor, FeatureFlaggable, Sendable, Notifiable {
    let notificationCenter: NotificationProtocol
    private let pocketAPI: PocketStoriesProviding
    private let storyProvider: StoryProvider
    private var pocketStories = [PocketStory]()

    weak var delegate: PocketDelegate?

    init(pocketAPI: PocketStoriesProviding,
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.pocketAPI = pocketAPI
        self.notificationCenter = notificationCenter
        self.storyProvider = StoryProvider(pocketAPI: pocketAPI)
        setupNotifications(forObserver: self, observing: [UIApplication.didBecomeActiveNotification])

        Task {
            await updatePocketSites()
        }
    }

    func getPocketData() -> [PocketStory] {
        return pocketStories
    }

    func setDelegate(_ delegate: PocketDelegate?) {
        self.delegate = delegate
    }

    private func updatePocketSites() async {
        let stories = await storyProvider.fetchPocketStories()
        pocketStories = stories
        delegate?.didLoadNewData()
    }
}

extension PocketDataAdaptorImplementation {
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
