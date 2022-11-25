/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class MoreButtonCell: UICollectionReusableView, ReusableCell, NotificationThemeable {
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
}
