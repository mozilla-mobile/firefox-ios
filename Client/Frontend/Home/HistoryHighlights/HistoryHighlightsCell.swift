// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import SiteImageView
import Shared

/// A cell used in FxHomeScreen's History Highlights section.
class HistoryHighlightsCell: UICollectionViewCell, ReusableCell {
    struct UX {
        static let verticalSpacing: CGFloat = 20
        static let horizontalSpacing: CGFloat = 16
        static let heroImageDimension: CGFloat = 24
    }

    // MARK: - UI Elements
    let imageView: FaviconImageView = .build { imageView in }

    let itemTitle: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                            size: 15)
        label.adjustsFontForContentSizeCategory = true
    }

    let itemDescription: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .caption1,
                                                            size: 12)
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var textStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [itemTitle, itemDescription])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.distribution = .fillProportionally
        stack.axis = .vertical
        stack.alignment = .leading

        return stack
    }()

    let bottomLine: UIView = .build { line in
        line.isHidden = false
    }

    var isFillerCell = false {
        didSet {
            itemTitle.isHidden = isFillerCell
            imageView.isHidden = isFillerCell
            bottomLine.isHidden = isFillerCell
        }
    }

    // MARK: - Variables
    private var cellModel: HistoryHighlightsModel?

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: .zero)

        isAccessibilityElement = true
        accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.HistoryHighlights.itemCell

        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public methods
    func configureCell(with options: HistoryHighlightsModel, theme: Theme) {
        cellModel = options
        itemTitle.text = !options.title.isEmpty ? options.title : options.urlString

        if let descriptionCount = options.description {
            itemDescription.text = descriptionCount
            itemDescription.isHidden = false
        }

        bottomLine.alpha = options.hideBottomLine ? 0 : 1
        isFillerCell = options.isFillerCell
        accessibilityLabel = options.accessibilityLabel

        if let url = options.urlString {
            let faviconViewModel = FaviconImageViewModel(siteURLString: url)
            imageView.setFavicon(faviconViewModel)
        } else {
            imageView.image = UIImage.templateImageNamed(StandardImageIdentifiers.Large.tabTray)
        }

        applyTheme(theme: theme)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageView.image = nil
        itemDescription.isHidden = true

        contentView.layer.shadowRadius = 0.0
        contentView.layer.shadowOpacity = 0.0
        contentView.layer.shadowPath = nil
    }

    // MARK: - Setup Helper methods
    private func setupLayout() {
        contentView.addSubview(imageView)
        contentView.addSubview(textStack)
        contentView.addSubview(bottomLine)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                               constant: UX.horizontalSpacing),
            imageView.heightAnchor.constraint(equalToConstant: UX.heroImageDimension),
            imageView.widthAnchor.constraint(equalToConstant: UX.heroImageDimension),
            imageView.centerYAnchor.constraint(equalTo: textStack.centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: imageView.trailingAnchor,
                                               constant: UX.horizontalSpacing),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                constant: -UX.horizontalSpacing),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            bottomLine.heightAnchor.constraint(equalToConstant: 0.5),
            bottomLine.leadingAnchor.constraint(equalTo: itemTitle.leadingAnchor),
            bottomLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                 constant: -UX.horizontalSpacing),
            bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func setupShadow(_ shouldAddShadow: Bool,
                             cornersToRound: CACornerMask?,
                             theme: Theme) {
        contentView.layer.maskedCorners = cornersToRound ?? .layerMaxXMinYCorner
        contentView.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius

        var needsShadow = shouldAddShadow
        if let cornersToRound = cornersToRound {
            needsShadow = cornersToRound.contains(.layerMinXMaxYCorner) ||
                cornersToRound.contains(.layerMaxXMaxYCorner) ||
                shouldAddShadow
        }

        if needsShadow {
            let size: CGFloat = 5
            let distance: CGFloat = 0
            let rect = CGRect(
                x: -size,
                y: contentView.frame.height - (size * 0.4) + distance,
                width: contentView.frame.width + size * 2,
                height: size
            )

            contentView.layer.shadowColor = theme.colors.shadowDefault.cgColor
            contentView.layer.shadowRadius = HomepageViewModel.UX.shadowRadius
            contentView.layer.shadowOpacity = HomepageViewModel.UX.shadowOpacity
            contentView.layer.shadowOffset = HomepageViewModel.UX.shadowOffset
            contentView.layer.shadowPath = UIBezierPath(ovalIn: rect).cgPath
        }
    }
}

// MARK: - ThemeApplicable
extension HistoryHighlightsCell: ThemeApplicable {
    func applyTheme(theme: Theme) {
        imageView.tintColor = theme.colors.iconPrimary
        bottomLine.backgroundColor = theme.colors.borderPrimary
        itemTitle.textColor = theme.colors.textPrimary
        itemDescription.textColor = theme.colors.textSecondary

        adjustBlur(theme: theme)
    }
}

// MARK: - Blurrable
extension HistoryHighlightsCell: Blurrable {
    func adjustBlur(theme: Theme) {
        // If blur is disabled set background color
        if shouldApplyWallpaperBlur {
            contentView.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
            contentView.backgroundColor = .clear
            contentView.layer.maskedCorners = cellModel?.corners ?? .layerMaxXMinYCorner
            contentView.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
        } else {
            contentView.removeVisualEffectView()
            contentView.backgroundColor = theme.colors.layer5
            setupShadow(cellModel?.shouldAddShadow ?? false,
                        cornersToRound: cellModel?.corners,
                        theme: theme)
        }
    }
}
