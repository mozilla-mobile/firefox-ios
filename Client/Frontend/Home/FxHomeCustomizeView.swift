/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

fileprivate struct HomeViewUX {
    static let settingsButtonHeight: CGFloat = 36
    static let settingsButtonWidth: CGFloat = 328
    static let settingsButtonTopAnchorSpace: CGFloat = 28
}

class FxHomeCustomizeHomeView: UICollectionViewCell {

    // MARK: - UI Elements
    let goToSettingsButton: UIButton = .build { button in
        button.setTitle(.FirefoxHomeCustomizeHomeButtonTitle, for: .normal)
        button.backgroundColor = UIColor.Photon.LightGrey30
        button.setTitleColor(UIColor.Photon.DarkGrey90, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        button.layer.cornerRadius = 5
        button.accessibilityIdentifier = "FxHomeCustomizeHomeSettingButton"
    }

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    func setupView() {
        contentView.backgroundColor = .clear
        contentView.addSubview(goToSettingsButton)

        NSLayoutConstraint.activate([
            goToSettingsButton.widthAnchor.constraint(equalToConstant: HomeViewUX.settingsButtonWidth),
            goToSettingsButton.heightAnchor.constraint(equalToConstant: HomeViewUX.settingsButtonHeight),
            goToSettingsButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: HomeViewUX.settingsButtonTopAnchorSpace),
            goToSettingsButton.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
}

