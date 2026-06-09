// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class TranslationPickerLanguageCell: UITableViewCell {
    static let cellIdentifier = "TranslationPickerLanguageCell"

    func configure(native: String, localized: String?) {
        var content = defaultContentConfiguration()
        content.text = native
        content.secondaryText = localized
        contentConfiguration = content
    }

    func applyTheme(theme: Theme) {
        guard var content = contentConfiguration as? UIListContentConfiguration else { return }
        content.textProperties.color = theme.colors.textPrimary
        content.secondaryTextProperties.color = theme.colors.textSecondary
        contentConfiguration = content
        backgroundColor = theme.colors.layer5
    }
}
