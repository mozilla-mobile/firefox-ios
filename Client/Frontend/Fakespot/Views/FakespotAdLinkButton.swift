// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import ComponentLibrary

class FakespotAdLinkButton: LinkButton {
    private var numberOfLines = 0
    private var previousFrame: CGRect = .zero

    override public var frame: CGRect {
        didSet {
            // invalidate intrinsic content size so that we calculate it correctly
            // when not the full button text should be shown
            guard previousFrame != frame, numberOfLines > 0 else { return }

            previousFrame = frame
            invalidateIntrinsicContentSize()
        }
    }

    override public func configure(viewModel: LinkButtonViewModel) {
        super.configure(viewModel: viewModel)

        guard let config = configuration else {
            return
        }
        var updatedConfiguration = config

        if viewModel.numberOfLines > 0 {
            updatedConfiguration.titleLineBreakMode = .byTruncatingTail
            self.numberOfLines = viewModel.numberOfLines
        }

        configuration = updatedConfiguration
        layoutIfNeeded()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        guard let titleLabel, numberOfLines > 0 else { return }

        // hack to be able to restrict the number of lines displayed
        titleLabel.numberOfLines = numberOfLines
        sizeToFit()
    }

    override public var intrinsicContentSize: CGSize {
        // will only be calculated when the number of lines displayed is restricted
        // without autolayout is not working correctly
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
}
