// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Foundation

struct EmptyPrivateTabsViewUX {
    static let TitleFont = UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.medium)
    static let DescriptionFont = UIFont.systemFont(ofSize: 17)
    static let LearnMoreFont = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.medium)
    static let TextMargin: CGFloat = 18
    static let LearnMoreMargin: CGFloat = 8
    static let MaxDescriptionWidth: CGFloat = 250
    static let MinBottomMargin: CGFloat = 10
}

// View we display when there are no private tabs created
class EmptyPrivateTabsView: UIView {
    // MARK: - Properties
    
    // UI
    let titleLabel: UILabel = .build { label in
        label.text =  .PrivateBrowsingTitle
        label.font = EmptyPrivateTabsViewUX.TitleFont
        label.textAlignment = .center
    }
    let descriptionLabel: UILabel = .build { label in
        label.font = EmptyPrivateTabsViewUX.DescriptionFont
        label.textAlignment = .center
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = EmptyPrivateTabsViewUX.MaxDescriptionWidth
        label.text = .TabTrayPrivateBrowsingDescription
    }
    let learnMoreButton: UIButton = .build { button in
        button.setTitle( .PrivateBrowsingLearnMore, for: [])
        button.setTitleColor(UIColor.theme.tabTray.privateModeLearnMore, for: [])
        button.titleLabel?.font = EmptyPrivateTabsViewUX.LearnMoreFont
    }
    let iconImageView: UIImageView = .build { imageView in
        imageView.image = UIImage.templateImageNamed("largePrivateMask")
        imageView.tintColor = UIColor.Photon.Grey60
    }

    // MARK: - Inits
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews(iconImageView, titleLabel, descriptionLabel, learnMoreButton)
        
        NSLayoutConstraint.activate([
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -70),
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 120),
            iconImageView.heightAnchor.constraint(equalToConstant: 120),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 0),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: CGFloat(EmptyPrivateTabsViewUX.TextMargin)),
            descriptionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            learnMoreButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: CGFloat(EmptyPrivateTabsViewUX.LearnMoreMargin)),
            learnMoreButton.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])

        applyTheme()

        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: .DisplayThemeChanged, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension EmptyPrivateTabsView: NotificationThemeable {
    @objc func applyTheme() {
        titleLabel.textColor = UIColor.theme.tabTray.tabTitleText
        descriptionLabel.textColor = UIColor.theme.tabTray.tabTitleText
    }
}
