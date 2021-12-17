// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

fileprivate struct LogoViewUX {
    static let imageHeight: CGFloat = 40
    static let imageWidth: CGFloat = 214.74
}

class FxHomeLogoHeaderCell: UICollectionViewCell, ReusableCell {
    typealias a11y = AccessibilityIdentifiers.FirefoxHomepage.OtherButtons

    // MARK: - UI Elements
    let logoButton: UIButton = .build { button in
        let resourceName = "fxHomeHeaderLogo"
        let imageString = LegacyThemeManager.instance.currentName == .dark ? resourceName + "_dark" : resourceName
        button.setImage(
            UIImage(imageLiteralResourceName: imageString),
            for: .normal)
        button.setTitle("", for: .normal)
        button.backgroundColor = .clear
        button.accessibilityIdentifier = a11y.logoButton
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
        contentView.addSubview(logoButton)

        NSLayoutConstraint.activate([
            logoButton.widthAnchor.constraint(equalToConstant: LogoViewUX.imageWidth),
            logoButton.heightAnchor.constraint(equalToConstant: LogoViewUX.imageHeight),
            logoButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            logoButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
}
