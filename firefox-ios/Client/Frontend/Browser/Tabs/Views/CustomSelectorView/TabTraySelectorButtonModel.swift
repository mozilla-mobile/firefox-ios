// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

struct TabTraySelectorButtonModel {
    let title: String
    let a11yIdentifier: String
    let a11yHint: String
    let font: UIFont
    let contentInsets: NSDirectionalEdgeInsets
    let cornerRadius: CGFloat
}

final class TabTraySelectorButton: UIButton, ThemeApplicable {
    private var foregroundColorNormal: UIColor = .clear
    private var foregroundColorHighlighted: UIColor = .clear
    private var backgroundColorNormal: UIColor = .clear

    override init(frame: CGRect) {
        super.init(frame: frame)

        configuration = UIButton.Configuration.plain()
        titleLabel?.adjustsFontForContentSizeCategory = false
        showsLargeContentViewer = true
        addInteraction(UILargeContentViewerInteraction())
    }

    func configure(viewModel: TabTraySelectorButtonModel) {
        guard let config = configuration else {
            return
        }
        var updatedConfiguration = config

        updatedConfiguration.titleLineBreakMode = .byTruncatingTail
        updatedConfiguration.title = viewModel.title
        updatedConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = viewModel.font
            return outgoing
        }
        updatedConfiguration.contentInsets = viewModel.contentInsets
        layer.cornerRadius = viewModel.cornerRadius

        accessibilityIdentifier = viewModel.a11yIdentifier
        accessibilityHint = viewModel.a11yHint

        configuration = updatedConfiguration
        layoutIfNeeded()
    }

    /// The `TabTraySelectorButton` font is adjusted whenever it is selected
    /// - Parameter font: the new font to apply on the button
    func applySelectedFontChange(font: UIFont) {
        guard let config = configuration else { return }
        var updatedConfiguration = config
        updatedConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = font
            return outgoing
        }
        configuration = updatedConfiguration
        layoutIfNeeded()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConfiguration() {
        guard var updatedConfiguration = configuration else {
            return
        }

        switch state {
        case [.highlighted]:
            updatedConfiguration.baseForegroundColor = foregroundColorHighlighted
        default:
            updatedConfiguration.baseForegroundColor = foregroundColorNormal
        }

        updatedConfiguration.background.backgroundColor = backgroundColorNormal
        configuration = updatedConfiguration
    }

    // MARK: ThemeApplicable

    func applyTheme(theme: Theme) {
        foregroundColorNormal = theme.colors.textPrimary
        foregroundColorHighlighted = theme.colors.actionSecondaryHover
        backgroundColorNormal = .clear
        setNeedsUpdateConfiguration()
    }
}
