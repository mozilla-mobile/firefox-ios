// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol TabDataStore {
    func fetchTabData() async -> WindowData?
    func saveTabData(window: WindowData) async
    func clearAllTabData() async
}

public actor DefaultTabDataStore: TabDataStore {
    public init() {}

    public func fetchTabData() async -> WindowData? {
        return WindowData(id: UUID(), isPrimary: true, activeTabId: UUID(), tabData: [])
    }

    public func saveTabData(window: WindowData) async {}

    public func clearAllTabData() async {}
}
