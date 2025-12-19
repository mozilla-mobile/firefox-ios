// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class InvisibleTabManager {

    // MARK: - Singleton

    static let shared = InvisibleTabManager()

    // MARK: - Private Properties

    private let queue = DispatchQueue(label: "ecosia.invisible.tabs", attributes: .concurrent)
    private var _invisibleTabUUIDs: Set<TabUUID> = []

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Interface

    /// Array of invisible tab UUIDs
    var invisibleTabUUIDs: [TabUUID] {
        return queue.sync {
            Array(_invisibleTabUUIDs)
        }
    }

    /// Check if a tab is invisible
    /// - Parameter tab: The tab to check
    /// - Returns: True if the tab is invisible
    func isTabInvisible(_ tab: Tab) -> Bool {
        return queue.sync {
            _invisibleTabUUIDs.contains(tab.tabUUID)
        }
    }

    /// Mark a tab as invisible
    /// - Parameter tab: The tab to mark as invisible
    func markTabAsInvisible(_ tab: Tab) {
        queue.sync(flags: .barrier) {
            _invisibleTabUUIDs.insert(tab.tabUUID)
        }
    }

    /// Mark a tab as visible
    /// - Parameter tab: The tab to mark as visible
    func markTabAsVisible(_ tab: Tab) {
        queue.sync(flags: .barrier) {
            _invisibleTabUUIDs.remove(tab.tabUUID)
        }
    }

    /// Get visible tabs from a collection
    /// - Parameter tabs: Collection of tabs to filter
    /// - Returns: Array of visible tabs
    func getVisibleTabs(from tabs: [Tab]) -> [Tab] {
        return queue.sync {
            tabs.filter { !_invisibleTabUUIDs.contains($0.tabUUID) }
        }
    }

    /// Get invisible tabs from a collection
    /// - Parameter tabs: Collection of tabs to filter
    /// - Returns: Array of invisible tabs
    func getInvisibleTabs(from tabs: [Tab]) -> [Tab] {
        return queue.sync {
            tabs.filter { _invisibleTabUUIDs.contains($0.tabUUID) }
        }
    }

    /// Clean up tracking for removed tabs
    /// - Parameter existingTabUUIDs: Set of tab UUIDs that still exist
    func cleanupRemovedTabs(existingTabUUIDs: Set<TabUUID>) {
        queue.sync(flags: .barrier) {
            _invisibleTabUUIDs = _invisibleTabUUIDs.intersection(existingTabUUIDs)
        }
    }

    /// Clear all invisible tabs (useful for testing)
    func clearAllInvisibleTabs() {
        queue.sync(flags: .barrier) {
            _invisibleTabUUIDs.removeAll()
        }
    }
}
