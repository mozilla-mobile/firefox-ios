// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

enum ThemedTableViewCellType {
    case standard, actionPrimary, destructive, disabled
}

class ThemedTableViewCellViewModel {
    var type: ThemedTableViewCellType

    var textColor: UIColor?
    var detailTextColor: UIColor?
    var backgroundColor: UIColor?
    var tintColor: UIColor?

    init(theme: Theme, type: ThemedTableViewCellType) {
        self.type = type
        setColors(theme: theme)
    }

    func setColors(theme: Theme) {
        detailTextColor = theme.colors.textSecondary
        backgroundColor = theme.colors.layer5
        tintColor = theme.colors.actionPrimary

        switch self.type {
        case .standard:
            textColor = theme.colors.textPrimary
        case .actionPrimary:
            textColor = theme.colors.actionPrimary
        case .destructive:
            textColor = theme.colors.textCritical
        case .disabled:
            textColor = theme.colors.textDisabled
        }
    }
}
