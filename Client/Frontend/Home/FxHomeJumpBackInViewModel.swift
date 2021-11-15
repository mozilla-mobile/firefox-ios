// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

fileprivate let MaximumNumberOfGroups: Int = 1

struct JumpList {
    let group: ASGroup<Tab>?
    let tabs: [Tab]
    var itemsToDisplay: Int {
        get {
            var count = 0

            count += group != nil ? 1 : 0
            count += tabs.count

            return count
        }
    }
}

class FirefoxHomeJumpBackInViewModel: FeatureFlagsProtocol {

    // MARK: - Properties
    var jumpList = JumpList(group: nil, tabs: [Tab]())

    var layoutVariables: JumpBackInLayoutVariables
    private var tabManager: TabManager
    private var profile: Profile
    lazy var siteImageHelper = SiteImageHelper(profile: profile)

    var onTapGroup: ((Tab) -> Void)?

    init() {
        self.tabManager = BrowserViewController.foregroundBVC().tabManager
        self.profile = BrowserViewController.foregroundBVC().profile
        self.layoutVariables = JumpBackInLayoutVariables(columns: 1, scrollDirection: .vertical, maxItemsToDisplay: 2)
    }

    public func updateDataAnd(_ layoutVariables: JumpBackInLayoutVariables) {
        self.layoutVariables = layoutVariables
        updateJumpListData()
    }

    public func switchTo(group: ASGroup<Tab>) {
        if BrowserViewController.foregroundBVC().urlBar.inOverlayMode {
            BrowserViewController.foregroundBVC().urlBar.leaveOverlayMode()
        }
        guard let firstTab = group.groupedItems.first else { return }

        onTapGroup?(firstTab)

        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .firefoxHomepage, value: .jumpBackInSectionGroupOpened)
    }

    public func switchTo(tab: Tab) {
        if BrowserViewController.foregroundBVC().urlBar.inOverlayMode {
            BrowserViewController.foregroundBVC().urlBar.leaveOverlayMode()
        }
        tabManager.selectTab(tab)
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .firefoxHomepage, value: .jumpBackInSectionTabOpened)
    }

    private func updateJumpListData() {
        if featureFlags.isFeatureActiveForBuild(.groupedTabs),
           featureFlags.userPreferenceFor(.groupedTabs) == UserFeaturePreference.enabled {
            let recentTabs = tabManager.recentlyAccessedNormalTabs
            SearchTermGroupsManager.getTabGroups(with: profile,
                                          from: recentTabs,
                                          using: .orderedDescending) { groups, _ in
                self.jumpList = self.createJumpList(from: recentTabs, and: groups)
            }
        } else {
            self.jumpList = createJumpList(from: tabManager.recentlyAccessedNormalTabs)
        }
    }

    private func createJumpList(from tabs: [Tab], and groups: [ASGroup<Tab>]? = nil) -> JumpList {
        let recentGroup = groups?.first
        let groupCount = recentGroup != nil ? 1 : 0
        let recentTabs = filter(tabs: tabs, usingGroupCount: groupCount)

        return JumpList(group: recentGroup, tabs: recentTabs)
    }

    private func filter(tabs: [Tab], usingGroupCount groupCount: Int) -> [Tab] {
        var recentTabs = [Tab]()
        let maxItemCount = layoutVariables.maxItemsToDisplay - groupCount

        for tab in tabs {
            recentTabs.append(tab)
            // We are only showing one group in Jump Back in, so adjust count accordingly
            if recentTabs.count == maxItemCount { break }
        }

        return recentTabs
    }
}

