// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol PocketDataAdaptor {
    var onTapAction: ((IndexPath) -> Void)? { get set }

    func getPocketData() -> [PocketStandardCellViewModel]
}

protocol PocketDelegate: AnyObject {
    func didLoadNewData()
}

class PocketDataAdaptorImplementation: PocketDataAdaptor, FeatureFlaggable {

    var notificationCenter: NotificationProtocol

    private let pocketAPI: PocketStoriesProviding
    private let pocketSponsoredAPI: PocketSponsoredStoriesProviding
    private var pocketStoriesViewModels = [PocketStandardCellViewModel]()

    weak var delegate: PocketDelegate?
    var onTapAction: ((IndexPath) -> Void)?

    init(pocketAPI: PocketStoriesProviding,
         pocketSponsoredAPI: PocketSponsoredStoriesProviding,
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.pocketAPI = pocketAPI
        self.pocketSponsoredAPI = pocketSponsoredAPI
        self.notificationCenter = notificationCenter
        setupNotifications(forObserver: self, observing: [UIApplication.willEnterForegroundNotification])

        Task {
            await updatePocketSites()
        }
    }

    func getPocketData() -> [PocketStandardCellViewModel] {
        return pocketStoriesViewModels
    }

    private lazy var storyProvider: StoryProvider = {
        StoryProvider(pocketAPI: pocketAPI, pocketSponsoredAPI: pocketSponsoredAPI) { [weak self] in
            self?.featureFlags.isFeatureEnabled(.sponsoredPocket, checking: .buildAndUser) == true
        }
    }()

    private func updatePocketSites() async {
        let stories = await storyProvider.fetchPocketStories()
        pocketStoriesViewModels = []
        // Add the story in the view models list
        for story in stories {
            bind(pocketStoryViewModel: .init(story: story))
        }

        delegate?.didLoadNewData()
    }

    private func bind(pocketStoryViewModel: PocketStandardCellViewModel) {
        guard let onTapAction = onTapAction else { return }
        pocketStoryViewModel.onTap = onTapAction
        pocketStoriesViewModels.append(pocketStoryViewModel)
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
