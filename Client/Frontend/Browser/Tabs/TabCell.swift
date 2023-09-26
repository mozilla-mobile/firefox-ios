// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit
import Shared
import SiteImageView

private struct TabCellUILayout {
    static let borderWidth: CGFloat = 3.0
}

protocol TabCellDelegate: AnyObject {
    func tabCellDidClose(_ cell: TabCell)
}

/// WIP. Brings over much of the existing functionality from LegacyTabCell but has been
/// updated to avoid capturing state within the cell itself, instead consuming and returning
/// read-only state from our Redux app state (and more specifically `TabCellState`).
class TabCell: UICollectionViewCell, ThemeApplicable, ReusableCell {
    // MARK: - Properties

    private(set) var state = TabCellState.emptyTabState()

    var isSelectedTab: Bool { return state.isSelected }
    var animator: SwipeAnimator?
    weak var delegate: TabCellDelegate?

    private lazy var smallFaviconView: FaviconImageView = .build()
    private lazy var favicon: FaviconImageView = .build()
    private var title =
        UIVisualEffectView(effect: UIBlurEffect(style: UIColor.legacyTheme.tabTray.tabTitleBlur))

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.animator = SwipeAnimator(animatingView: self)
        self.closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        contentView.addSubview(backgroundHolder)

        faviconBG.addSubview(smallFaviconView)
        backgroundHolder.addSubviews(screenshotView, faviconBG)

        self.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: .TabTrayCloseAccessibilityCustomAction,
                                        target: self.animator,
                                        selector: #selector(SwipeAnimator.closeWithoutGesture))
        ]

        backgroundHolder.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.contentView.addSubview(self.closeButton)
        title.contentView.addSubview(self.titleText)
        title.contentView.addSubview(self.favicon)

        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not yet supported") }

    // MARK: - Configuration

    func configure(with state: TabCellState, theme: Theme?) {
        self.state = state

        titleText.text = state.tabTitle
        accessibilityLabel = getA11yTitleLabel(state: state)
        isAccessibilityElement = true
        accessibilityHint = .TabTraySwipeToCloseAccessibilityHint

        favicon.image = UIImage(named: StandardImageIdentifiers.Large.globe)?
            .withRenderingMode(.alwaysTemplate)

        if !state.isFxHomeTab, let tabURL = state.url?.absoluteString {
            favicon.setFavicon(FaviconImageViewModel(siteURLString: tabURL))
        }

        updateUIForSelectedState(state.isSelected,
                                 isPrivate: state.isPrivate,
                                 theme: theme)

        faviconBG.isHidden = true
        configureScreenshot(state: state)

        if let theme = theme {
            applyTheme(theme: theme)
        }
    }

    // MARK: - Actions

    @objc
    func close() {
        delegate?.tabCellDidClose(self)
    }

    // MARK: - UI

    func applyTheme(theme: Theme) {
        backgroundHolder.backgroundColor = theme.colors.layer1
        closeButton.tintColor = theme.colors.indicatorActive
        titleText.textColor = theme.colors.textPrimary
        screenshotView.backgroundColor = theme.colors.layer1
        favicon.tintColor = theme.colors.textPrimary
        smallFaviconView.tintColor = theme.colors.textPrimary
    }

    private func configureScreenshot(state: TabCellState) {
        if let url = state.url,
           let tabScreenshot = state.screenshot,
           (url.absoluteString.starts(with: "internal") && state.hasHomeScreenshot) {
            // Regular screenshot for home or internal url when
            // tab has home screenshot
            let defaultImage = UIImage(named: StandardImageIdentifiers.Large.globe)?
                .withRenderingMode(.alwaysTemplate)
            smallFaviconView.manuallySetImage(defaultImage ?? UIImage())
            screenshotView.image = tabScreenshot
        } else if let url = state.url,
                  (!url.absoluteString.starts(with: "internal") && state.hasHomeScreenshot) {
            // Favicon or letter image when home screenshot is present for
            // a regular (non-internal) url

            let defaultImage = UIImage(named: StandardImageIdentifiers.Large.globe)?.withRenderingMode(.alwaysTemplate)
            smallFaviconView.manuallySetImage(defaultImage ?? UIImage())
            faviconBG.isHidden = false
            screenshotView.image = nil
        } else if let tabScreenshot = state.screenshot {
            // Tab screenshot when available
            screenshotView.image = tabScreenshot
        } else {
            // Favicon or letter image when tab screenshot isn't available
            faviconBG.isHidden = false
            screenshotView.image = nil

            if let tabURL = state.url?.absoluteString {
                smallFaviconView.setFavicon(FaviconImageViewModel(siteURLString: tabURL))
            }
        }
    }

    private func updateUIForSelectedState(_ selected: Bool,
                                          isPrivate: Bool,
                                          theme: Theme?) {
        guard let theme = theme else { return }
        if selected {
            layoutMargins = UIEdgeInsets(top: TabCellUILayout.borderWidth,
                                         left: TabCellUILayout.borderWidth,
                                         bottom: TabCellUILayout.borderWidth,
                                         right: TabCellUILayout.borderWidth)
            layer.borderColor = (isPrivate ? theme.colors.borderAccentPrivate : theme.colors.borderAccent).cgColor
            layer.borderWidth = TabCellUILayout.borderWidth
            layer.cornerRadius =
            LegacyGridTabViewController.UX.cornerRadius + TabCellUILayout.borderWidth
        } else {
            layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            layer.borderColor = UIColor.clear.cgColor
            layer.borderWidth = 0
            layer.cornerRadius =
            LegacyGridTabViewController.UX.cornerRadius + TabCellUILayout.borderWidth
        }
    }

    private lazy var backgroundHolder: UIView = .build { view in
        view.layer.cornerRadius =
        LegacyGridTabViewController.UX.cornerRadius + TabCellUILayout.borderWidth
        view.clipsToBounds = true
    }

    private lazy var faviconBG: UIView = .build { view in
        view.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
        view.layer.borderWidth = HomepageViewModel.UX.generalBorderWidth
        view.layer.shadowOffset = HomepageViewModel.UX.shadowOffset
        view.layer.shadowRadius = HomepageViewModel.UX.shadowRadius
    }

    private lazy var screenshotView: UIImageView = .build { view in
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
    }

    private lazy var titleText: UILabel = .build { label in
        label.isUserInteractionEnabled = false
        label.numberOfLines = 1
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: 12, weight: .semibold)
    }

    private lazy var closeButton: UIButton = .build { button in
        button.setImage(UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross), for: [])
        button.imageView?.contentMode = .scaleAspectFit
        button.contentMode = .center
        button.imageEdgeInsets = UIEdgeInsets(equalInset: LegacyGridTabViewController.UX.closeButtonEdgeInset)
    }

    // MARK: UICollectionViewCell

    override func prepareForReuse() {
        // Reset any close animations.
        super.prepareForReuse()
        screenshotView.image = nil
        backgroundHolder.transform = .identity
        backgroundHolder.alpha = 1
        self.titleText.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: 12, weight: .semibold)
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
            backgroundHolder.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            backgroundHolder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            title.topAnchor.constraint(equalTo: backgroundHolder.topAnchor),
            title.leftAnchor.constraint(equalTo: backgroundHolder.leftAnchor),
            title.rightAnchor.constraint(equalTo: backgroundHolder.rightAnchor),
            title.heightAnchor.constraint(equalToConstant: LegacyGridTabViewController.UX.textBoxHeight),

            favicon.leadingAnchor.constraint(equalTo: title.leadingAnchor, constant: 6),
            favicon.topAnchor.constraint(equalTo: title.topAnchor, constant: (LegacyGridTabViewController.UX.textBoxHeight - LegacyGridTabViewController.UX.faviconSize) / 2),
            favicon.heightAnchor.constraint(equalToConstant: LegacyGridTabViewController.UX.faviconSize),
            favicon.widthAnchor.constraint(equalToConstant: LegacyGridTabViewController.UX.faviconSize),

            closeButton.heightAnchor.constraint(equalToConstant: LegacyGridTabViewController.UX.closeButtonSize),
            closeButton.widthAnchor.constraint(equalToConstant: LegacyGridTabViewController.UX.closeButtonSize),
            closeButton.centerYAnchor.constraint(equalTo: title.contentView.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: title.trailingAnchor),

            titleText.leadingAnchor.constraint(equalTo: favicon.trailingAnchor, constant: 6),
            titleText.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: 6),
            titleText.centerYAnchor.constraint(equalTo: title.contentView.centerYAnchor),

            screenshotView.topAnchor.constraint(equalTo: topAnchor),
            screenshotView.leftAnchor.constraint(equalTo: backgroundHolder.leftAnchor),
            screenshotView.rightAnchor.constraint(equalTo: backgroundHolder.rightAnchor),
            screenshotView.bottomAnchor.constraint(equalTo: backgroundHolder.bottomAnchor),

            faviconBG.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 10),
            faviconBG.centerXAnchor.constraint(equalTo: centerXAnchor),
            faviconBG.heightAnchor.constraint(equalToConstant: TopSiteItemCell.UX.imageBackgroundSize.height),
            faviconBG.widthAnchor.constraint(equalToConstant: TopSiteItemCell.UX.imageBackgroundSize.width),

            smallFaviconView.heightAnchor.constraint(equalToConstant: TopSiteItemCell.UX.iconSize.height),
            smallFaviconView.widthAnchor.constraint(equalToConstant: TopSiteItemCell.UX.iconSize.width),
            smallFaviconView.centerYAnchor.constraint(equalTo: faviconBG.centerYAnchor),
            smallFaviconView.centerXAnchor.constraint(equalTo: faviconBG.centerXAnchor),
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
}

// MARK: - AX Extension

extension TabCell {
    func getA11yTitleLabel(state: TabCellState) -> String? {
        let baseName = state.tabTitle

        if isSelectedTab, !baseName.isEmpty {
            return baseName + ". " + String.TabTrayCurrentlySelectedTabAccessibilityLabel
        } else if isSelectedTab {
            return String.TabTrayCurrentlySelectedTabAccessibilityLabel
        } else {
            return baseName
        }
    }
}
