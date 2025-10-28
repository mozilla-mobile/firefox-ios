// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class NTPCustomizationCell: UICollectionViewCell, ThemeApplicable, ReusableCell {
    struct UX {
        static let buttonHeight: CGFloat = 40
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 12
        static let imageTitlePadding: CGFloat = 4
    }

    weak var delegate: NTPCustomizationCellDelegate?

    private lazy var button: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(.localized(.customizeHomepage), for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.setImage(.init(named: StandardImageIdentifiers.Large.settings)?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage(.init(named: StandardImageIdentifiers.Large.settings)?.withRenderingMode(.alwaysTemplate), for: .highlighted)
        button.imageView?.contentMode = .scaleAspectFit
        button.setInsets(forContentPadding: .init(top: UX.verticalInset, left: UX.horizontalInset, bottom: UX.verticalInset, right: UX.horizontalInset),
                         imageTitlePadding: UX.imageTitlePadding)
        button.addTarget(self, action: #selector(touchButtonAction), for: .touchUpInside)
        button.clipsToBounds = true
        return button
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        button.layer.cornerRadius = button.frame.height/2
    }

    private func setup() {
        isAccessibilityElement = true
        accessibilityIdentifier = "customize_homepage"

        contentView.addSubview(button)

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: UX.buttonHeight),
            button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func applyTheme(theme: Theme) {
        button.imageView?.tintColor = theme.colors.ecosia.buttonContentSecondary
        button.setTitleColor(theme.colors.ecosia.buttonContentSecondary, for: .normal)
        button.setBackgroundColor(theme.colors.ecosia.buttonBackgroundSecondary, forState: .normal)
        button.setBackgroundColor(theme.colors.ecosia.buttonBackgroundSecondaryActive, forState: .highlighted)
    }

    @objc func touchButtonAction() {
        delegate?.openNTPCustomizationSettings()
    }
}
