// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

class FxHomeCustomizeHomeView: UICollectionViewCell, ReusableCell {

    typealias a11y = AccessibilityIdentifiers.FirefoxHomepage.OtherButtons

    private struct UX {
        static let settingsButtonHeight: CGFloat = 36
        static let settingsButtonTopAnchorSpace: CGFloat = 28
        static let settingsButtonMaxFontSize: CGFloat = 49
    }

    // MARK: - UI Elements
    let goToSettingsButton: UIButton = .build { button in
        button.setTitle(.FirefoxHomepage.CustomizeHomepage.ButtonTitle, for: .normal)
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .subheadline,
                                                                                    maxSize: UX.settingsButtonMaxFontSize)
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
            goToSettingsButton.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.settingsButtonHeight),
            goToSettingsButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.settingsButtonTopAnchorSpace),
            goToSettingsButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -FirefoxHomeViewModel.UX.spacingBetweenSections),
            goToSettingsButton.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
            goToSettingsButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16)
        ])
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
