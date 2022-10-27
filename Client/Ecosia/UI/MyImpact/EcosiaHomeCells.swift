/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class MoreButtonCell: UICollectionReusableView, ReusableCell {
    private(set) weak var button: UIButton!
    
    required init?(coder: NSCoder) { return nil }
    
    override init(frame: CGRect) {
        let button = UIButton()
        self.button = button
        
        super.init(frame: frame)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(.init(named: "news"), for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.contentEdgeInsets.right = 16
        button.contentEdgeInsets.left = 16
        button.imageEdgeInsets.left = -8
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        addSubview(button)
        
        button.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        button.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16).isActive = true
        button.heightAnchor.constraint(equalToConstant: 32).priority(.defaultHigh).isActive = true

        applyTheme()
    }
    
    func applyTheme() {
        button.tintColor = .theme.ecosia.primaryText
        button.imageView?.tintColor = .theme.ecosia.primaryText
        button.setTitleColor(.theme.ecosia.primaryText, for: .normal)
        button.setTitleColor(.theme.ecosia.secondaryText, for: .highlighted)
        button.setTitleColor(.theme.ecosia.secondaryText, for: .selected)
        button.backgroundColor = .theme.ecosia.moreNewsButton
        button.layer.borderColor = UIColor.theme.ecosia.primaryText.cgColor
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        applyTheme()
    }

}

final class HeaderCell: UICollectionViewCell, NotificationThemeable {
    private(set) weak var title: UILabel!
    
    required init?(coder aDecoder: NSCoder) { return nil }
    
    override init(frame: CGRect) {
        let title = UILabel()
        self.title = title
        
        super.init(frame: frame)
        title.textColor = UIColor.theme.ecosia.primaryText
        title.font = .preferredFont(forTextStyle: .headline)
        title.adjustsFontForContentSizeCategory = true
        title.numberOfLines = 0
        title.translatesAutoresizingMaskIntoConstraints = false
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        contentView.addSubview(title)
        
        let top = title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32)
        top.priority = .init(999)
        top.isActive = true

        title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        title.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor).isActive = true
        title.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16).isActive = true
    }

    func applyTheme() {
        title.textColor = .theme.ecosia.primaryText
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
