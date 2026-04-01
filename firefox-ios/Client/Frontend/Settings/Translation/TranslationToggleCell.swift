// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit

final class TranslationToggleCell: UICollectionViewListCell, ThemeApplicable {
    private let toggle = UISwitch()

    func configure(title: String, isOn: Bool, target: Any?, action: Selector, theme: Theme) {
        var content = defaultContentConfiguration()
        content.text = title
        contentConfiguration = content
        toggle.isOn = isOn
        toggle.addTarget(target, action: action, for: .valueChanged)
        accessories = [.customView(configuration: .init(customView: toggle, placement: .trailing(displayed: .always)))]
        applyTheme(theme: theme)
    }

    func applyTheme(theme: Theme) {
        guard var content = contentConfiguration as? UIListContentConfiguration else { return }
        content.textProperties.color = theme.colors.textPrimary
        contentConfiguration = content
        toggle.onTintColor = theme.colors.actionPrimary
        backgroundConfiguration = .listGroupedCell()
        backgroundConfiguration?.backgroundColor = theme.colors.layer2
    }
}
