// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

fileprivate struct LogoViewUX {
    static let imageHeight: CGFloat = 36
    static let imageWidth: CGFloat = 28
}

class FxHomeLogoHeaderCell: UICollectionViewCell, ReusableCell {

    // MARK: - UI Elements
    let logoButton: UIButton = .build { button in
        button.setImage(
            UIImage(imageLiteralResourceName: "fxHomeHeaderLogo"),
            for: .normal)
        button.setTitle("", for: .normal)
        button.backgroundColor = .clear
        button.accessibilityIdentifier = "FxHomeCustomizeHomeSettingButton"
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
        contentView.addSubview(logoButton)

        NSLayoutConstraint.activate([
            logoButton.widthAnchor.constraint(equalToConstant: LogoViewUX.imageWidth),
            logoButton.heightAnchor.constraint(equalToConstant: LogoViewUX.imageHeight),
            logoButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            logoButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
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

extension FxHomeLogoHeaderCell: NotificationThemeable {
    func applyTheme() {
    }
}
