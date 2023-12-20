// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

protocol PocketDataAdaptor {
    func getPocketData() -> [PocketStory]
}

protocol PocketDelegate: AnyObject {
    func didLoadNewData()
}

class PocketDataAdaptorImplementation: PocketDataAdaptor, FeatureFlaggable {
    var notificationCenter: NotificationProtocol
    private let pocketAPI: PocketStoriesProviding
    private let storyProvider: StoryProvider
    private var pocketStories = [PocketStory]()

    weak var delegate: PocketDelegate?

    // Used for unit tests since pocket use async/await
    private var dataCompletion: (() -> Void)?

    init(pocketAPI: PocketStoriesProviding,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         dataCompletion: (() -> Void)? = nil) {
        self.pocketAPI = pocketAPI
        self.notificationCenter = notificationCenter
        self.storyProvider = StoryProvider(pocketAPI: pocketAPI)
        self.dataCompletion = dataCompletion

        setupNotifications(forObserver: self, observing: [UIApplication.didBecomeActiveNotification])

        Task {
            await updatePocketSites()
        }
    }

    func getPocketData() -> [PocketStory] {
        return pocketStories
    }

    private func updatePocketSites() async {
        pocketStories = await storyProvider.fetchPocketStories()
        delegate?.didLoadNewData()
        dataCompletion?()
    }
}

extension PocketDataAdaptorImplementation: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIApplication.willEnterForegroundNotification:
            Task {
                await updatePocketSites()
            }
        default: break
        }
    }
}
