// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// This class is a button that enables resizing with dynamic type
/// This is a building block component for developement purpose, and isn't the designer component in itself.
/// See `RoundedButton` for the designer button component (to be done with FXIOS-6948 #15441)
open class ResizableButton: UIButton {
    public struct UX {
        public static let buttonEdgeSpacing: CGFloat = 8
    }

    public var buttonEdgeSpacing: CGFloat = UX.buttonEdgeSpacing {
        didSet {
            contentEdgeInsets = UIEdgeInsets(top: 0,
                                             left: buttonEdgeSpacing,
                                             bottom: 0,
                                             right: buttonEdgeSpacing)
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }

    func commonInit() {
        titleLabel?.numberOfLines = 0
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.lineBreakMode = .byWordWrapping
        adjustsImageSizeForAccessibilityContentSizeCategory = true
        contentEdgeInsets = UIEdgeInsets(top: 0,
                                         left: buttonEdgeSpacing,
                                         bottom: 0,
                                         right: buttonEdgeSpacing)
    }

    public override var intrinsicContentSize: CGSize {
        guard let title = titleLabel else {
            return super.intrinsicContentSize
        }

        let widthTitleInset = titleEdgeInsets.left + titleEdgeInsets.right
        let widthImageInset = imageEdgeInsets.left + imageEdgeInsets.right
        let widthContentInset = contentEdgeInsets.left + contentEdgeInsets.right

        var availableWidth = frame.width - widthTitleInset - widthImageInset - widthContentInset
        if let imageWidth = image(for: [])?.size.width {
            availableWidth = availableWidth - imageWidth
        }

        let size = title.sizeThatFits(CGSize(width: availableWidth, height: .greatestFiniteMagnitude))
        return CGSize(width: size.width + widthContentInset,
                      height: size.height + contentEdgeInsets.top + contentEdgeInsets.bottom)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let title = titleLabel else { return }

        titleLabel?.preferredMaxLayoutWidth = title.frame.size.width
    }
}
