// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

struct FakespotHighlightGroupViewModel {
    let highlightGroup: FakespotHighlightGroup
}

class FakespotHighlightGroupView: UIView, ThemeApplicable, Notifiable {
    private struct UX {
        static let horizontalSpace: CGFloat = 8
        static let verticalSpace: CGFloat = 8
        static let imageSize: CGFloat = 24
        static let imageMaxSize: CGFloat = 58
        static let titleFontSize: CGFloat = 15
        static let highlightFontSize: CGFloat = 13
    }

    private lazy var itemImageView: UIImageView = .build()

    private lazy var titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .subheadline,
            size: UX.titleFontSize,
            weight: .semibold)
        label.numberOfLines = 0
    }

    private lazy var highlightLabel: FakespotFadeLabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .body,
            size: UX.highlightFontSize)
        label.numberOfLines = 0
        label.lineBreakMode = .byClipping
    }

    private var highlightLabelLeadingConstraint: NSLayoutConstraint?
    private var imageHeightConstraint: NSLayoutConstraint?

    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(viewModel: FakespotHighlightGroupViewModel) {
        titleLabel.text = viewModel.highlightGroup.type.title
        titleLabel.accessibilityIdentifier = viewModel.highlightGroup.type.titleA11yId
        itemImageView.image = UIImage(named: viewModel.highlightGroup.type.iconName)?.withRenderingMode(.alwaysTemplate)
        itemImageView.accessibilityIdentifier = viewModel.highlightGroup.type.iconA11yId

        updateHighlightLabel(viewModel.highlightGroup.reviews)
        highlightLabel.accessibilityIdentifier = viewModel.highlightGroup.type.highlightsA11yId
    }

    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        itemImageView.tintColor = theme.colors.iconPrimary
        highlightLabel.textColor = theme.colors.textPrimary
    }

    func showPreview(_ showPreview: Bool) {
        highlightLabel.numberOfLines = showPreview ? 2 : 0
        highlightLabel.isShowingFade = showPreview
    }

    private func setupLayout() {
        addSubview(itemImageView)
        addSubview(titleLabel)
        addSubview(highlightLabel)

        highlightLabelLeadingConstraint = highlightLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor)
        highlightLabelLeadingConstraint?.isActive = true

        let size = min(UIFontMetrics.default.scaledValue(for: UX.imageSize), UX.imageMaxSize)
        imageHeightConstraint = itemImageView.heightAnchor.constraint(equalToConstant: size)
        imageHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            itemImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            itemImageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            itemImageView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -UX.horizontalSpace),
            itemImageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            itemImageView.widthAnchor.constraint(equalTo: itemImageView.heightAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: itemImageView.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: highlightLabel.topAnchor, constant: -UX.verticalSpace),

            highlightLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            highlightLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func updateHighlightLabel(_ highlights: [String]) {
        let highlightText = "\"\(highlights.joined(separator: "\"\n\""))\""

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 8
        paragraphStyle.lineHeightMultiple = 1.16

        let attributedString = NSMutableAttributedString(string: highlightText)
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle,
                                      value: paragraphStyle,
                                      range: NSRange(location: 0, length: attributedString.length))
        highlightLabel.attributedText = attributedString
    }

    private func adjustLayout() {
        let isA11ySize = UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
        highlightLabelLeadingConstraint?.constant = isA11ySize ? -UX.horizontalSpace : 0
        imageHeightConstraint?.constant = min(UIFontMetrics.default.scaledValue(for: UX.imageSize), UX.imageMaxSize)
        setNeedsLayout()
        layoutIfNeeded()
    }

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            adjustLayout()
        default: break
        }
    }
}
