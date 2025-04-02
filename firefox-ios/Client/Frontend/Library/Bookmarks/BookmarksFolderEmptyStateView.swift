// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import ComponentLibrary

final class BookmarksFolderEmptyStateView: UIView, ThemeApplicable {
    private struct UX {
        static let a11yTopMargin: CGFloat = 16
        static let titleTopMargin: CGFloat = 16
        static let bodyTopMargin: CGFloat = 8
        static let buttonTopMargin: CGFloat = 16
        static let contentLeftRightMargins: CGFloat = 16
        static let stackViewWidthMultiplier: CGFloat = 0.9
        static let imageWidth: CGFloat = 200
        static let signInButtonMaxWidth: CGFloat = 306
    }

    var signInAction: (() -> Void)?

    private lazy var logoImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.emptyStateLogoImage
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.textAlignment = .center
        label.font = FXFontStyles.Bold.headline.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.emptyStateTitleLabel
    }

    private lazy var bodyLabel: UILabel = .build { label in
        label.textAlignment = .center
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.emptyStateBodyLabel
    }

    private lazy var signInButton: PrimaryRoundedButton = .build { button in
        let viewModel = PrimaryRoundedButtonViewModel(
            title: .Bookmarks.EmptyState.Root.ButtonTitle,
            a11yIdentifier: AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.emptyStateSignInButton
        )
        button.configure(viewModel: viewModel)
        button.addTarget(self, action: #selector(self.didTapSignIn), for: .touchUpInside)
    }

    private lazy var stackViewWrapper: UIStackView = .build { stackView in
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 0
    }

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(isRoot: Bool, isSignedIn: Bool) {
        titleLabel.text = isRoot ? .Bookmarks.EmptyState.Root.Title : .Bookmarks.EmptyState.Nested.Title
        if isRoot {
            bodyLabel.text = isSignedIn ? .Bookmarks.EmptyState.Root.BodySignedIn
                                        : .Bookmarks.EmptyState.Root.BodySignedOut
        } else {
            bodyLabel.text = .Bookmarks.EmptyState.Nested.Body
        }
        logoImage.image = UIImage(named: isRoot ? ImageIdentifiers.noBookmarksInRoot : ImageIdentifiers.noBookmarksInFolder)
        signInButton.isHidden = !isRoot || isSignedIn
    }

    private func setupLayout() {
        stackViewWrapper.addArrangedSubview(logoImage)
        stackViewWrapper.setCustomSpacing(UX.titleTopMargin, after: logoImage)
        stackViewWrapper.addArrangedSubview(titleLabel)
        stackViewWrapper.setCustomSpacing(UX.bodyTopMargin, after: titleLabel)
        stackViewWrapper.addArrangedSubview(bodyLabel)
        stackViewWrapper.setCustomSpacing(UX.buttonTopMargin, after: bodyLabel)
        stackViewWrapper.addArrangedSubview(signInButton)
        addSubview(stackViewWrapper)

        let aspectRatio = (logoImage.image?.size.height ?? 1) / (logoImage.image?.size.width ?? 1)
        NSLayoutConstraint.activate([
            stackViewWrapper.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: UX.a11yTopMargin),
            stackViewWrapper.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            stackViewWrapper.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackViewWrapper.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackViewWrapper.widthAnchor.constraint(equalTo: widthAnchor, multiplier: UX.stackViewWidthMultiplier),

            titleLabel.leadingAnchor.constraint(
                equalTo: stackViewWrapper.leadingAnchor, constant: UX.contentLeftRightMargins),
            titleLabel.trailingAnchor.constraint(
                equalTo: stackViewWrapper.trailingAnchor, constant: -UX.contentLeftRightMargins),

            bodyLabel.leadingAnchor.constraint(
                equalTo: stackViewWrapper.leadingAnchor, constant: UX.contentLeftRightMargins),
            bodyLabel.trailingAnchor.constraint(
                equalTo: stackViewWrapper.trailingAnchor, constant: -UX.contentLeftRightMargins),

            signInButton.widthAnchor.constraint(equalToConstant: UX.signInButtonMaxWidth),

            logoImage.widthAnchor.constraint(equalToConstant: UX.imageWidth),
            logoImage.heightAnchor.constraint(equalTo: logoImage.widthAnchor, multiplier: aspectRatio)
        ])
    }

    // MARK: Actions
    @objc
    private func didTapSignIn() {
        signInAction?()
    }

    // MARK: ThemeApplicable
    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        bodyLabel.textColor = theme.colors.textPrimary
        signInButton.applyTheme(theme: theme)
    }
}
