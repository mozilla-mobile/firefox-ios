/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class SettingsTableViewAccessoryCell: SettingsTableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryView = UIImageView(image: UIImage(systemName: "chevron.right"))
        tintColor = .secondaryText.withAlphaComponent(0.3)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setConfiguration(text: String, secondaryText: String? = nil) {
        var configuration = defaultContentConfiguration()
        configuration.text = text
        configuration.textProperties.color = .primaryText
        
        if let secondaryText {
            configuration.secondaryText = secondaryText
        }
        
        let margins = configuration.directionalLayoutMargins
        configuration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: margins.top, leading: UIConstants.layout.settingsCellLeftInset, bottom: margins.bottom, trailing: margins.trailing)
        configuration.prefersSideBySideTextAndSecondaryText = true
        contentConfiguration = configuration
    }
}
