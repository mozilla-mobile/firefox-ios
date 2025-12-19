// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Extension to add invisible tab filtering capabilities to existing TabManager
/// Provides filtered tab collections that exclude invisible tabs
extension TabManager {

    /// Returns the count of visible tabs only (excludes invisible tabs)
    /// This should be used for UI display purposes instead of the raw `count` property
    var visibleTabCount: Int {
        return InvisibleTabManager.shared.getVisibleTabs(from: tabs).count
    }

    /// Returns the count of invisible tabs only
    var invisibleTabCount: Int {
        return InvisibleTabManager.shared.getInvisibleTabs(from: tabs).count
    }

    /// Returns only visible normal tabs (excludes private and invisible tabs)
    /// This is the filtered equivalent of `normalTabs`
    var visibleNormalTabs: [Tab] {
        return InvisibleTabManager.shared.getVisibleTabs(from: normalTabs)
    }

    /// Returns only visible normal active tabs (excludes private, inactive, and invisible tabs)
    /// This is the filtered equivalent of `normalActiveTabs`
    var visibleNormalActiveTabs: [Tab] {
        return InvisibleTabManager.shared.getVisibleTabs(from: normalActiveTabs)
    }

    /// Returns only visible private tabs (excludes invisible tabs)
    /// This is the filtered equivalent of `privateTabs`
    var visiblePrivateTabs: [Tab] {
        return InvisibleTabManager.shared.getVisibleTabs(from: privateTabs)
    }

    /// Returns only visible inactive tabs (excludes invisible tabs)
    /// This is the filtered equivalent of `inactiveTabs`
    var visibleInactiveTabs: [Tab] {
        return InvisibleTabManager.shared.getVisibleTabs(from: inactiveTabs)
    }

    /// Returns only visible recently accessed normal tabs (excludes invisible tabs)
    /// This is the filtered equivalent of `recentlyAccessedNormalTabs`
    var visibleRecentlyAccessedNormalTabs: [Tab] {
        return InvisibleTabManager.shared.getVisibleTabs(from: recentlyAccessedNormalTabs)
    }

    /// Returns all invisible tabs
    var invisibleTabs: [Tab] {
        return InvisibleTabManager.shared.getInvisibleTabs(from: tabs)
    }

    /// Returns all visible tabs (the opposite of invisibleTabs)
    var visibleTabs: [Tab] {
        return InvisibleTabManager.shared.getVisibleTabs(from: tabs)
    }

    /// Cleanup invisible tab tracking when tabs are removed
    /// This should be called when tabs are removed to prevent memory leaks
    func cleanupInvisibleTabTracking() {
        let existingTabUUIDs = Set(tabs.map { $0.tabUUID })
        InvisibleTabManager.shared.cleanupRemovedTabs(existingTabUUIDs: existingTabUUIDs)
    }
}
