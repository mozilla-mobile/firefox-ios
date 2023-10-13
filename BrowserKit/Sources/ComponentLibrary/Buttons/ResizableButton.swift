// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

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

    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
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

    override public var intrinsicContentSize: CGSize {
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

    override public func layoutSubviews() {
        super.layoutSubviews()
        guard let title = titleLabel else { return }

        titleLabel?.preferredMaxLayoutWidth = title.frame.size.width
    }
}
