// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

class CustomizeHomepageSectionCell: BlurrableCollectionViewCell, ReusableCell {

    typealias a11y = AccessibilityIdentifiers.FirefoxHomepage.OtherButtons

    private struct UX {
        static let buttonFontSize: CGFloat = 15
        static let buttonTrailingSpace: CGFloat = 12
        static let buttonVerticalInset: CGFloat = 11
    }

    // MARK: - UI Elements
    private let goToSettingsButton: ActionButton = .build { button in
        button.setTitle(.FirefoxHomepage.CustomizeHomepage.ButtonTitle, for: .normal)
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .subheadline,
                                                                                    size: UX.buttonFontSize)
        button.layer.cornerRadius = 5
        button.accessibilityIdentifier = a11y.customizeHome
        button.contentEdgeInsets = UIEdgeInsets(top: UX.buttonVerticalInset,
                                                left: ResizableButton.UX.buttonEdgeSpacing,
                                                bottom: UX.buttonVerticalInset,
                                                right: ResizableButton.UX.buttonEdgeSpacing)
    }

    // MARK: - Variables
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        applyTheme()

        setupNotifications(forObserver: self,
                           observing: [.DisplayThemeChanged,
                                       .WallpaperDidChange])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: - UI Setup

    func setupView() {
        contentView.backgroundColor = .clear
        contentView.addSubview(goToSettingsButton)

        NSLayoutConstraint.activate([
            goToSettingsButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            goToSettingsButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            goToSettingsButton.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            goToSettingsButton.rightAnchor.constraint(equalTo: contentView.rightAnchor,
                                                      constant: -UX.buttonTrailingSpace)
        ])

        goToSettingsButton.setContentHuggingPriority(.required, for: .vertical)

        // needed so the button sizes correctly
        setNeedsLayout()
        layoutIfNeeded()
    }

    func configure(onTapAction: ((UIButton) -> Void)?) {
        goToSettingsButton.touchUpAction = onTapAction

        adjustLayout()
    }

    private func adjustLayout() {
        if shouldApplyWallpaperBlur {
            goToSettingsButton.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        } else {
            goToSettingsButton.removeVisualEffectView()
            applyTheme()
        }
    }
}

// MARK: - Theme
extension CustomizeHomepageSectionCell: NotificationThemeable {
    func applyTheme() {
        goToSettingsButton.backgroundColor = UIColor.theme.homePanel.customizeHomepageButtonBackground
        goToSettingsButton.setTitleColor(UIColor.theme.homePanel.customizeHomepageButtonText, for: .normal)
    }
}

// MARK: - Notifiable
extension CustomizeHomepageSectionCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        ensureMainThread { [weak self] in
            switch notification.name {
            case .DisplayThemeChanged:
                self?.applyTheme()
            case .WallpaperDidChange:
                self?.adjustLayout()
            default: break
            }
        }
    }
}
