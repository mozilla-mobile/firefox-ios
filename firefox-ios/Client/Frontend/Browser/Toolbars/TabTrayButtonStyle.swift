// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

enum TabTrayButtonStyle: String {
    case number
    case screenshot

    static func style(from type: TabTrayButtonType?) -> Self {
        guard let type else { return .number }
        switch type {
        case .number: return .number
        case .screenshot: return .screenshot
        }
    }
}
