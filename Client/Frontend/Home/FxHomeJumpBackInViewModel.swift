/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

fileprivate let MaximumNumberOfGroups: Int = 1

struct JumpList {
    let groups: [String: [Tab]]?
    let tabs: [Tab]
    var itemsToDisplay: Int {
        get {
            var count = 0

            // This should only be one, but, implementing it like thing in case
            // product wants to include more groups in JumpBackIn in the future,
            // we don't really have to touch this code
            if let groupCount = groups?.count {
                count += groupCount
            }

            count += tabs.count

            return count
        }
    }
}

class FirefoxHomeJumpBackInViewModel: FeatureFlagsProtocol {

    // MARK: - Properties
    var jumpList = JumpList(groups: nil, tabs: [Tab]())

    var layoutVariables: JumpBackInLayoutVariables
    var tabManager: TabManager
    var profile: Profile

    init() {
        self.tabManager = BrowserViewController.foregroundBVC().tabManager
        self.profile = BrowserViewController.foregroundBVC().profile
        self.layoutVariables = JumpBackInLayoutVariables(columns: 1, scrollDirection: .vertical, maxItemsToDisplay: 2)
    }

    public func updateDataAnd(_ layoutVariables: JumpBackInLayoutVariables) {
        self.layoutVariables = layoutVariables
        updateJumpListData()
    }

    public func switchTo(_ tab: Tab) {
        if BrowserViewController.foregroundBVC().urlBar.inOverlayMode {
            BrowserViewController.foregroundBVC().urlBar.leaveOverlayMode()
        }
        tabManager.selectTab(tab)
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .firefoxHomepage, value: .jumpBackInSectionTabOpened)
    }

    private func updateJumpListData() {
        if featureFlags.isFeatureActive(.groupedTabs) {
            TabGroupsManager.getTabGroups(profile: profile,
                                          tabs: tabManager.recentlyAccessedNormalTabs) { groups, filteredActiveTabs in
                self.jumpList = self.createJumpList(from: filteredActiveTabs, and: groups)
            }
        } else {
            self.jumpList = createJumpList(from: tabManager.recentlyAccessedNormalTabs)
        }
    }

    private func createJumpList(from tabs: [Tab], and groups: [String: [Tab]]? = nil) -> JumpList {
        let recentGroup = filter(groups: groups)
        let groupCount = recentGroup != nil ? 1 : 0
        let recentTabs = filter(tabs: tabs, usingGroupCount: groupCount)

        return JumpList(groups: recentGroup, tabs: recentTabs)
    }

    private func filter(groups: [String: [Tab]]?) -> [String: [Tab]]? {
        var recentGroup: [String: [Tab]]? = nil

        if let groups = groups {
            for group in groups {

            }
            // use Maximum number of groups
            print(groups)
            recentGroup = nil
        }

        return recentGroup
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
