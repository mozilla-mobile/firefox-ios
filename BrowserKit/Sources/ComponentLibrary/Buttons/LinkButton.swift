// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public class LinkButton: UIButton, ThemeApplicable {
    private var numberOfLines = 0
    private var previousFrame: CGRect = .zero
    private var foregroundColorNormal: UIColor = .clear
    private var foregroundColorHighlighted: UIColor = .clear
    private var backgroundColorNormal: UIColor = .clear

    public override var frame: CGRect {
        didSet {
            guard previousFrame != frame, numberOfLines > 0 else { return }

            previousFrame = frame
            invalidateIntrinsicContentSize()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        configuration = UIButton.Configuration.plain()
    }

    public func configure(viewModel: LinkButtonViewModel) {
        guard let config = configuration else {
            return
        }
        var updatedConfiguration = config

        updatedConfiguration.title = viewModel.title
        updatedConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                                   size: viewModel.fontSize)
            return outgoing
        }
        updatedConfiguration.contentInsets = viewModel.contentInsets

        accessibilityIdentifier = viewModel.a11yIdentifier
        contentHorizontalAlignment = viewModel.contentHorizontalAlignment

        if viewModel.numberOfLines > 0 {
            updatedConfiguration.titleLineBreakMode = .byTruncatingTail
            self.numberOfLines = viewModel.numberOfLines
        }

        configuration = updatedConfiguration
        layoutIfNeeded()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func updateConfiguration() {
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

    override public func layoutSubviews() {
        super.layoutSubviews()

        guard let titleLabel, numberOfLines > 0 else { return }

        titleLabel.numberOfLines = numberOfLines
        sizeToFit()
    }

    override public var intrinsicContentSize: CGSize {
        guard let title = titleLabel,
              let configuration,
              numberOfLines > 0
        else {
            return super.intrinsicContentSize
        }

        let widthContentInset = configuration.contentInsets.leading + configuration.contentInsets.trailing
        let heightContentInset = configuration.contentInsets.top + configuration.contentInsets.bottom

        let availableWidth = frame.width - widthContentInset
        let size = title.sizeThatFits(CGSize(width: availableWidth, height: .greatestFiniteMagnitude))

        return CGSize(width: size.width + widthContentInset,
                      height: size.height + heightContentInset)
    }

    // MARK: ThemeApplicable

    public func applyTheme(theme: Theme) {
        foregroundColorNormal = theme.colors.textAccent
        foregroundColorHighlighted = theme.colors.actionPrimaryHover
        backgroundColorNormal = .clear
        setNeedsUpdateConfiguration()
    }
}
