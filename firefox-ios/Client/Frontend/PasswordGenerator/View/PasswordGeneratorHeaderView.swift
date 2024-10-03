// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

 import Foundation
 import Common

final class PasswordGeneratorHeaderView: UIView, ThemeApplicable, Notifiable {
    var notificationCenter: NotificationProtocol
    private enum UX {
        static let headerIconLabelSpacing: CGFloat = 10
        static let headerVerticalPadding: CGFloat = 8
        static let headerImageHeight: CGFloat = 24
    }

    private var scaledHeaderImageSize = UIFontMetrics.default.scaledValue(for: UX.headerImageHeight)
    private lazy var headerImageWidthConstraint = headerImageView.widthAnchor.constraint(
        equalToConstant: scaledHeaderImageSize)
    private lazy var headerImageHeightConstraint = headerImageView.heightAnchor.constraint(
        equalToConstant: scaledHeaderImageSize)

    private lazy var headerLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Bold.body.scaledFont()
        label.text = .PasswordGenerator.Title
        label.accessibilityIdentifier = AccessibilityIdentifiers.PasswordGenerator.headerLabel
        label.accessibilityTraits = .header
    }

    private lazy var headerImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: StandardImageIdentifiers.Large.login)?.withRenderingMode(.alwaysTemplate)
        imageView.accessibilityIdentifier = AccessibilityIdentifiers.PasswordGenerator.headerImage
    }

    init(frame: CGRect = .zero, notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.notificationCenter = notificationCenter
        super.init(frame: frame)
        self.accessibilityIdentifier = AccessibilityIdentifiers.PasswordGenerator.header
        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        self.addSubviews(headerImageView, headerLabel)

        // Header elements layout
        NSLayoutConstraint.activate([
            headerImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            headerImageView.centerYAnchor.constraint(equalTo: headerLabel.centerYAnchor),
            headerImageWidthConstraint,
            headerImageHeightConstraint,
            headerLabel.leadingAnchor.constraint(
                equalTo: headerImageView.trailingAnchor,
                constant: UX.headerIconLabelSpacing),
            headerLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            headerLabel.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: UX.headerVerticalPadding),
            headerLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    func applyTheme(theme: any Common.Theme) {
        headerImageView.tintColor = theme.colors.iconPrimary
        headerLabel.textColor = theme.colors.textPrimary
    }

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            applyDynamicFontChange()
        default: break
        }
    }

    func applyDynamicFontChange() {
        scaledHeaderImageSize = UIFontMetrics.default.scaledValue(for: UX.headerImageHeight)
        headerImageWidthConstraint.constant = scaledHeaderImageSize
        headerImageHeightConstraint.constant = scaledHeaderImageSize
        setNeedsLayout()
        layoutIfNeeded()
    }
}
