// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

class InactiveTabsFooterView: UICollectionReusableView, ReusableCell, ThemeApplicable {
    struct UX {
        static let buttonImagePadding: CGFloat = 11
        static let iPadOffset: CGFloat = 100
        static let iPhoneOffset: CGFloat = 23
        static let buttonTopOffset: CGFloat = 16
        static let buttonBottomOffset: CGFloat = 24
    }
    // MARK: - Properties
    var buttonClosure: (() -> Void)?

    // MARK: - UI Elements
    private lazy var roundedButton: PrimaryRoundedButton = .build { button in
        let viewModel = PrimaryRoundedButtonViewModel(
            title: .TabsTray.InactiveTabs.CloseAllInactiveTabsButton,
            a11yIdentifier: AccessibilityIdentifiers.TabTray.InactiveTabs.deleteButton,
            imageTitlePadding: UX.buttonImagePadding
        )
        button.configure(viewModel: viewModel)
        button.addTarget(self, action: #selector(self.buttonPressed), for: .touchUpInside)
    }

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

        let horizontalOffSet: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? UX.iPadOffset : UX.iPhoneOffset
        accessibilityIdentifier = AccessibilityIdentifiers.TabTray.InactiveTabs.footerView

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
        roundedButton.applyTheme(theme: theme)
        let image = UIImage(named: StandardImageIdentifiers.Large.delete)?.tinted(withColor: theme.colors.iconPrimary)
        roundedButton.configuration?.image = image?.withRenderingMode(.alwaysTemplate)
    }
}
