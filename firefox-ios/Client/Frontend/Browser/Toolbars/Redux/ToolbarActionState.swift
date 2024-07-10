// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct ToolbarActionState: Equatable {
    enum ActionType {
        case back
        case forward
        case home
        case search
        case tabs
        case menu
        case qrCode
        case share
        case reload
        case stopLoading
        case trackingProtection
        case readerMode
        case dataClearance
        case cancelEdit
    }

    var actionType: ActionType
    var iconName: String
    var badgeImageName: String?
    var numberOfTabs: Int?
    var isEnabled: Bool
    var a11yLabel: String
    var a11yHint: String?
    var a11yId: String

    var canPerformLongPressAction: Bool {
        return actionType == .back ||
               actionType == .forward ||
               actionType == .tabs
    }
}
