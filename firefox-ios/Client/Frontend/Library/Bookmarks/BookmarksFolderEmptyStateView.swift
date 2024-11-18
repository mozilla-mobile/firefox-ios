// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class BookmarksFolderEmptyStateView: UIView, ThemeApplicable {
    private struct UX {
        static let a11yTopMargin: CGFloat = 20
        static let TitleTopPadding: CGFloat = 16
        static let BodyTopMargin: CGFloat = 8
        static let ContentLeftRightMargins: CGFloat = 16
    }

    let windowUUID: WindowUUID
    let themeManager: Common.ThemeManager

    private lazy var logoImage: UIImageView = .build { imageView in
          imageView.contentMode = .scaleAspectFit
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.textAlignment = .center
        label.font = FXFontStyles.Bold.headline.scaledFont()
        label.numberOfLines = 0
        label.textColor = self.currentTheme().colors.textPrimary
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var bodyLabel: UILabel = .build { label in
        label.textAlignment = .center
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.textColor = self.currentTheme().colors.textPrimary
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var stackViewWrapper: UIStackView = .build { stackView in
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 0
    }

    init(windowUUID: WindowUUID,
         frame: CGRect = .zero,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false

        setupLayout()
    }

    func configure(isRoot: Bool) {
        titleLabel.text = isRoot ? .RootBookmarksFolderEmptyState.Title : .BookmarksFolderEmptyState.Title
        bodyLabel.text = isRoot ? .RootBookmarksFolderEmptyState.Body : .BookmarksFolderEmptyState.Body
        logoImage.image = UIImage(named: isRoot ? ImageIdentifiers.noBookmarksInRoot : ImageIdentifiers.noBookmarksInFolder)
    }

    private func setupLayout() {
        stackViewWrapper.addArrangedSubview(logoImage)
        stackViewWrapper.setCustomSpacing(UX.TitleTopPadding, after: logoImage)
        stackViewWrapper.addArrangedSubview(titleLabel)
        stackViewWrapper.setCustomSpacing(UX.BodyTopMargin, after: titleLabel)
        stackViewWrapper.addArrangedSubview(bodyLabel)
        addSubview(stackViewWrapper)

        let aspectRatio = (logoImage.image?.size.height ?? 1) / (logoImage.image?.size.width ?? 1)
        NSLayoutConstraint.activate([
            stackViewWrapper.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: UX.a11yTopMargin),
            stackViewWrapper.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackViewWrapper.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackViewWrapper.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            stackViewWrapper.centerYAnchor.constraint(equalTo: centerYAnchor),

            titleLabel.leadingAnchor.constraint(
                equalTo: stackViewWrapper.leadingAnchor, constant: UX.ContentLeftRightMargins),
            titleLabel.trailingAnchor.constraint(
                equalTo: stackViewWrapper.trailingAnchor, constant: -UX.ContentLeftRightMargins),

            bodyLabel.leadingAnchor.constraint(
                equalTo: stackViewWrapper.leadingAnchor, constant: UX.ContentLeftRightMargins),
            bodyLabel.trailingAnchor.constraint(
                equalTo: stackViewWrapper.trailingAnchor, constant: -UX.ContentLeftRightMargins),

            logoImage.widthAnchor.constraint(equalTo: stackViewWrapper.widthAnchor, multiplier: 0.5),
            logoImage.heightAnchor.constraint(equalTo: logoImage.widthAnchor, multiplier: aspectRatio)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    func applyTheme(theme: any Theme) {
        titleLabel.textColor = self.currentTheme().colors.textPrimary
        bodyLabel.textColor = self.currentTheme().colors.textPrimary
    }
}
