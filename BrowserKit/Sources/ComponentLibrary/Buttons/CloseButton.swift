// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public class CloseButton: UIButton, ThemeApplicable {
    private var viewModel: CloseButtonViewModel?

    var buttonSize: CGSize { UX.closeButtonSize }

    private struct UX {
        static let closeButtonSize = CGSize(width: 44, height: 44)
        static let legacyCrossCircleImage = StandardImageIdentifiers.ExtraLarge.crossCircleFill
        static let glassCrossImage = StandardImageIdentifiers.Large.cross
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        adjustsImageSizeForAccessibilityContentSizeCategory = true
        setupConstraints()

        if #available(iOS 26.0, *) {
            var glassConfiguration = UIButton.Configuration.glass()
            glassConfiguration.image = UIImage(named: UX.glassCrossImage)?.withRenderingMode(.alwaysTemplate)
            configuration = glassConfiguration
        } else {
            setImage(UIImage(named: UX.legacyCrossCircleImage), for: .normal)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: UX.closeButtonSize.height),
            widthAnchor.constraint(equalToConstant: UX.closeButtonSize.width)
        ])
    }

    public func configure(viewModel: CloseButtonViewModel) {
        self.viewModel = viewModel
        accessibilityIdentifier = viewModel.a11yIdentifier
        accessibilityLabel = viewModel.a11yLabel
    }

    // MARK: - ThemeApplicable

    public func applyTheme(theme: Theme) {
        let tintColor = theme.colors.iconSecondary
        self.tintColor = tintColor
        if #available(iOS 26.0, *) {
            configuration?.baseForegroundColor = tintColor
        }
    }
}
