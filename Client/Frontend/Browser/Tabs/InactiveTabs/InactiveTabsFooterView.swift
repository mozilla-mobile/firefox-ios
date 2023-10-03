// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class InactiveTabsFooterView: UICollectionReusableView, ReusableCell, ThemeApplicable {
    private struct UX {
        static let borderViewMargin: CGFloat = 16
        static let titleFontSize: CGFloat = 17
        static let buttonInset: CGFloat = 14
        static let buttonImagePadding: CGFloat = 11
    }

    var buttonClosure: (() -> Void)?
    private let containerView = UIView()

    private lazy var roundedButton: UIButton = .build { button in
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredBoldFont(
            withTextStyle: .body,
            size: UX.titleFontSize)
        button.setTitle(.TabsTray.InactiveTabs.CloseAllInactiveTabsButton, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.layer.cornerRadius = 13.5
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.clear.cgColor
        button.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.inactiveTabDeleteButton
        button.addTarget(self, action: #selector(self.buttonPressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        addSubview(roundedButton)

        roundedButton.setInsets(forContentPadding: UIEdgeInsets(top: UX.buttonInset,
                                                                left: UX.buttonInset,
                                                                bottom: UX.buttonInset,
                                                                right: UX.buttonInset),
                                imageTitlePadding: UX.buttonImagePadding)

        let trailingOffSet: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 100 : 23
        let leadingOffSet: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 100 : 23

        NSLayoutConstraint.activate([
            roundedButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            roundedButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: trailingOffSet),
            roundedButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -leadingOffSet),
            roundedButton.topAnchor.constraint(equalTo: topAnchor, constant: UX.borderViewMargin),
            roundedButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24)
        ])
    }

    @objc
    func buttonPressed() {
        self.buttonClosure?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    func applyTheme(theme: Theme) {
        backgroundColor = .clear
        roundedButton.setTitleColor(theme.colors.textPrimary, for: .normal)
        roundedButton.backgroundColor = theme.colors.layer3
        roundedButton.tintColor = theme.colors.textPrimary
        let image = UIImage(named: StandardImageIdentifiers.Large.delete)?.tinted(withColor: theme.colors.iconPrimary)
        roundedButton.setImage(image, for: .normal)
    }
}
