// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

fileprivate struct HomeViewUX {
    static let settingsButtonHeight: CGFloat = 36
    static let settingsButtonTopAnchorSpace: CGFloat = 28
}

class FxHomeCustomizeHomeView: UICollectionViewCell, ReusableCell {
    typealias a11y = AccessibilityIdentifiers.FirefoxHomepage.OtherButtons

    // MARK: - UI Elements
    let goToSettingsButton: UIButton = .build { button in
        button.setTitle(.FirefoxHomepage.CustomizeHomepage.ButtonTitle, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        button.layer.cornerRadius = 5
        button.accessibilityIdentifier = a11y.customizeHome
    }

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        applyTheme()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleNotifications(_:)),
                                               name: .DisplayThemeChanged,
                                               object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UI Setup
    func setupView() {
        contentView.backgroundColor = .clear
        contentView.addSubview(goToSettingsButton)

        NSLayoutConstraint.activate([
            goToSettingsButton.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            goToSettingsButton.heightAnchor.constraint(equalToConstant: HomeViewUX.settingsButtonHeight),
            goToSettingsButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: HomeViewUX.settingsButtonTopAnchorSpace),
            goToSettingsButton.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
    
    // MARK: - Notifications
    
    @objc private func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default: break
        }
    }
}

extension FxHomeCustomizeHomeView: NotificationThemeable {
    func applyTheme() {
        goToSettingsButton.backgroundColor = UIColor.theme.homePanel.customizeHomepageButtonBackground
        goToSettingsButton.setTitleColor(UIColor.theme.homePanel.customizeHomepageButtonText, for: .normal)
    }
}
