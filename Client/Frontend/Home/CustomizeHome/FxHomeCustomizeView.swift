// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

class FxHomeCustomizeHomeView: UICollectionViewCell, ReusableCell {

    typealias a11y = AccessibilityIdentifiers.FirefoxHomepage.OtherButtons

    private struct UX {
        static let buttonHeight: CGFloat = 36
        static let buttonMaxFontSize: CGFloat = 49
        static let buttonTrailingSpace: CGFloat = 12
    }

    // MARK: - UI Elements
    private let goToSettingsButton: ActionButton = .build { button in
        button.setTitle(.FirefoxHomepage.CustomizeHomepage.ButtonTitle, for: .normal)
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .subheadline,
                                                                                    maxSize: UX.buttonMaxFontSize)
        button.makeDynamicHeightSupport()

        button.layer.cornerRadius = 5
        button.accessibilityIdentifier = a11y.customizeHome
    }

    // MARK: - Variables
    var notificationCenter: NotificationCenter = NotificationCenter.default

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        applyTheme()

        setupNotifications(forObserver: self,
                           observing: [.DisplayThemeChanged])
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
            goToSettingsButton.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.buttonHeight),
            goToSettingsButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            goToSettingsButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            goToSettingsButton.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            goToSettingsButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -UX.buttonTrailingSpace)
        ])
    }

    func configure(onTapAction: ((UIButton) -> Void)?) {
        goToSettingsButton.touchUpAction = onTapAction
    }
}

// MARK: - Theme
extension FxHomeCustomizeHomeView: NotificationThemeable {
    func applyTheme() {
        goToSettingsButton.backgroundColor = UIColor.theme.homePanel.customizeHomepageButtonBackground
        goToSettingsButton.setTitleColor(UIColor.theme.homePanel.customizeHomepageButtonText, for: .normal)
    }
}

// MARK: - Notifiable
extension FxHomeCustomizeHomeView: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default: break
        }
    }
}
