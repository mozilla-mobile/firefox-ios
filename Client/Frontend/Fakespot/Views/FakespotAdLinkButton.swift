// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import ComponentLibrary

class FakespotAdLinkButton: LinkButton {
    private struct UX {
        static let numberOfLines: Int = 3
    }

    private var previousFrame: CGRect = .zero

    override public var frame: CGRect {
        didSet {
            guard previousFrame != frame else { return }

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
        updatedConfiguration.titleLineBreakMode = .byTruncatingTail

        configuration = updatedConfiguration
        layoutIfNeeded()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        guard let titleLabel else { return }

        // hack to be able to restrict the number of lines displayed
        titleLabel.numberOfLines = UX.numberOfLines
        sizeToFit()
    }

    override public var intrinsicContentSize: CGSize {
        guard let title = titleLabel,
              let configuration
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
