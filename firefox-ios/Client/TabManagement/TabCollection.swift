// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@MainActor
final class TabCollection {
    var tabs: [Tab] {
        didSet { cachedSnapshot = nil }
    }

    var groups: [TabGroupMembership: [Tab]] { snapshot.groups }
    var normalTabs: [Tab] { snapshot.normalTabs }

    private struct Snapshot {
        var groups: [TabGroupMembership: [Tab]] = [:]
        var normalTabs: [Tab] = []
    }

    private var cachedSnapshot: Snapshot?

    init(tabs: [Tab] = []) {
        self.tabs = tabs
    }

    func tabs(in group: TabGroupMembership) -> [Tab] {
        groups[group] ?? []
    }

    private var snapshot: Snapshot {
        if let cachedSnapshot { return cachedSnapshot }
        var result = Snapshot()
        result.normalTabs.reserveCapacity(tabs.count)
        for tab in tabs {
            result.groups[tab.group, default: []].append(tab)
            if !tab.isPrivate {
                result.normalTabs.append(tab)
            }
        }
        cachedSnapshot = result
        return result
    }
}
