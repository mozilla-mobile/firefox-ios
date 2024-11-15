// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

public final class NavigationHeaderView: UIView {
    private struct UX {
        static let closeButtonSize: CGFloat = 30
        static let imageMargins: CGFloat = 10
        static let baseDistance: CGFloat = 21
        static let horizontalMargin: CGFloat = 16
        static let separatorHeight: CGFloat = 1
        static let largeFaviconImageSize: CGFloat = 48
    }

    public var backToMainMenuCallback: (() -> Void)?
    public var dismissMenuCallback: (() -> Void)?

    let titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.numberOfLines = 2
        label.accessibilityTraits.insert(.header)
        label.isAccessibilityElement = false
    }

    private lazy var closeButton: CloseButton = .build { button in
        button.addTarget(self, action: #selector(self.dismissMenuTapped), for: .touchUpInside)
    }

    private lazy var backButton: UIButton = .build { button in
        button.setImage(UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.chevronLeft)
            .withRenderingMode(.alwaysTemplate),
                        for: .normal)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.addTarget(self, action: #selector(self.backButtonTapped), for: .touchUpInside)
    }

    private let horizontalLine: UIView = .build()

    private var viewConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubviews(titleLabel, backButton, closeButton, horizontalLine)
    }

    // MARK: View Setup
    private func updateLayout(isAccessibilityCategory: Bool) {
        removeConstraints(constraints)
        closeButton.removeConstraints(closeButton.constraints)
        viewConstraints.removeAll()
        viewConstraints.append(contentsOf: [
            backButton.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: UX.imageMargins
            ),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            titleLabel.topAnchor.constraint(
                equalTo: topAnchor,
                constant: UX.baseDistance
            ),
            titleLabel.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -UX.baseDistance
            ),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            closeButton.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -UX.horizontalMargin
            ),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            horizontalLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            horizontalLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            horizontalLine.heightAnchor.constraint(equalToConstant: UX.separatorHeight)
        ])
        let closeButtonSizes = isAccessibilityCategory ? UX.largeFaviconImageSize : UX.closeButtonSize
        viewConstraints.append(closeButton.heightAnchor.constraint(equalToConstant: closeButtonSizes))
        viewConstraints.append(closeButton.widthAnchor.constraint(equalToConstant: closeButtonSizes))
        closeButton.layer.cornerRadius = 0.5 * closeButtonSizes
        NSLayoutConstraint.activate(viewConstraints)
    }

    public func setupAccessibility(closeButtonA11yLabel: String,
                                   closeButtonA11yId: String,
                                   titleA11yId: String? = nil,
                                   backButtonA11yLabel: String,
                                   backButtonA11yId: String) {
        let closeButtonViewModel = CloseButtonViewModel(a11yLabel: closeButtonA11yLabel,
                                                        a11yIdentifier: closeButtonA11yId)
        closeButton.configure(viewModel: closeButtonViewModel)
        if let titleA11yId {
            titleLabel.isAccessibilityElement = true
            titleLabel.accessibilityIdentifier = titleA11yId
        }
        backButton.accessibilityIdentifier = backButtonA11yId
        backButton.accessibilityLabel = backButtonA11yLabel
    }

    public func setViews(with title: String, and backButtonText: String) {
        titleLabel.text = title
        backButton.setTitle(backButtonText, for: .normal)
    }

    public func adjustLayout() {
        backButton.titleLabel?.font = FXFontStyles.Regular.body.scaledFont()
        updateLayout(isAccessibilityCategory: UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory)
    }

    public func updateHeaderLineView(isHidden: Bool) {
        if (isHidden && !horizontalLine.isHidden) || (!isHidden && horizontalLine.isHidden) {
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.horizontalLine.isHidden = isHidden
            }
        }
    }

    @objc
    private func backButtonTapped() {
        backToMainMenuCallback?()
    }

    @objc
    private func dismissMenuTapped() {
        dismissMenuCallback?()
    }

    // MARK: ThemeApplicable
    public func applyTheme(theme: Theme) {
        let buttonImage = UIImage(named: StandardImageIdentifiers.Medium.cross)?
            .withTintColor(theme.colors.iconSecondary)
        closeButton.setImage(buttonImage, for: .normal)
        closeButton.backgroundColor = theme.colors.layer2
        backButton.tintColor = theme.colors.iconAccent
        backButton.setTitleColor(theme.colors.textAccent, for: .normal)
        horizontalLine.backgroundColor = theme.colors.borderPrimary
        titleLabel.textColor = theme.colors.textPrimary
        backgroundColor = theme.colors.layer3
    }
}
