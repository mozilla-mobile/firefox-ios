/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class MultiplyImpactStep: UIView, NotificationThemeable {
    private weak var indicator: UIImageView?
    private weak var titleLabel: UILabel?
    private weak var subtitleLabel: UILabel?
    
    required init?(coder: NSCoder) { nil }
    init(title: String, subtitle: String, image: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false
        
        let indicator = UIImageView(image: .init(named: image)?.withRenderingMode(.alwaysTemplate))
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.isUserInteractionEnabled = false
        indicator.clipsToBounds = true
        addSubview(indicator)
        self.indicator = indicator
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .subheadline).bold()
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.adjustsFontForContentSizeCategory = true
        addSubview(titleLabel)
        self.titleLabel = titleLabel
        
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = subtitle
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        addSubview(subtitleLabel)
        self.subtitleLabel = subtitleLabel
        
        bottomAnchor.constraint(equalTo: subtitleLabel.bottomAnchor).isActive = true
        
        indicator.topAnchor.constraint(equalTo: topAnchor).isActive = true
        indicator.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        indicator.widthAnchor.constraint(equalToConstant: 24).isActive = true
        indicator.heightAnchor.constraint(equalTo: indicator.widthAnchor).isActive = true
        
        titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: indicator.rightAnchor, constant: 12).isActive = true
        titleLabel.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: -12).isActive = true
        
        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4).isActive = true
        subtitleLabel.leftAnchor.constraint(equalTo: indicator.rightAnchor, constant: 12).isActive = true
        subtitleLabel.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: -12).isActive = true
    }
    
    func applyTheme() {
        indicator?.tintColor = .theme.ecosia.primaryBrand
        titleLabel?.textColor = .theme.ecosia.primaryText
        subtitleLabel?.textColor = .theme.ecosia.secondaryText
    }
}
