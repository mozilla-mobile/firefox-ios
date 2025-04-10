// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit
import Shared
import SiteImageView

/// Tab cell used in the tab tray under the .tabTrayUIExperiments Nimbus experiment
class ExperimentTabCell: UICollectionViewCell, ThemeApplicable, ReusableCell {
    struct UX {
        static let selectedBorderWidth: CGFloat = 3.0
        static let unselectedBorderWidth: CGFloat = 1
        static let cornerRadius: CGFloat = 16
        static let subviewDefaultPadding: CGFloat = 6.0
        static let faviconSize = CGSize(width: 16, height: 16)
        static let fallbackFaviconSize = CGSize(width: 24, height: 24)
        static let closeButtonSize: CGFloat = 32
        static let textBoxHeight: CGFloat = 32
        static let closeButtonEdgeInset = NSDirectionalEdgeInsets(top: 12,
                                                                  leading: 12,
                                                                  bottom: 12,
                                                                  trailing: 12)
        static let closeButtonTop: CGFloat = 6
        static let closeButtonTrailing: CGFloat = 8
        static let closeButtonOverlaySpacing: CGFloat = 16
        static let tabViewFooterSpacing: CGFloat = 4
        static let shadowRadius: CGFloat = 4
        static let shadowOffset = CGSize(width: 0, height: 2)
        static let shadowOpacity: Float = 1
        static let thumbnailScreenshotHeight: CGFloat = 200
    }
    // MARK: - Properties

    private(set) var tabModel: TabModel?

    var isSelectedTab: Bool { return tabModel?.isSelected ?? false }
    var animator: SwipeAnimator?
    weak var delegate: TabCellDelegate?

    private lazy var smallFaviconView: FaviconImageView = .build { view in
        view.isHidden = true
    }

    private lazy var favicon: FaviconImageView = .build()
    private lazy var faviconContainer: UIView = .build()

    // MARK: - UI

    // Contains the title and the favicon under the tab screenshot view
    private lazy var footerView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = UX.tabViewFooterSpacing
        stackView.backgroundColor = .clear
        stackView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        stackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
    }

    lazy var backgroundHolder: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
        view.layer.borderWidth = UX.unselectedBorderWidth
        view.clipsToBounds = true
    }

    private lazy var screenshotView: UIImageView = .build { view in
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isAccessibilityElement = false
        view.accessibilityElementsHidden = true
    }

    private lazy var titleText: UILabel = .build { label in
        label.numberOfLines = 1
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.isAccessibilityElement = false
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
    }

    private lazy var closeButton: UIButton = .build { button in
        button.setImage(UIImage.templateImageNamed(ImageIdentifiers.badgeMask), for: [])
        button.imageView?.contentMode = .scaleAspectFit
        button.contentMode = .center
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = UX.closeButtonEdgeInset
        button.configuration = configuration
        button.alpha = 0.5
    }

    private lazy var closeButtonOverlay: UIImageView = .build { imageView in
        imageView.image = UIImage(named: StandardImageIdentifiers.Medium.cross)?.withRenderingMode(.alwaysTemplate)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        favicon.layer.cornerRadius = UX.faviconSize.height / 2
        smallFaviconView.layer.cornerRadius = UX.fallbackFaviconSize.height / 2

        backgroundHolder.layoutIfNeeded()
        contentView.layer.shadowPath = UIBezierPath(
            roundedRect: self.backgroundHolder.bounds,
            cornerRadius: self.backgroundHolder.layer.cornerRadius
        ).cgPath
    }

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        animator = SwipeAnimator(animatingView: self)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        layer.cornerRadius = UX.cornerRadius
        contentView.addSubview(backgroundHolder)
        contentView.addSubview(footerView)

        footerView.addArrangedSubview(faviconContainer)
        footerView.addArrangedSubview(titleText)
        faviconContainer.addSubview(favicon)

        backgroundHolder.addSubviews(screenshotView, smallFaviconView, closeButton, closeButtonOverlay)

        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: .TabTrayCloseAccessibilityCustomAction,
                                        target: animator,
                                        selector: #selector(SwipeAnimator.closeWithoutGesture))
        ]

        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not yet supported") }

    // MARK: - Configuration
    func configure(with tabModel: TabModel, theme: Theme?, delegate: TabCellDelegate, a11yId: String) {
        self.tabModel = tabModel
        self.delegate = delegate

        if let swipeAnimatorDelegate = delegate as? SwipeAnimatorDelegate {
            animator?.delegate = swipeAnimatorDelegate
        }

        animator?.animateBackToCenter()

        titleText.text = tabModel.tabTitle
        accessibilityLabel = getA11yTitleLabel(tabModel: tabModel)
        isAccessibilityElement = true
        accessibilityHint = .TabTraySwipeToCloseAccessibilityHint
        accessibilityIdentifier = a11yId

        let identifier = StandardImageIdentifiers.Large.globe
        if let globeFavicon = UIImage(named: identifier)?.withRenderingMode(.alwaysTemplate) {
            favicon.manuallySetImage(globeFavicon)
        }

        if !tabModel.isFxHomeTab, let tabURL = tabModel.url?.absoluteString {
            favicon.setFavicon(FaviconImageViewModel(siteURLString: tabURL))
        }

        updateUIForSelectedState(tabModel.isSelected,
                                 isPrivate: tabModel.isPrivate,
                                 theme: theme)

        configureScreenshot(tabModel: tabModel)

        if let theme {
            applyTheme(theme: theme)
        }
    }

    // MARK: - Actions

    @objc
    func close() {
        guard let tabModel = tabModel else { return }
        delegate?.tabCellDidClose(for: tabModel.tabUUID)
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        backgroundHolder.backgroundColor = theme.colors.layer1
        closeButton.tintColor = theme.colors.iconPrimary
        closeButtonOverlay.tintColor = theme.colors.textInverted
        titleText.textColor = theme.colors.textPrimary
        screenshotView.backgroundColor = theme.colors.layer1
        favicon.tintColor = theme.colors.textPrimary
        smallFaviconView.tintColor = theme.colors.textPrimary
        setupShadow(theme: theme)
    }

    func setupShadow(theme: Theme) {
        contentView.layer.shadowRadius = UX.shadowRadius
        contentView.layer.shadowOffset = UX.shadowOffset
        contentView.layer.shadowColor = theme.colors.shadowDefault.cgColor
        contentView.layer.shadowOpacity = UX.shadowOpacity
    }

    // MARK: - Configuration

    private func configureScreenshot(tabModel: TabModel) {
        if let url = tabModel.url,
           isInternal(url: url),
           tabModel.hasHomeScreenshot {
            // Regular screenshot for home or internal url when tab has home screenshot
            let defaultImage = UIImage(named: StandardImageIdentifiers.Large.globe)?
                .withRenderingMode(.alwaysTemplate)
            smallFaviconView.manuallySetImage(defaultImage ?? UIImage())
            screenshotView.image = tabModel.screenshot
        } else if let url = tabModel.url,
                  !isInternal(url: url),
                  tabModel.hasHomeScreenshot {
            // Favicon or letter image when home screenshot is present for a regular (non-internal) url
            let defaultImage = UIImage(
                named: StandardImageIdentifiers.Large.globe
            )?.withRenderingMode(.alwaysTemplate)
            smallFaviconView.manuallySetImage(defaultImage ?? UIImage())
            smallFaviconView.isHidden = false
            screenshotView.image = nil
        } else if let tabScreenshot = tabModel.screenshot {
            // Use Tab screenshot when available
            screenshotView.image = tabScreenshot
        } else {
            // Favicon or letter image when tab screenshot isn't available
            smallFaviconView.isHidden = false
            screenshotView.image = nil

            if let tabURL = tabModel.url?.absoluteString {
                smallFaviconView.setFavicon(FaviconImageViewModel(siteURLString: tabURL))
            }
        }
    }

    private func isInternal(url: URL) -> Bool {
        return url.absoluteString.starts(with: "internal")
    }

    private func updateUIForSelectedState(_ selected: Bool,
                                          isPrivate: Bool,
                                          theme: Theme?) {
        guard let theme = theme else { return }
        if selected {
            let borderColor = isPrivate ? theme.colors.borderAccentPrivate : theme.colors.borderAccent
            backgroundHolder.layer.borderColor = borderColor.cgColor
            backgroundHolder.layer.borderWidth = UX.selectedBorderWidth
        } else {
            backgroundHolder.layer.borderColor = theme.colors.borderPrimary.cgColor
            backgroundHolder.layer.borderWidth = UX.unselectedBorderWidth
        }
    }

    // MARK: - UICollectionViewCell

    override func prepareForReuse() {
        // Reset any close animations.
        super.prepareForReuse()
        screenshotView.image = nil
        smallFaviconView.isHidden = true
        layer.shadowOffset = .zero
        layer.shadowPath = nil
        layer.shadowOpacity = 0
        isHidden = false
    }

    // MARK: - Auto Layout

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundHolder.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundHolder.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundHolder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundHolder.heightAnchor.constraint(equalToConstant: UX.thumbnailScreenshotHeight),

            footerView.topAnchor.constraint(equalTo: backgroundHolder.bottomAnchor,
                                            constant: UX.tabViewFooterSpacing),
            footerView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
            footerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            footerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            footerView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),

            faviconContainer.topAnchor.constraint(lessThanOrEqualTo: favicon.topAnchor),
            faviconContainer.bottomAnchor.constraint(greaterThanOrEqualTo: favicon.bottomAnchor),
            faviconContainer.leadingAnchor.constraint(equalTo: favicon.leadingAnchor),
            faviconContainer.trailingAnchor.constraint(equalTo: favicon.trailingAnchor),
            favicon.heightAnchor.constraint(equalToConstant: UX.faviconSize.height),
            favicon.widthAnchor.constraint(equalToConstant: UX.faviconSize.width),
            favicon.centerYAnchor.constraint(equalTo: titleText.centerYAnchor),

            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.topAnchor.constraint(equalTo: backgroundHolder.topAnchor,
                                             constant: UX.closeButtonTop),
            closeButton.trailingAnchor.constraint(equalTo: backgroundHolder.trailingAnchor,
                                                  constant: -UX.closeButtonTrailing),

            // Screenshot either shown or favicon takes its place as fallback
            screenshotView.topAnchor.constraint(equalTo: backgroundHolder.topAnchor),
            screenshotView.leadingAnchor.constraint(equalTo: backgroundHolder.leadingAnchor),
            screenshotView.trailingAnchor.constraint(equalTo: backgroundHolder.trailingAnchor),
            screenshotView.bottomAnchor.constraint(equalTo: backgroundHolder.bottomAnchor),

            smallFaviconView.heightAnchor.constraint(equalToConstant: UX.fallbackFaviconSize.height),
            smallFaviconView.widthAnchor.constraint(equalToConstant: UX.fallbackFaviconSize.width),
            smallFaviconView.centerYAnchor.constraint(equalTo: backgroundHolder.centerYAnchor),
            smallFaviconView.centerXAnchor.constraint(equalTo: backgroundHolder.centerXAnchor),

            closeButtonOverlay.centerXAnchor.constraint(equalTo: closeButton.centerXAnchor),
            closeButtonOverlay.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            closeButtonOverlay.widthAnchor.constraint(equalTo: closeButton.widthAnchor,
                                                      constant: -UX.closeButtonOverlaySpacing),
            closeButtonOverlay.heightAnchor.constraint(equalTo: closeButton.heightAnchor,
                                                       constant: -UX.closeButtonOverlaySpacing)
        ])
    }

    // MARK: - Accessibility

    override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        var right: Bool
        switch direction {
        case .left:
            right = false
        case .right:
            right = true
        default:
            return false
        }
        animator?.close(right: right)
        return true
    }

    private func getA11yTitleLabel(tabModel: TabModel) -> String? {
        let baseName = tabModel.tabTitle

        if isSelectedTab, !baseName.isEmpty {
            return baseName + ". " + String.TabTrayCurrentlySelectedTabAccessibilityLabel
        } else if isSelectedTab {
            return String.TabTrayCurrentlySelectedTabAccessibilityLabel
        } else {
            return baseName
        }
    }
}
