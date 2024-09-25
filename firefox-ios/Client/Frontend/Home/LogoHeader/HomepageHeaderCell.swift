// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common

struct HomepageHeaderCellViewModel {
    var showiPadSetup: Bool
    var showPrivateModeToggle: Bool
    var isPrivate: Bool

    private var action: (() -> Void)
    private var homepageTelemetry = HomepageTelemetry()

    init(isPrivate: Bool, showiPadSetup: Bool, showPrivateModeToggle: Bool, action: @escaping () -> Void) {
        self.isPrivate = isPrivate
        self.showiPadSetup = showiPadSetup
        self.showPrivateModeToggle = showPrivateModeToggle
        self.action = action
    }

    func switchMode() {
        action()
        homepageTelemetry.sendHomepageTappedTelemetry(enteringPrivateMode: !isPrivate)
    }
}

// Header for the homepage in both normal and private mode
// Contains the firefox logo and the private browsing shortcut button
class HomepageHeaderCell: UICollectionViewCell, ReusableCell, ThemeApplicable {
    enum UX {
        static let iPhoneTopConstant: CGFloat = 16
        static let iPadTopConstant: CGFloat = 54
        static let circleSize = CGRect(width: 40, height: 40)
    }

    var viewModel: HomepageHeaderCellViewModel?

    private lazy var stackContainer: UIStackView = .build { stackView in
        stackView.axis = .horizontal
    }

    private lazy var logoHeaderCell: HomeLogoHeaderCell = {
        let logoHeader = HomeLogoHeaderCell()
        return logoHeader
    }()

    private lazy var privateModeButton: UIButton = .build { [weak self] button in
        let maskImage = UIImage(named: StandardImageIdentifiers.Large.privateMode)?.withRenderingMode(.alwaysTemplate)
        button.setImage(maskImage, for: .normal)
        button.frame = UX.circleSize
        button.layer.cornerRadius = button.frame.size.width / 2
        button.addTarget(self, action: #selector(self?.switchMode), for: .touchUpInside)
        button.accessibilityLabel = .TabTrayToggleAccessibilityLabel
        button.accessibilityHint = .TabTrayToggleAccessibilityHint
        button.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.OtherButtons.privateModeToggleButton
    }

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupView(with showiPadSetup: Bool) {
        stackContainer.addArrangedSubview(logoHeaderCell.contentView)
        stackContainer.addArrangedSubview(privateModeButton)
        contentView.addSubview(stackContainer)

        setupConstraints(for: showiPadSetup)
    }

    private var logoConstraints = [NSLayoutConstraint]()

    private func setupConstraints(for iPadSetup: Bool) {
        NSLayoutConstraint.deactivate(logoConstraints)
        let topAnchorConstant = iPadSetup ? UX.iPadTopConstant : UX.iPhoneTopConstant
        logoConstraints = [
            stackContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topAnchorConstant),
            stackContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).priority(.defaultLow),

            privateModeButton.widthAnchor.constraint(equalToConstant: UX.circleSize.width),
            privateModeButton.centerYAnchor.constraint(equalTo: stackContainer.centerYAnchor),
            logoHeaderCell.contentView.centerYAnchor.constraint(equalTo: stackContainer.centerYAnchor)
        ]

        NSLayoutConstraint.activate(logoConstraints)
    }

    func configure(with viewModel: HomepageHeaderCellViewModel) {
        self.viewModel = viewModel
        setupView(with: viewModel.showiPadSetup)
        logoHeaderCell.configure(with: viewModel.showiPadSetup)
        privateModeButton.isHidden = !viewModel.showPrivateModeToggle
    }

    @objc
    private func switchMode() {
        viewModel?.switchMode()
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        logoHeaderCell.applyTheme(theme: theme)
        guard let viewModel else { return }
        let privateModeButtonTintColor = viewModel.isPrivate ? theme.colors.layer2 : theme.colors.iconPrimary
        privateModeButton.imageView?.tintColor = privateModeButtonTintColor
        privateModeButton.backgroundColor = viewModel.isPrivate ? .white : .clear
        privateModeButton.accessibilityValue = viewModel.isPrivate ?
            .TabTrayToggleAccessibilityValueOn :
            .TabTrayToggleAccessibilityValueOff
    }
}
