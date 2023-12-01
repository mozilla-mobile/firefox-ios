// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct WindowData: Codable {
    // TODO: [7798] Part of WIP iPad multi-window epic.
    public static let DefaultSingleWindowUUID = UUID(uuidString: "44BA0B7D-097A-484D-8358-91A6E374451D")!

    public let id: UUID
    public let isPrimary: Bool
    public let activeTabId: UUID
    public let tabData: [TabData]

    /// Providing default values for id and isPrimary for now
    /// This will change when multi-window support is added
    /// - Parameters:
    ///   - id: a unique ID used to identify the window
    ///   - isPrimary: determines if the window is the primary window
    ///   - activeTabId: the ID of the currently selected tab
    ///   - tabData: a list of all tabs associated with the window
    public init(id: UUID,
                isPrimary: Bool = true,
                activeTabId: UUID,
                tabData: [TabData]) {
        self.id = id
        self.isPrimary = isPrimary
        self.activeTabId = activeTabId
        self.tabData = tabData
    }
}
