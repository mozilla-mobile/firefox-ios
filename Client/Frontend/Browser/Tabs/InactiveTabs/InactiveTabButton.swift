// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

class InactiveTabButton: UITableViewCell, ThemeApplicable, ReusableCell {
    private struct UX {
        static let ImageSize: CGFloat = 29
        static let BorderViewMargin: CGFloat = 16
        static let ButtonInset: CGFloat = 14
        static let ButtonImagePadding: CGFloat = 11
    }

    // MARK: - Properties
    var buttonClosure: (() -> Void)?
    private let containerView = UIView()
    private var shouldLeftAlignTitle = false
    private var customization: OneLineTableViewCustomization = .regular

    // MARK: - UI Elements
    private let selectedView: UIView = .build { _ in }

    private lazy var roundedButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = LegacyDynamicFontHelper.defaultHelper.preferredFont(
            withTextStyle: .body,
            weight: .semibold,
            maxSize: 16)
        button.setTitle(.TabsTray.InactiveTabs.CloseAllInactiveTabsButton, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.layer.cornerRadius = 13.5
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.clear.cgColor
        button.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.inactiveTabDeleteButton
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Initializers
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialViewSetup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initialViewSetup() {
        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.selectionStyle = .default

        contentView.addSubview(roundedButton)

        roundedButton.setInsets(forContentPadding: UIEdgeInsets(top: UX.ButtonInset,
                                                                left: UX.ButtonInset,
                                                                bottom: UX.ButtonInset,
                                                                right: UX.ButtonInset),
                                imageTitlePadding: UX.ButtonImagePadding)

        let trailingOffSet: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 100 : 23
        let leadingOffSet: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 100 : 23

        NSLayoutConstraint.activate([
            roundedButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            roundedButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: trailingOffSet),
            roundedButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -leadingOffSet),
            roundedButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            roundedButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])

        selectedBackgroundView = selectedView
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.selectionStyle = .default
        separatorInset = UIEdgeInsets(top: 0,
                                      left: UX.ImageSize + 2 * UX.BorderViewMargin,
                                      bottom: 0,
                                      right: 0)
    }

    @objc
    func buttonPressed() {
        self.buttonClosure?()
    }

    // MARK: ThemeApplicable

    func applyTheme(theme: Theme) {
        backgroundColor = .clear
        selectedView.backgroundColor = theme.colors.layer5Hover
        roundedButton.setTitleColor(theme.colors.textPrimary, for: .normal)
        roundedButton.backgroundColor = theme.colors.layer3
        roundedButton.tintColor = theme.colors.textPrimary
        let image = UIImage(named: StandardImageIdentifiers.Large.delete)?.tinted(withColor: theme.colors.iconPrimary)
        roundedButton.setImage(image, for: .normal)
    }
}
