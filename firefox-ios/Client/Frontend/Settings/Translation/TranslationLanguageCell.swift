// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class TranslationLanguageCell: UICollectionViewListCell, ThemeApplicable {
    private var details: PreferredLanguageDetails?
    private var isCollectionViewEditing = false
    var deleteHandler: (() -> Void)?

    func configure(with details: PreferredLanguageDetails, theme: Theme) {
        self.details = details
        var content = defaultContentConfiguration()
        content.text = details.mainText
        content.secondaryText = details.subtitleText
        contentConfiguration = content
        accessories = []
        accessibilityLabel = details.mainText
        applyTheme(theme: theme)
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        isCollectionViewEditing = state.isEditing
    }

    override func accessibilityActivate() -> Bool {
        if isCollectionViewEditing, let deleteHandler {
            deleteHandler()
            return true
        }
        return super.accessibilityActivate()
    }

    func applyTheme(theme: Theme) {
        guard var content = contentConfiguration as? UIListContentConfiguration else { return }
        content.textProperties.color = theme.colors.textPrimary
        content.secondaryTextProperties.color = theme.colors.textSecondary
        contentConfiguration = content
        backgroundConfiguration = .listGroupedCell()
        backgroundConfiguration?.backgroundColor = theme.colors.layer5
    }
}
