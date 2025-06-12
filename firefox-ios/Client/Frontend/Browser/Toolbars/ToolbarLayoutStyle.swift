// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

enum ToolbarLayoutStyle: String {
    /// Shows the add new tab, menu and tabs button in the navigation toolbar. The
    /// share button is displayed in the address toolbar.
    case version1

    /// Like version1 but the menu and tabs buttons are inverted.
    case version2

    static func style(from type: ToolbarLayoutType?) -> ToolbarLayoutStyle {
        guard let type else { return .version1 }
        switch type {
        case .version1, .baseline: return .version1
        case .version2: return .version2
        }
    }
}
