// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import SiteImageView
import ComponentLibrary

public struct MenuSiteAdBlockerBadgeData {
    public let title: String
    public let image: String
    public let shouldUseRenderMode: Bool

    public init(title: String, image: String, shouldUseRenderMode: Bool) {
        self.title = title
        self.image = image
        self.shouldUseRenderMode = shouldUseRenderMode
    }
}

public final class MenuSiteProtectionsHeader: UIView, ThemeApplicable {
    private struct UX {
        static let closeButtonSize: CGFloat = 30
        static let contentLabelsSpacing: CGFloat = 1
        static let horizontalContentMargin: CGFloat = 16
        static let favIconSize: CGFloat = 40
        static let badgesTopMargin: CGFloat = 4
        static let badgesSpacing: CGFloat = 8
    }

    public var closeButtonCallback: (() -> Void)?
    public var siteProtectionsButtonCallback: (() -> Void)?
    public var adBlockerButtonCallback: (() -> Void)?
    public var mainMenuHelper: MainMenuInterface = MainMenuHelper()

    private var contentLabels: UIStackView = .build { stack in
        stack.distribution = .fillProportionally
        stack.axis = .vertical
        stack.spacing = UX.contentLabelsSpacing
        stack.isAccessibilityElement = true
    }

    private var favicon: FaviconImageView = .build { favicon in
        favicon.manuallySetImage(
            UIImage(named: StandardImageIdentifiers.Large.globe)?.withRenderingMode(.alwaysTemplate) ?? UIImage())
    }

    private let titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.callout.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.isAccessibilityElement = false
    }

    private let subtitleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.isAccessibilityElement = false
    }

    private lazy var closeButton: CloseButton = .build { button in
        button.addTarget(self, action: #selector(self.closeButtonTapped), for: .touchUpInside)
        let imageName = StandardImageIdentifiers.Medium.cross
        button.setImage(UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate) ?? UIImage(), for: .normal)
    }

    private lazy var badgesStack: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = UX.badgesSpacing
    }

    private lazy var siteProtectionsBadge: MenuSiteBadge = {
        let badge = MenuSiteBadge(mainMenuHelper: mainMenuHelper)
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.tapHandler = { [weak self] in self?.siteProtectionsButtonCallback?() }
        return badge
    }()

    private lazy var adBlockerBadge: MenuSiteBadge = {
        let badge = MenuSiteBadge(mainMenuHelper: mainMenuHelper)
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.tapHandler = { [weak self] in self?.adBlockerButtonCallback?() }
        return badge
    }()

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentLabels.addArrangedSubview(titleLabel)
        contentLabels.addArrangedSubview(subtitleLabel)
        addSubviews(contentLabels, favicon, closeButton, badgesStack)
        badgesStack.addArrangedSubview(siteProtectionsBadge)

        let badgesTopFromFavicon = badgesStack.topAnchor.constraint(
            greaterThanOrEqualTo: favicon.bottomAnchor,
            constant: UX.badgesTopMargin
        )

        let badgesTopFromLabels = badgesStack.topAnchor.constraint(
            equalTo: contentLabels.bottomAnchor,
            constant: UX.badgesTopMargin
        )
        badgesTopFromLabels.priority = .defaultHigh
        NSLayoutConstraint.activate([
            contentLabels.topAnchor.constraint(equalTo: self.topAnchor),
            contentLabels.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor,
                                                    constant: -UX.horizontalContentMargin),

            favicon.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: UX.horizontalContentMargin),
            favicon.topAnchor.constraint(equalTo: self.topAnchor),
            favicon.trailingAnchor.constraint(equalTo: contentLabels.leadingAnchor, constant: -UX.horizontalContentMargin),
            favicon.widthAnchor.constraint(equalToConstant: UX.favIconSize),
            favicon.heightAnchor.constraint(equalToConstant: UX.favIconSize),

            closeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -UX.horizontalContentMargin),
            closeButton.topAnchor.constraint(equalTo: self.topAnchor),

            badgesTopFromLabels,
            badgesTopFromFavicon,
            badgesStack.leadingAnchor.constraint(equalTo: favicon.leadingAnchor),
            badgesStack.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor),
            badgesStack.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize)
        ])

        closeButton.layer.cornerRadius = 0.5 * UX.closeButtonSize
    }

    public func setupDetails(
        title: String?,
        subtitle: String?,
        image: String?,
        state: String,
        stateImage: String,
        shouldUseRenderMode: Bool,
        adBlocker: MenuSiteAdBlockerBadgeData? = nil
    ) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        siteProtectionsBadge.configure(text: state,
                                       iconName: stateImage,
                                       useTemplate: shouldUseRenderMode)
        if let adBlocker {
            if adBlockerBadge.superview == nil {
                badgesStack.addArrangedSubview(adBlockerBadge)
            }
            adBlockerBadge.configure(text: adBlocker.title,
                                     iconName: adBlocker.image,
                                     useTemplate: adBlocker.shouldUseRenderMode)
        } else {
            adBlockerBadge.removeFromSuperview()
        }

        let image = FaviconImageViewModel(siteURLString: image,
                                          faviconCornerRadius: UX.favIconSize / 2)
        favicon.setFavicon(image)
    }

    public func setupAccessibility(closeButtonA11yLabel: String,
                                   closeButtonA11yId: String) {
        let closeButtonViewModel = CloseButtonViewModel(a11yLabel: closeButtonA11yLabel,
                                                        a11yIdentifier: closeButtonA11yId)
        closeButton.configure(viewModel: closeButtonViewModel)
        contentLabels.accessibilityLabel = "\(titleLabel.text ?? "") \(subtitleLabel.text ?? "")"
    }

    @objc
    func closeButtonTapped() {
        closeButtonCallback?()
    }

    public func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        subtitleLabel.textColor = theme.colors.textSecondary
        closeButton.tintColor = theme.colors.iconSecondary
        closeButton.backgroundColor = theme.colors.actionCloseButton.withAlphaComponent(mainMenuHelper.backgroundAlpha())
        siteProtectionsBadge.applyTheme(theme: theme)
        adBlockerBadge.applyTheme(theme: theme)
    }
}
