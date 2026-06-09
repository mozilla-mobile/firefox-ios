// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit

final class TranslationAddLanguageCell: UICollectionViewListCell, ThemeApplicable {
    func configure(theme: Theme) {
        var content = defaultContentConfiguration()
        content.text = .Settings.Translation.PreferredLanguages.AddLanguage
        contentConfiguration = content
        accessories = []
        accessibilityTraits = .button
        applyTheme(theme: theme)
    }

    func applyTheme(theme: Theme) {
        guard var content = contentConfiguration as? UIListContentConfiguration else { return }
        content.textProperties.color = theme.colors.actionPrimary
        contentConfiguration = content
        backgroundConfiguration = .listGroupedCell()
        backgroundConfiguration?.backgroundColor = theme.colors.layer5
    }
}
