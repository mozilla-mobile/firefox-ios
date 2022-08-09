// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

protocol JumpBackInDataAdaptor {
    var hasSyncedTabFeatureEnabled: Bool { get }

    func getJumpBackInData() -> JumpBackInList
    func getSyncedTabData() -> JumpBackInSyncedTab?
    func getHeroImage(forSite site: Site) -> UIImage?
    func getFaviconImage(forSite site: Site) -> UIImage?

    func refreshData(maxItemToDisplay: Int)
}

protocol JumpBackInDelegate: AnyObject {
    func didLoadNewData()
}

class JumpBackInDataAdaptorImplementation: JumpBackInDataAdaptor, FeatureFlaggable {

    // MARK: Properties

    var notificationCenter: NotificationProtocol
    private let profile: Profile
    private let tabManager: TabManagerProtocol
    private var siteImageHelper: SiteImageHelperProtocol
    private var heroImages = [String: UIImage]() {
        didSet {
            delegate?.didLoadNewData()
        }
    }

    private var faviconImages = [String: UIImage]() {
        didSet {
            delegate?.didLoadNewData()
        }
    }

    private var recentTabs: [Tab] = [Tab]()
    private var recentGroups: [ASGroup<Tab>]?
    private var jumpBackInList = JumpBackInList(group: nil, tabs: [Tab]())
    private var mostRecentSyncedTab: JumpBackInSyncedTab?

    private let mainQueue: DispatchQueueInterface
    private let dispatchGroup: DispatchGroupInterface
    private let userInteractiveQueue: DispatchQueueInterface

    weak var delegate: JumpBackInDelegate?

    // MARK: Init
    init(profile: Profile,
         tabManager: TabManagerProtocol,
         siteImageHelper: SiteImageHelperProtocol,
         dispatchGroup: DispatchGroupInterface = DispatchGroup(),
         mainQueue: DispatchQueueInterface = DispatchQueue.main,
         userInteractiveQueue: DispatchQueueInterface = DispatchQueue.global(qos: DispatchQoS.userInteractive.qosClass),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.profile = profile
        self.tabManager = tabManager
        self.siteImageHelper = siteImageHelper
        self.notificationCenter = notificationCenter

        self.mainQueue = mainQueue
        self.dispatchGroup = dispatchGroup
        self.userInteractiveQueue = userInteractiveQueue

        setupNotifications(forObserver: self, observing: [.TabsTrayDidClose,
                                                          .TopTabsTabClosed,
                                                          .TopTabsTabSelected,
                                                          .TabsTrayDidSelectHomeTab])

        updateData()
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: Public interface

    var hasSyncedTabFeatureEnabled: Bool {
        return profile.hasSyncableAccount() &&
                featureFlags.isFeatureEnabled(.jumpBackInSyncedTab, checking: .buildOnly)
    }

    func getJumpBackInData() -> JumpBackInList {
        return jumpBackInList
    }

    func getSyncedTabData() -> JumpBackInSyncedTab? {
        return mostRecentSyncedTab
    }

    func getHeroImage(forSite site: Site) -> UIImage? {
        if let heroImage = heroImages[site.url] {
            return heroImage
        }
        siteImageHelper.fetchImageFor(site: site,
                                      imageType: .heroImage,
                                      shouldFallback: true) { image in
            self.heroImages[site.url] = image
        }
        return nil
    }

    func getFaviconImage(forSite site: Site) -> UIImage? {
        if let heroImage = faviconImages[site.url] {
            return heroImage
        }

        siteImageHelper.fetchImageFor(site: site,
                                      imageType: .favicon,
                                      shouldFallback: false) { image in
            self.faviconImages[site.url] = image
        }
        return nil
    }

    /// Default number of items to display to 2 in the case that we want to refresh data after the first async fetch
    /// At that moment we don't know for which UI we want to display the data, but we need to calculate some
    /// jumpBackInList items to be able to show the section. jumpBackInList gets refreshed with the proper UI
    func refreshData(maxItemToDisplay: Int = 2) {
        jumpBackInList = createJumpBackInList(
            from: recentTabs,
            withMaxItemsToDisplay: maxItemToDisplay,
            and: recentGroups)
    }

    // MARK: Jump back in data

    private func updateData() {
        // Has to be on main due to tab manager needing main tread
        // This can be fixed when tab manager has been revisited
        mainQueue.async { [weak self] in
            guard let self = self else { return }

            self.dispatchGroup.enter()
            self.updateJumpBackInData {
                self.dispatchGroup.leave()
            }

            self.dispatchGroup.enter()
            self.updateRemoteTabs {
                self.dispatchGroup.leave()
            }

            self.dispatchGroup.notify(queue: .main) {
                self.refreshData()
                self.delegate?.didLoadNewData()
            }
        }
    }

    private func createJumpBackInList(
        from tabs: [Tab],
        withMaxItemsToDisplay maxItems: Int,
        and groups: [ASGroup<Tab>]? = nil
    ) -> JumpBackInList {
        let recentGroup = groups?.first
        let groupCount = recentGroup != nil ? 1 : 0
        let recentTabs = filter(
            tabs: tabs,
            from: recentGroup,
            usingGroupCount: groupCount,
            withMaxItemsToDisplay: maxItems
        )

        return JumpBackInList(group: recentGroup, tabs: recentTabs)
    }

    private func filter(
        tabs: [Tab],
        from recentGroup: ASGroup<Tab>?,
        usingGroupCount groupCount: Int,
        withMaxItemsToDisplay maxItemsToDisplay: Int
    ) -> [Tab] {
        var recentTabs = [Tab]()
        let maxItemCount = maxItemsToDisplay - groupCount

        for tab in tabs {
            // We must make sure to not include any 'solo' tabs that are also part of a group
            // because they should not show up in the Jump Back In section.
            if let recentGroup = recentGroup, recentGroup.groupedItems.contains(tab) { continue }

            recentTabs.append(tab)
            // We are only showing one group in Jump Back in, so adjust count accordingly
            if recentTabs.count == maxItemCount { break }
        }

        return recentTabs
    }

    /// Update data with tab and search term group managers, saving it in view model for further usage
    private func updateJumpBackInData(completion: @escaping () -> Void) {
        recentTabs = tabManager.recentlyAccessedNormalTabs

        if featureFlags.isFeatureEnabled(.tabTrayGroups, checking: .buildAndUser) {
            SearchTermGroupsUtility.getTabGroups(
                with: profile,
                from: recentTabs,
                using: .orderedDescending
            ) { [weak self] groups, _ in

                self?.recentGroups = groups
                completion()
            }
        } else {
            completion()
        }
    }

    // MARK: Synced tab data

    private func updateRemoteTabs(completion: @escaping () -> Void) {
        // Short circuit if the user is not logged in or feature not enabled
        guard hasSyncedTabFeatureEnabled else {
            mostRecentSyncedTab = nil
            completion()
            return
        }

        // Get cached tabs
        userInteractiveQueue.async { [weak self] in
            self?.profile.getCachedClientsAndTabs { [weak self] result in
                self?.createMostRecentSyncedTab(from: result, completion: completion)
            }
        }
    }

    private func createMostRecentSyncedTab(from clientAndTabs: [ClientAndTabs], completion: @escaping () -> Void) {
        // filter clients for non empty desktop clients
        let desktopClientAndTabs = clientAndTabs.filter { !$0.tabs.isEmpty &&
            ClientType.fromFxAType($0.client.type) == .Desktop }

        guard !desktopClientAndTabs.isEmpty, !clientAndTabs.isEmpty else {
            mostRecentSyncedTab = nil
            completion()
            return
        }

        // get most recent tab
        var mostRecentTab: (client: RemoteClient, tab: RemoteTab)?

        desktopClientAndTabs.forEach { remoteClient in
            guard let firstClient = remoteClient.tabs.first else { return }
            let mostRecentClientTab = remoteClient.tabs.reduce(firstClient, {
                                                                $0.lastUsed > $1.lastUsed ? $0 : $1 })

            if let currentMostRecentTab = mostRecentTab,
               currentMostRecentTab.tab.lastUsed < mostRecentClientTab.lastUsed {
                mostRecentTab = (client: remoteClient.client, tab: mostRecentClientTab)
            } else if mostRecentTab == nil {
                mostRecentTab = (client: remoteClient.client, tab: mostRecentClientTab)
            }
        }

        guard let mostRecentTab = mostRecentTab else {
            mostRecentSyncedTab = nil
            completion()
            return
        }

        mostRecentSyncedTab = JumpBackInSyncedTab(client: mostRecentTab.client, tab: mostRecentTab.tab)
        completion()
    }
}

// MARK: - Notifiable
extension JumpBackInDataAdaptorImplementation: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .TabsTrayDidClose,
                .TopTabsTabClosed,
                .TopTabsTabSelected,
                .TabsTrayDidSelectHomeTab:
            updateData()
        default: break
        }
    }
}
