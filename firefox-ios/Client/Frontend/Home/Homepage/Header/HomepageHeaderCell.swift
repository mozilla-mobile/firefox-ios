// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common
import Shared

// Header for the homepage in both normal and private mode
// Contains the firefox logo and the quick answers button
class HomepageHeaderCell: UICollectionViewCell, ReusableCell, ThemeApplicable {
    enum UX {
        static let firefoxLogoImageSize = CGSize(width: 40, height: 40)
        static let firefoxTextImageSize = CGSize(width: 90, height: 40)
        static let interImageSpacing: CGFloat = 10
        static let quickAnswersButtonSize = CGSize(width: 40, height: 40)

        static func contentWidth() -> CGFloat {
            return UX.firefoxLogoImageSize.width + UX.interImageSpacing + UX.firefoxTextImageSize.width
        }
    }

    typealias a11y = AccessibilityIdentifiers.FirefoxHomepage.OtherButtons

    /// Called when the quick answers button is tapped
    var onQuickAnswersTapped: (() -> Void)?

    private var headerState: HeaderState?
    private var hasConfiguredView = false
    private var headerConstraints = [NSLayoutConstraint]()
    private var logoConstraints = [NSLayoutConstraint]()

    private lazy var stackContainer: UIStackView = .build { stackView in
        stackView.axis = .horizontal
    }

    private lazy var logoContainerView: UIView = .build()

    private lazy var logoStackView: UIStackView = .build { view in
        view.backgroundColor = .clear
        view.accessibilityIdentifier = a11y.logoID
        view.accessibilityLabel = AppName.shortName.rawValue
        view.isAccessibilityElement = true
        view.accessibilityTraits = .image
    }

    private lazy var logoImage: UIImageView = .build { imageView in
        imageView.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoBall)
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var logoTextImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var quickAnswersButton: UIButton = .build { button in
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "waveform", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.accessibilityIdentifier = "HomepageHeaderCell.quickAnswersButton"
        button.accessibilityLabel = String.FirefoxHomepage.QuickAnswersButtonAccessibilityLabel
        button.addTarget(self, action: #selector(self.quickAnswersButtonTapped), for: .touchUpInside)
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
        if !hasConfiguredView {
            contentView.backgroundColor = .clear
            logoStackView.addArrangedSubview(logoImage)
            logoStackView.addArrangedSubview(logoTextImage)

            logoContainerView.addSubview(logoStackView)
            stackContainer.addArrangedSubview(logoContainerView)
            stackContainer.addArrangedSubview(UIView()) // flexible spacer
            stackContainer.addArrangedSubview(quickAnswersButton)
            contentView.addSubview(stackContainer)

            NSLayoutConstraint.activate([
                logoStackView.topAnchor.constraint(equalTo: logoContainerView.topAnchor),
                logoStackView.bottomAnchor.constraint(equalTo: logoContainerView.bottomAnchor),
                quickAnswersButton.widthAnchor.constraint(equalToConstant: UX.quickAnswersButtonSize.width),
                quickAnswersButton.heightAnchor.constraint(equalToConstant: UX.quickAnswersButtonSize.height),
            ])

            hasConfiguredView = true
        }

        logoStackView.spacing = UX.interImageSpacing

        setupConstraints()
        setupLogoConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.deactivate(headerConstraints)
        headerConstraints = [
            stackContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).priority(.defaultLow),

//            logoContainerView.centerYAnchor.constraint(equalTo: stackContainer.centerYAnchor)
        ]

        NSLayoutConstraint.activate(headerConstraints)
    }

    private func setupLogoConstraints() {
        NSLayoutConstraint.deactivate(logoConstraints)
        logoConstraints = [
            logoImage.widthAnchor.constraint(equalToConstant: UX.firefoxLogoImageSize.width),
            logoImage.heightAnchor.constraint(equalToConstant: UX.firefoxLogoImageSize.height),
            logoTextImage.widthAnchor.constraint(equalToConstant: UX.firefoxTextImageSize.width),
            logoTextImage.heightAnchor.constraint(equalToConstant: UX.firefoxTextImageSize.height)
        ]

        NSLayoutConstraint.activate(logoConstraints)
    }

    func configure(headerState: HeaderState) {
        self.headerState = headerState
        setupView(with: headerState.showiPadSetup)
    }

    @objc
    private func quickAnswersButtonTapped() {
        onQuickAnswersTapped?()
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        // TODO: FXIOS-10851 This can be moved to the new homescreen wallpaper fetching redux
        let wallpaperManager = WallpaperManager()
        let browserViewType = store.state.componentState(
            BrowserViewControllerState.self,
            for: .browserViewController,
            window: currentWindowUUID
        )?.browserViewType

        if let logoTextColor = wallpaperManager.currentWallpaper.logoTextColor, browserViewType != .privateHomepage {
            logoTextImage.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoText)
                .withRenderingMode(.alwaysTemplate)
            logoTextImage.tintColor = logoTextColor
        } else {
            logoTextImage.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoText)
                .withRenderingMode(.alwaysTemplate)
            logoTextImage.tintColor = theme.colors.textPrimary
        }
        quickAnswersButton.tintColor = theme.colors.textPrimary
    }
}
