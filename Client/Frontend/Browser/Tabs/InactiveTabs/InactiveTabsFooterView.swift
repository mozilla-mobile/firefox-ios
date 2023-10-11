// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class InactiveTabsFooterView: UICollectionReusableView, ReusableCell, ThemeApplicable {
    struct UX {
        static let imageSize: CGFloat = 29
        static let borderViewMargin: CGFloat = 16
        static let buttonInset: CGFloat = 14
        static let buttonImagePadding: CGFloat = 11
        static let buttonFontSize: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 13.5
        static let buttonBorderWidth: CGFloat = 1
        static let iPadOffset: CGFloat = 100
        static let iPhoneOffset: CGFloat = 23
        static let buttonTopOffset: CGFloat = 16
        static let buttonBottomOffset: CGFloat = 24
    }
    // MARK: - Properties
    var buttonClosure: (() -> Void)?

    let containerView = UIView()
    var shouldLeftAlignTitle = false

    // MARK: - UI Elements
    private lazy var roundedButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredBoldFont(
            withTextStyle: .body,
            size: UX.buttonFontSize)
        button.setImage(UIImage(systemName: "trash"), for: .normal)
        button.setTitle(.TabsTray.InactiveTabs.CloseAllInactiveTabsButton, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.layer.borderWidth = UX.buttonBorderWidth
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        addSubview(roundedButton)

        roundedButton.contentEdgeInsets = UIEdgeInsets(
            top: UX.buttonInset,
            left: UX.buttonInset,
            bottom: UX.buttonInset,
            right: UX.buttonInset)
        roundedButton.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: UX.buttonImagePadding,
            bottom: 0,
            right: UX.buttonImagePadding
        )

        let horizontalOffSet: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? UX.iPadOffset : UX.iPhoneOffset

        NSLayoutConstraint.activate([
            roundedButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            roundedButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalOffSet),
            roundedButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalOffSet),
            roundedButton.topAnchor.constraint(equalTo: topAnchor, constant: UX.buttonTopOffset),
            roundedButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.buttonBottomOffset)
        ])
    }

    @objc
    func buttonPressed() {
        buttonClosure?()
    }

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer2
        roundedButton.setTitleColor(theme.colors.textPrimary, for: .normal)
        roundedButton.backgroundColor = theme.colors.layer3
        roundedButton.tintColor = theme.colors.textPrimary
        let image = UIImage(named: StandardImageIdentifiers.Large.delete)?.tinted(withColor: theme.colors.iconPrimary)
        roundedButton.setImage(image, for: .normal)
    }
}
