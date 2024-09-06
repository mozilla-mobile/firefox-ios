// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import SiteImageView
import ComponentLibrary

final class TrackingProtectionHeaderView: UIView, ThemeApplicable {
    private struct UX {
        static let headerLinesLimit: Int = 2
        static let siteDomainLabelsVerticalSpacing: CGFloat = 12
        static let faviconImageSize: CGFloat = 40
        static let closeButtonSize: CGFloat = 30
        static let horizontalMargin: CGFloat = 16
    }

    var closeButtonCallback: (() -> Void)?

    private var faviconHeightConstraint: NSLayoutConstraint?
    private var faviconWidthConstraint: NSLayoutConstraint?
    private var closeButtonHeightConstraint: NSLayoutConstraint?
    private var closeButtonWidthConstraint: NSLayoutConstraint?

    private lazy var headerLabelsContainer: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.alignment = .leading
        stack.axis = .vertical
        stack.spacing = TPMenuUX.UX.headerLabelDistance
    }

    private var favicon: FaviconImageView = .build { favicon in
        favicon.manuallySetImage(
            UIImage(named: StandardImageIdentifiers.Large.globe)?.withRenderingMode(.alwaysTemplate) ?? UIImage())
    }

    private let siteDisplayTitleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.numberOfLines = UX.headerLinesLimit
        label.adjustsFontForContentSizeCategory = true
    }

    private let siteDomainLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption1.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private var closeButton: CloseButton = .build { button in
        button.layer.cornerRadius = 0.5 * UX.closeButtonSize
    }

    init() {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        headerLabelsContainer.addArrangedSubview(siteDisplayTitleLabel)
        headerLabelsContainer.addArrangedSubview(siteDomainLabel)
        addSubviews(favicon, headerLabelsContainer, closeButton)
        faviconHeightConstraint = favicon.heightAnchor.constraint(equalToConstant: UX.faviconImageSize)
        faviconWidthConstraint = favicon.widthAnchor.constraint(equalToConstant: UX.faviconImageSize)
        NSLayoutConstraint.activate([
            favicon.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            favicon.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            faviconHeightConstraint ?? NSLayoutConstraint(),
            faviconWidthConstraint ?? NSLayoutConstraint(),

            headerLabelsContainer.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: UX.siteDomainLabelsVerticalSpacing
            ),
            headerLabelsContainer.bottomAnchor.constraint(
                equalTo: self.bottomAnchor,
                constant: -UX.siteDomainLabelsVerticalSpacing
            ),
            headerLabelsContainer.leadingAnchor.constraint(
                equalTo: favicon.trailingAnchor,
                constant: UX.siteDomainLabelsVerticalSpacing
            ),
            headerLabelsContainer.trailingAnchor.constraint(
                equalTo: closeButton.leadingAnchor,
                constant: -UX.horizontalMargin
            ),

            closeButton.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: -UX.horizontalMargin
            ),
            closeButton.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: UX.horizontalMargin
            )
        ])
    }

    func setupDetails(website: String, display: String, icon: FaviconImageViewModel) {
        favicon.setFavicon(icon)
        siteDomainLabel.text = website
        siteDisplayTitleLabel.text = display
    }

    func setTitle(with text: String) {
        siteDisplayTitleLabel.text = text
    }

    func adjustLayout() {
        let faviconDynamicSize = min(UIFontMetrics.default.scaledValue(for: UX.faviconImageSize),
                                     2 * UX.faviconImageSize)
        faviconHeightConstraint?.constant = faviconDynamicSize
        faviconWidthConstraint?.constant = faviconDynamicSize

        let closeButtonDynamicSize = min(UIFontMetrics.default.scaledValue(for: UX.closeButtonSize),
                                         2 * UX.closeButtonSize)
        closeButton.updateLayoutForDynamicFont(newSize: closeButtonDynamicSize)
        closeButton.layer.cornerRadius = closeButtonDynamicSize * 0.5
    }

    func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }

    @objc
    func closeButtonTapped() {
        closeButtonCallback?()
    }

    func applyTheme(theme: Theme) {
        closeButton.backgroundColor = theme.colors.layer2
        let buttonImage = UIImage(named: StandardImageIdentifiers.Medium.cross)?
            .tinted(withColor: theme.colors.iconSecondary)
        closeButton.setImage(buttonImage, for: .normal)
        siteDomainLabel.textColor = theme.colors.textSecondary
        siteDisplayTitleLabel.textColor = theme.colors.textPrimary
        self.tintColor = theme.colors.layer2
    }
}
