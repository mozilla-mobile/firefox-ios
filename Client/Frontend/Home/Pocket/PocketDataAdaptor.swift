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
    private let storyProvider: StoryProvider
    private var pocketStoriesViewModels = [PocketStandardCellViewModel]()

    weak var delegate: PocketDelegate?
    var onTapAction: ((IndexPath) -> Void)? {
        didSet {
            guard let onTapAction = onTapAction else { return }
            pocketStoriesViewModels.forEach { $0.onTap = onTapAction }
        }
    }

    var dataCompletion: (() -> Void)?

    init(pocketAPI: PocketStoriesProviding,
         pocketSponsoredAPI: PocketSponsoredStoriesProviding,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         dataCompletion: (() -> Void)? = nil) {
        self.pocketAPI = pocketAPI
        self.pocketSponsoredAPI = pocketSponsoredAPI
        self.notificationCenter = notificationCenter
        self.storyProvider = StoryProvider(pocketAPI: pocketAPI,
                                           pocketSponsoredAPI: pocketSponsoredAPI)
        self.dataCompletion = dataCompletion

        setupNotifications(forObserver: self, observing: [UIApplication.willEnterForegroundNotification])

        Task {
            await updatePocketSites()
            dataCompletion?()
        }
    }

    func getPocketData() -> [PocketStandardCellViewModel] {
        return pocketStoriesViewModels
    }

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
        pocketStoriesViewModels.append(pocketStoryViewModel)
    }
}

extension PocketDataAdaptorImplementation: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIApplication.willEnterForegroundNotification:
            Task {
                await updatePocketSites()
                dataCompletion?()
            }
        default: break
        }
    }
}
