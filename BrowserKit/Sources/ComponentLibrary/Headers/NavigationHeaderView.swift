// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

public protocol NavigationHeaderViewActionsHandler: AnyObject {
    func backToMainView()
    func dismissMenu()
}

public final class NavigationHeaderView: UIView {
    private struct UX {
        static let closeButtonSize: CGFloat = 30
        static let imageMargins: CGFloat = 10
        static let baseDistance: CGFloat = 20
        static let horizontalMargin: CGFloat = 16
        static let separatorHeight: CGFloat = 1
    }

    let siteTitleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.numberOfLines = 2
        label.accessibilityTraits.insert(.header)
    }

    private lazy var closeButton: CloseButton = .build { button in
        button.layer.cornerRadius = 0.5 * UX.closeButtonSize
        button.addTarget(self, action: #selector(self.dismissMenuTapped), for: .touchUpInside)
    }

    private lazy var backButton: UIButton = .build { button in
        button.setImage(UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.chevronLeft)
            .withRenderingMode(.alwaysTemplate),
                        for: .normal)
        button.titleLabel?.font = FXFontStyles.Regular.body.scaledFont()
        button.addTarget(self, action: #selector(self.backButtonTapped), for: .touchUpInside)
    }

    private let horizontalLine: UIView = .build { _ in }

    public weak var navigationDelegate: NavigationHeaderViewActionsHandler?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Setup
    private func setupView() {
        addSubviews(siteTitleLabel, backButton, closeButton, horizontalLine)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: UX.imageMargins
            ),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            siteTitleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            siteTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            siteTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            siteTitleLabel.topAnchor.constraint(
                equalTo: topAnchor,
                constant: UX.baseDistance
            ),
            siteTitleLabel.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -UX.baseDistance
            ),

            closeButton.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -UX.horizontalMargin
            ),
            closeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.closeButtonSize),
            closeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: UX.closeButtonSize),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            horizontalLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            horizontalLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            horizontalLine.heightAnchor.constraint(equalToConstant: UX.separatorHeight)
        ])
    }

    public func setViews(with title: String, and backButtonText: String) {
        siteTitleLabel.text = title
        backButton.setTitle(backButtonText, for: .normal)
    }

    @objc
    private func backButtonTapped() {
        navigationDelegate?.backToMainView()
    }

    @objc
    private func dismissMenuTapped() {
        navigationDelegate?.dismissMenu()
    }

    // MARK: ThemeApplicable
    public func applyTheme(theme: Theme) {
        let buttonImage = UIImage(named: StandardImageIdentifiers.Medium.cross)?
            .withTintColor(theme.colors.iconSecondary)
        closeButton.setImage(buttonImage, for: .normal)
        closeButton.backgroundColor = theme.colors.layer2
        backButton.tintColor = theme.colors.iconAction
        backButton.setTitleColor(theme.colors.textAccent, for: .normal)
        horizontalLine.backgroundColor = theme.colors.borderPrimary
        siteTitleLabel.textColor = theme.colors.textPrimary
    }
}
