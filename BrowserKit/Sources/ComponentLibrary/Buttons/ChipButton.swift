// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// `ChipButton` is a capsule-style button used in chip pickers
public final class ChipButton: UIButton, ThemeApplicable {
    private struct UX {
        static let verticalInset: CGFloat = 8
        static let horizontalInset: CGFloat = 12
    }

    private var viewModel: ChipButtonViewModel?

    private var normalBackgroundColor: UIColor = .clear
    private var normalForegroundColor: UIColor = .clear
    private var selectedBackgroundColor: UIColor = .clear
    private var selectedForegroundColor: UIColor = .clear
    private var disabledBackgroundColor: UIColor = .clear
    private var disabledForegroundColor: UIColor = .clear

    // Some pinned collection view headers use a system backdrop that can be visually disturbed
    // by UIKit text in scrolling chips, so this mode draws title text in a layer.
    private let titleTextLayer = CATextLayer()

    override public init(frame: CGRect) {
        super.init(frame: frame)

        configuration = UIButton.Configuration.filled()
        configuration?.cornerStyle = .capsule
        configuration?.background.backgroundColorTransformer = nil
        configuration?.titleLineBreakMode = .byTruncatingTail
        layer.masksToBounds = false
        titleTextLayer.contentsScale = UIScreen.main.scale
        titleTextLayer.alignmentMode = .center
        titleTextLayer.truncationMode = .end
        titleTextLayer.actions = [
            "bounds": NSNull(),
            "position": NSNull(),
            "contents": NSNull()
        ]
        layer.addSublayer(titleTextLayer)

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public var intrinsicContentSize: CGSize {
        guard let title = viewModel?.title, !title.isEmpty else {
            return super.intrinsicContentSize
        }

        // Reserve space for the wider selected/unselected title so the chip
        // does not resize when its font weight changes with selection.
        let regularFont = FXFontStyles.Regular.body.scaledFont()
        let boldFont = FXFontStyles.Bold.body.scaledFont()
        let regularWidth = title.size(withAttributes: [.font: regularFont]).width
        let boldWidth = title.size(withAttributes: [.font: boldFont]).width
        let reservedTextWidth = ceil(max(regularWidth, boldWidth))
        let reservedTextHeight = ceil(max(regularFont.lineHeight, boldFont.lineHeight))

        return CGSize(
            width: reservedTextWidth + UX.horizontalInset * 2,
            height: reservedTextHeight + UX.verticalInset * 2
        )
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.height / 2).cgPath
        performWithoutLayerAnimation {
            titleTextLayer.frame = bounds.insetBy(dx: UX.horizontalInset, dy: UX.verticalInset)
        }
    }

    override public func updateConfiguration() {
        guard var updatedConfiguration = configuration else { return }

        let foregroundColor: UIColor
        let backgroundColor: UIColor
        let font: UIFont

        if !isEnabled {
            foregroundColor = disabledForegroundColor
            backgroundColor = disabledBackgroundColor
            font = FXFontStyles.Regular.body.scaledFont()
        } else if isSelected {
            foregroundColor = selectedForegroundColor
            backgroundColor = selectedBackgroundColor
            font = FXFontStyles.Bold.body.scaledFont()
        } else {
            foregroundColor = normalForegroundColor
            backgroundColor = normalBackgroundColor
            font = FXFontStyles.Regular.body.scaledFont()
        }

        updatedConfiguration.background.backgroundColor = backgroundColor
        if viewModel?.titleRendering == .coreAnimationLayer {
            updateTitleTextLayer(font: font, foregroundColor: foregroundColor)
        } else {
            updatedConfiguration.baseForegroundColor = foregroundColor
            updatedConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = font
                outgoing.foregroundColor = foregroundColor
                return outgoing
            }
        }

        configuration = updatedConfiguration
        layer.shadowOpacity = isEnabled ? FxShadow.shadow200.opacity : 0

        if !isEnabled {
            accessibilityTraits = [.button, .notEnabled]
        } else if isSelected {
            accessibilityTraits = [.button, .selected]
        } else {
            accessibilityTraits = [.button]
        }
    }

    public func configure(viewModel: ChipButtonViewModel) {
        self.viewModel = viewModel
        accessibilityIdentifier = viewModel.a11yIdentifier
        isSelected = viewModel.isSelected

        guard var updatedConfiguration = configuration else { return }
        if viewModel.titleRendering == .coreAnimationLayer {
            accessibilityLabel = viewModel.title
            titleTextLayer.isHidden = false
        } else {
            titleTextLayer.isHidden = true
            updatedConfiguration.title = viewModel.title
        }
        updatedConfiguration.contentInsets = NSDirectionalEdgeInsets(
            top: UX.verticalInset,
            leading: UX.horizontalInset,
            bottom: UX.verticalInset,
            trailing: UX.horizontalInset,
        )
        configuration = updatedConfiguration
    }

    public func applyTheme(theme: Theme) {
        normalBackgroundColor = theme.colors.layerSurfaceMediumAlpha
        normalForegroundColor = theme.colors.textPrimary
        selectedBackgroundColor = theme.colors.actionPrimary
        selectedForegroundColor = theme.colors.textInverted
        disabledBackgroundColor = theme.colors.layer2
        disabledForegroundColor = theme.colors.textDisabled
        applyShadow(FxShadow.shadow200, theme: theme)
        setNeedsUpdateConfiguration()
    }

    private func updateTitleTextLayer(font: UIFont, foregroundColor: UIColor) {
        guard let title = viewModel?.title else {
            titleTextLayer.string = nil
            return
        }

        titleTextLayer.string = NSAttributedString(
            string: title,
            attributes: [
                .font: font,
                .foregroundColor: foregroundColor
            ]
        )
    }

    /// CATextLayer updates implicitly animate by default; disable actions so dynamic type
    /// changes update the chip title immediately like UIKit button titles.
    private func performWithoutLayerAnimation(_ updates: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        updates()
        CATransaction.commit()
    }

    @objc
    private func tapped(sender: UIButton) {
        viewModel?.tappedAction?(sender)
    }
}
