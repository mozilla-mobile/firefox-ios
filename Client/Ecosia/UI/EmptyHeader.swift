/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Common

final class EmptyHeader: UITableViewHeaderFooterView, Themeable {
    private let icon: String
    private weak var labelTitle: UILabel?
    private weak var labelSubtitle: UILabel?
    private weak var image: UIImageView?
    
    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init
    
    required init?(coder: NSCoder) { nil }
    
    init(icon: String, title: String, subtitle: String) {
        self.icon = icon
        super.init(reuseIdentifier: "EmptyHeader")
        frame.size.height = 170
        
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.clipsToBounds = true
        image.contentMode = .center
        contentView.addSubview(image)
        self.image = image
        
        let labelTitle = UILabel()
        labelTitle.translatesAutoresizingMaskIntoConstraints = false
        labelTitle.numberOfLines = 0
        labelTitle.text = title
        labelTitle.font = .preferredFont(forTextStyle: .subheadline).bold()
        labelTitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        labelTitle.adjustsFontForContentSizeCategory = true
        labelTitle.textAlignment = .center
        contentView.addSubview(labelTitle)
        self.labelTitle = labelTitle
        
        let labelSubtitle = UILabel()
        labelSubtitle.translatesAutoresizingMaskIntoConstraints = false
        labelSubtitle.numberOfLines = 0
        labelSubtitle.text = subtitle
        labelSubtitle.font = .preferredFont(forTextStyle: .subheadline)
        labelSubtitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        labelSubtitle.adjustsFontForContentSizeCategory = true
        labelSubtitle.textAlignment = .center
        contentView.addSubview(labelSubtitle)
        self.labelSubtitle = labelSubtitle
        
        image.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32).isActive = true
        image.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        labelTitle.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 12).isActive = true
        labelTitle.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        labelTitle.widthAnchor.constraint(lessThanOrEqualToConstant: 180).isActive = true
        
        labelSubtitle.topAnchor.constraint(equalTo: labelTitle.bottomAnchor, constant: 4).isActive = true
        labelSubtitle.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        labelSubtitle.widthAnchor.constraint(lessThanOrEqualToConstant: 180).isActive = true
    }
    
    // MARK: - Themeable
    
    func applyTheme() {
        image?.image = .init(named: icon)?.withRenderingMode(.alwaysTemplate)
        image?.tintColor = UIColor.legacyTheme.ecosia.secondaryText
        labelTitle?.textColor = .legacyTheme.ecosia.primaryText
        labelSubtitle?.textColor = .legacyTheme.ecosia.secondaryText
    }
}
