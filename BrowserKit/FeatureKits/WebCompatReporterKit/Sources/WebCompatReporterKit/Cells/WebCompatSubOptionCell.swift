// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class WebCompatSubOptionCell: UICollectionViewListCell {
    func configure(title: String, isSelected: Bool, theme: Theme, a11yIdentifier: String) {
        var content = defaultContentConfiguration()
        content.text = title
        content.textProperties.color = theme.colors.textPrimary
        contentConfiguration = content
        accessibilityIdentifier = a11yIdentifier
        backgroundConfiguration = .listGroupedCell()
        backgroundConfiguration?.backgroundColor = theme.colors.layer5
        accessories = isSelected ? [checkmarkAccessory(theme: theme)] : []
        // The checkmark is decorative; the selected state rides on the cell so
        // VoiceOver announces it. Reset on reuse (the cell reconfigures in place).
        accessibilityTraits.insert(.button)
        if isSelected {
            accessibilityTraits.insert(.selected)
        } else {
            accessibilityTraits.remove(.selected)
        }
    }

    private func checkmarkAccessory(theme: Theme) -> UICellAccessory {
        let image = UIImage(named: StandardImageIdentifiers.Large.checkmark)?.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.tintColor = theme.colors.actionPrimary
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = false
        return .customView(configuration: UICellAccessory.CustomViewConfiguration(
            customView: imageView,
            placement: .trailing()
        ))
    }
}
