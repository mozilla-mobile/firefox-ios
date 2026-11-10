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
    public let iconTintColor: UIColor?

    public init(title: String, image: String, shouldUseRenderMode: Bool, iconTintColor: UIColor? = nil) {
        self.title = title
        self.image = image
        self.shouldUseRenderMode = shouldUseRenderMode
        self.iconTintColor = iconTintColor
    }
}

public final class MenuSiteProtectionsHeader: UIView, ThemeApplicable {
    private enum UX {
        static let closeButtonSize: CGFloat = 30
        static let novaCloseButtonSize: CGFloat = 44
        static let contentLabelsSpacing: CGFloat = 1
        static let horizontalContentMargin: CGFloat = 16
        static let favIconSize: CGFloat = 40
        static let badgesTopMargin: CGFloat = 4
        static let badgesSpacing: CGFloat = 8
    }

    public var closeButtonCallback: (() -> Void)?
    public var siteProtectionsButtonCallback: (() -> Void)?
    public var adBlockerButtonCallback: (() -> Void)?
    public var privacyPanelButtonCallback: (() -> Void)?
    public var mainMenuHelper: MainMenuInterface = MainMenuHelper()

    private var trailingContentConstraints: [NSLayoutConstraint] = []
    private var visibleBadges: [MenuSiteBadge] = []
    private var badgeRows: [[MenuSiteBadge]] = []

    public func setCloseButtonHidden(_ hidden: Bool) {
        guard closeButton.isHidden != hidden else { return }
        closeButton.isHidden = hidden
        NSLayoutConstraint.deactivate(trailingContentConstraints)
        if hidden {
            trailingContentConstraints = [
                contentLabels.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor,
                                                        constant: -UX.horizontalContentMargin),
                badgesStack.trailingAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.trailingAnchor,
                                                      constant: -UX.horizontalContentMargin)
            ]
        } else {
            trailingContentConstraints = [
                contentLabels.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor,
                                                        constant: -UX.horizontalContentMargin),
                badgesStack.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor)
            ]
        }
        NSLayoutConstraint.activate(trailingContentConstraints)
    }

    private var theme: Theme?

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
        stack.axis = .vertical
        stack.alignment = .leading
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

    private lazy var privacyPanelBadge: MenuSiteBadge = {
        let badge = MenuSiteBadge(mainMenuHelper: mainMenuHelper)
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.tapHandler = { [weak self] in self?.privacyPanelButtonCallback?() }
        return badge
    }()

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            setNeedsLayout()
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        layoutBadgeRows()
    }

    /// Distributes the visible badges into rows, wrapping to a new row when a badge doesn't fit.
    private func layoutBadgeRows() {
        let isLarge = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        let maxX = closeButton.isHidden
            ? safeAreaLayoutGuide.layoutFrame.maxX - UX.horizontalContentMargin
            : closeButton.frame.minX
        let availableWidth = maxX - favicon.frame.minX

        var rows: [[MenuSiteBadge]] = []
        var rowWidth: CGFloat = 0
        for badge in visibleBadges {
            let width = badge.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width
            if !isLarge, !rows.isEmpty, rowWidth + UX.badgesSpacing + width <= availableWidth {
                rows[rows.count - 1].append(badge)
                rowWidth += UX.badgesSpacing + width
            } else {
                rows.append([badge])
                rowWidth = width
            }
        }

        guard rows != badgeRows else { return }
        badgeRows = rows
        badgesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for row in rows {
            let rowStack = UIStackView(arrangedSubviews: row)
            rowStack.axis = .horizontal
            rowStack.alignment = .center
            rowStack.spacing = UX.badgesSpacing
            badgesStack.addArrangedSubview(rowStack)
        }
    }

    private func setVisibleBadges(_ badges: [MenuSiteBadge]) {
        guard badges != visibleBadges else { return }
        visibleBadges = badges
        badgeRows = []
        setNeedsLayout()
    }

    private func setupViews() {
        contentLabels.addArrangedSubview(titleLabel)
        contentLabels.addArrangedSubview(subtitleLabel)
        addSubviews(contentLabels, favicon, closeButton, badgesStack)
        visibleBadges = [siteProtectionsBadge]

        let badgesTopFromFavicon = badgesStack.topAnchor.constraint(
            greaterThanOrEqualTo: favicon.bottomAnchor,
            constant: UX.badgesTopMargin
        )

        let badgesTopFromLabels = badgesStack.topAnchor.constraint(
            equalTo: contentLabels.bottomAnchor,
            constant: UX.badgesTopMargin
        )
        badgesTopFromLabels.priority = .defaultHigh
        trailingContentConstraints = [
            contentLabels.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor,
                                                    constant: -UX.horizontalContentMargin),
            badgesStack.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor)
        ]
        NSLayoutConstraint.activate(trailingContentConstraints)
        NSLayoutConstraint.activate([
            contentLabels.topAnchor.constraint(equalTo: self.topAnchor),
            favicon.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor,
                                             constant: UX.horizontalContentMargin),
            favicon.topAnchor.constraint(equalTo: self.topAnchor),
            favicon.trailingAnchor.constraint(equalTo: contentLabels.leadingAnchor, constant: -UX.horizontalContentMargin),
            favicon.widthAnchor.constraint(equalToConstant: UX.favIconSize),
            favicon.heightAnchor.constraint(equalToConstant: UX.favIconSize),

            closeButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor,
                                                  constant: -UX.horizontalContentMargin),
            closeButton.topAnchor.constraint(equalTo: self.topAnchor),

            badgesTopFromLabels,
            badgesTopFromFavicon,
            badgesStack.leadingAnchor.constraint(equalTo: favicon.leadingAnchor),
            badgesStack.bottomAnchor.constraint(equalTo: self.bottomAnchor)
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
        stateIconTintColor: UIColor? = nil,
        stateTextColor: UIColor? = nil,
        stateChevronTintColor: UIColor? = nil,
        adBlocker: MenuSiteAdBlockerBadgeData? = nil,
        privacyPanel: MenuSiteAdBlockerBadgeData? = nil
    ) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        siteProtectionsBadge.configure(text: state,
                                       iconName: stateImage,
                                       useTemplate: shouldUseRenderMode,
                                       iconTintColor: stateIconTintColor,
                                       textColor: stateTextColor,
                                       chevronTintColor: stateChevronTintColor)
        var badges = [siteProtectionsBadge]
        if let adBlocker {
            badges.append(adBlockerBadge)
            adBlockerBadge.configure(text: adBlocker.title,
                                     iconName: adBlocker.image,
                                     useTemplate: adBlocker.shouldUseRenderMode,
                                     iconTintColor: adBlocker.iconTintColor)
        }
        if let privacyPanel {
            badges.append(privacyPanelBadge)
            privacyPanelBadge.configure(text: privacyPanel.title,
                                        iconName: privacyPanel.image,
                                        useTemplate: privacyPanel.shouldUseRenderMode,
                                        iconTintColor: privacyPanel.iconTintColor)
        }
        setVisibleBadges(badges)
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
        self.theme = theme
        titleLabel.textColor = theme.colors.textPrimary
        subtitleLabel.textColor = theme.colors.textSecondary
        closeButton.tintColor = theme.isNova ? theme.colors.iconPrimary : theme.colors.iconSecondary
        if theme.isNova {
            let size = UX.novaCloseButtonSize
            closeButton.updateButtonSize(CGSize(width: size, height: size))
            closeButton.layer.cornerRadius = 0.5 * size
        }
        if #available(iOS 26.0, *), theme.isNova {
            closeButton.applyProminentClearGlassConfiguration(backgroundColor: theme.colors.layer2,
                                                              foregroundColor: theme.colors.iconPrimary)
        } else {
            let closeBackground = theme.isNova ? theme.colors.layer2 : theme.colors.actionCloseButton
            closeButton.backgroundColor = closeBackground.withAlphaComponent(mainMenuHelper.backgroundAlpha())
        }
        siteProtectionsBadge.applyTheme(theme: theme)
        adBlockerBadge.applyTheme(theme: theme)
        privacyPanelBadge.applyTheme(theme: theme)
    }
}
