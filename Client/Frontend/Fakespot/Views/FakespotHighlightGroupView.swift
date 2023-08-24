// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

struct FakespotHighlightGroupViewModel {
    let highlightGroup: HighlightGroup

    let titleA11yId: String
    let imageA11yId: String
    let highlightsA11yId: String

    var title: String {
        highlightGroup.type.title
    }

    var image: String {
        highlightGroup.type.iconName
    }
}

class FakespotHighlightGroupView: UIView, ThemeApplicable {
    private struct UX {
        static let horizontalSpace: CGFloat = 8
        static let verticalSpace: CGFloat = 8
        static let imageSize = CGSize(width: 24, height: 24)
        static let titleFontSize: CGFloat = 15
        static let highlightFontSize: CGFloat = 13
    }

    private lazy var itemImageView: UIImageView = .build()

    private lazy var titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .headline,
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

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(viewModel: FakespotHighlightGroupViewModel) {
        titleLabel.text = viewModel.title
        titleLabel.accessibilityIdentifier = viewModel.titleA11yId
        itemImageView.image = UIImage(named: viewModel.image)?.withRenderingMode(.alwaysTemplate)
        itemImageView.accessibilityIdentifier = viewModel.imageA11yId

        updateHighlightLabel(viewModel.highlightGroup.reviews)
        highlightLabel.accessibilityIdentifier = viewModel.highlightsA11yId
    }

    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        itemImageView.tintColor = theme.colors.iconPrimary
        highlightLabel.textColor = theme.colors.textPrimary
    }

    func showPreview(_ showPreview: Bool) {
        highlightLabel.numberOfLines = showPreview ? 3 : 0
        highlightLabel.isShowingFade = showPreview
    }

    private func setupLayout() {
        addSubview(itemImageView)
        addSubview(titleLabel)
        addSubview(highlightLabel)

        NSLayoutConstraint.activate([
            itemImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            itemImageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            itemImageView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -UX.horizontalSpace),
            itemImageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            itemImageView.widthAnchor.constraint(equalToConstant: UX.imageSize.width),
            itemImageView.heightAnchor.constraint(equalToConstant: UX.imageSize.height),
            titleLabel.centerYAnchor.constraint(equalTo: itemImageView.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: highlightLabel.topAnchor, constant: -UX.verticalSpace),

            highlightLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
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
}
