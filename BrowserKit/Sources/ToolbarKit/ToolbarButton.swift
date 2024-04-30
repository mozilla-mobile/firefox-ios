// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class ToolbarButton: UIButton, ThemeApplicable {
    private struct UX {
        static let verticalInset: CGFloat = 8
        static let horizontalInset: CGFloat = 8
        static let badgeIconSize = CGSize(width: 20, height: 20)
    }

    private var foregroundColorNormal: UIColor = .clear
    private var foregroundColorHighlighted: UIColor = .clear
    private var foregroundColorDisabled: UIColor = .clear
    private var backgroundColorNormal: UIColor = .clear

    override init(frame: CGRect) {
        super.init(frame: frame)

        configuration = UIButton.Configuration.plain()
        configuration?.contentInsets = NSDirectionalEdgeInsets(top: UX.verticalInset,
                                                               leading: UX.horizontalInset,
                                                               bottom: UX.verticalInset,
                                                               trailing: UX.horizontalInset)
    }

    open func configure(element: ToolbarElement) {
        guard var config = configuration else {
            return
        }

        let image = UIImage(named: element.iconName)?.withRenderingMode(.alwaysTemplate)
        if let badgeName = element.badgeImageName {
            addBadgeIcon(imageName: badgeName)
        }
        let action = UIAction(title: element.a11yLabel,
                              image: image,
                              handler: { _ in
            element.onSelected?()
        })

        config.image = image
        isEnabled = element.isEnabled
        accessibilityIdentifier = element.a11yId
        accessibilityLabel = element.a11yLabel
        addAction(action, for: .touchUpInside)

        showsLargeContentViewer = true
        largeContentTitle = element.a11yLabel
        largeContentImage = image

        configuration = config
        layoutIfNeeded()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func updateConfiguration() {
        guard var updatedConfiguration = configuration else {
            return
        }

        switch state {
        case [.highlighted]:
            updatedConfiguration.baseForegroundColor = foregroundColorHighlighted
        case [.disabled]:
            updatedConfiguration.baseForegroundColor = foregroundColorDisabled
        default:
            updatedConfiguration.baseForegroundColor = foregroundColorNormal
        }

        updatedConfiguration.background.backgroundColor = backgroundColorNormal
        configuration = updatedConfiguration
    }

    private func addBadgeIcon(imageName: String) {
        let badgeImageView = UIImageView(image: UIImage(named: imageName))
        badgeImageView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(badgeImageView)
        NSLayoutConstraint.activate([
            badgeImageView.widthAnchor.constraint(equalToConstant: UX.badgeIconSize.width),
            badgeImageView.heightAnchor.constraint(equalToConstant: UX.badgeIconSize.height),
            badgeImageView.leadingAnchor.constraint(equalTo: centerXAnchor),
            badgeImageView.bottomAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    // MARK: ThemeApplicable
    public func applyTheme(theme: Theme) {
        foregroundColorNormal = theme.colors.iconPrimary
        foregroundColorHighlighted = theme.colors.iconPrimary
        foregroundColorDisabled = theme.colors.iconDisabled
        backgroundColorNormal = .clear
        setNeedsUpdateConfiguration()
    }
}
