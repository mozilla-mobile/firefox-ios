// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class TranslationLanguageCell: UICollectionViewListCell, ThemeApplicable {
    private var details: PreferredLanguageDetails?

    func configure(with details: PreferredLanguageDetails, theme: Theme) {
        self.details = details
        accessories = []
        applyTheme(theme: theme)
    }

    func applyTheme(theme: Theme) {
        guard let details else { return }
        var content = defaultContentConfiguration()
        content.text = details.mainText
        content.textProperties.color = theme.colors.textPrimary
        content.secondaryText = details.subtitleText
        content.secondaryTextProperties.color = theme.colors.textSecondary
        contentConfiguration = content
        backgroundConfiguration = .listGroupedCell()
        backgroundConfiguration?.backgroundColor = theme.colors.layer2
    }
}
