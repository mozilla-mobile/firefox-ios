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
        static let fallbackFaviconSize = CGSize(width: 24, height: 24)
        static let closeButtonSize: CGFloat = 24
        static let closeButtonHitTarget: CGFloat = 44
        static let textBoxHeight: CGFloat = 32
        static let closeButtonTop: CGFloat = 6
        static let closeButtonTrailing: CGFloat = 8
        static let closeButtonOverlaySpacing: CGFloat = 6
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

    // MARK: - UI
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

    /// Invisible button without corner radius to ensure the button has the required hitbox size
    private lazy var closeButton: UIButton = .build { button in
        button.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.closeButton
    }

    /// Contains the blur background for the X icon
    private lazy var closeButtonBlurView: UIView = .build { view in
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
    }

    /// Contains the cross image for the close button
    private lazy var closeButtonImageOverlay: UIImageView = .build { imageView in
        imageView.image = UIImage(named: StandardImageIdentifiers.Medium.cross)?.withRenderingMode(.alwaysTemplate)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        smallFaviconView.layer.cornerRadius = UX.fallbackFaviconSize.height / 2

        backgroundHolder.layoutIfNeeded()
        contentView.layer.shadowPath = UIBezierPath(
            roundedRect: self.backgroundHolder.bounds,
            cornerRadius: self.backgroundHolder.layer.cornerRadius
        ).cgPath

        closeButtonBlurView.addBlurEffectWithClearBackgroundAndClipping(using: .systemUltraThinMaterialDark)
        closeButtonBlurView.layer.cornerRadius = closeButtonBlurView.frame.height / 2
    }

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        animator = SwipeAnimator(animatingView: self)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        layer.cornerRadius = UX.cornerRadius
        contentView.addSubview(backgroundHolder)

        backgroundHolder.addSubviews(screenshotView,
                                     smallFaviconView,
                                     closeButton,
                                     closeButtonBlurView,
                                     closeButtonImageOverlay)

        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: .TabsTray.TabTrayCloseAccessibilityCustomAction,
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

        accessibilityLabel = getA11yTitleLabel(tabModel: tabModel)
        isAccessibilityElement = true
        accessibilityHint = .TabsTray.TabTraySwipeToCloseAccessibilityHint
        accessibilityIdentifier = a11yId

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
        closeButtonImageOverlay.tintColor = theme.colors.textOnDark
        screenshotView.backgroundColor = theme.colors.layer1
        smallFaviconView.tintColor = theme.colors.textPrimary
        setupShadow(theme: theme)

        if UIAccessibility.isReduceTransparencyEnabled {
            closeButtonBlurView.backgroundColor = theme.colors.iconSecondary
        } else {
            closeButtonBlurView.backgroundColor = .clear
            closeButtonBlurView.addBlurEffectWithClearBackgroundAndClipping(using: .systemUltraThinMaterialDark)
        }

        guard let tabModel else { return }
        updateUIForSelectedState(tabModel.isSelected,
                                 isPrivate: tabModel.isPrivate,
                                 theme: theme)
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
        closeButton.removeVisualEffectView()
    }

    // MARK: - Auto Layout

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundHolder.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundHolder.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundHolder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundHolder.heightAnchor.constraint(equalToConstant: UX.thumbnailScreenshotHeight),
            backgroundHolder.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonHitTarget),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonHitTarget),
            closeButton.centerXAnchor.constraint(equalTo: closeButtonBlurView.centerXAnchor),
            closeButton.centerYAnchor.constraint(equalTo: closeButtonBlurView.centerYAnchor),

            closeButtonBlurView.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButtonBlurView.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButtonBlurView.topAnchor.constraint(equalTo: backgroundHolder.topAnchor,
                                                     constant: UX.closeButtonTop),
            closeButtonBlurView.trailingAnchor.constraint(equalTo: backgroundHolder.trailingAnchor,
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

            closeButtonImageOverlay.centerXAnchor.constraint(equalTo: closeButtonBlurView.centerXAnchor),
            closeButtonImageOverlay.centerYAnchor.constraint(equalTo: closeButtonBlurView.centerYAnchor),
            closeButtonImageOverlay.widthAnchor.constraint(equalTo: closeButtonBlurView.widthAnchor,
                                                           constant: -UX.closeButtonOverlaySpacing),
            closeButtonImageOverlay.heightAnchor.constraint(equalTo: closeButtonBlurView.heightAnchor,
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
            return baseName + ". " + String.TabsTray.TabTrayCurrentlySelectedTabAccessibilityLabel
        } else if isSelectedTab {
            return String.TabsTray.TabTrayCurrentlySelectedTabAccessibilityLabel
        } else {
            return baseName
        }
    }
}
