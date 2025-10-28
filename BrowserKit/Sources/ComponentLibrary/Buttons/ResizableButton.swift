// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

open class ResizableButton: UIButton {
    public struct UX {
        public static let buttonEdgeHorizontalSpacing: CGFloat = 8
        public static let buttonEdgeVerticalSpacing: CGFloat = 0
    }

    public var buttonEdgeInsets = NSDirectionalEdgeInsets(top: UX.buttonEdgeVerticalSpacing,
                                                          leading: UX.buttonEdgeHorizontalSpacing,
                                                          bottom: UX.buttonEdgeVerticalSpacing,
                                                          trailing: UX.buttonEdgeHorizontalSpacing) {
        didSet {
            updateContentInsets()
        }
    }

    // Ecosia: Add support to custom font
    public var customFont: UIFont? {
        didSet {
            updateFontConfiguration()
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

    override public var intrinsicContentSize: CGSize {
        guard let title = titleLabel, let configuration else {
            return super.intrinsicContentSize
        }

        let imagePadding = configuration.imagePadding
        let widthContentInset = configuration.contentInsets.leading + configuration.contentInsets.trailing
        let heightContentInset = configuration.contentInsets.top + configuration.contentInsets.bottom

        var availableWidth = frame.width - widthContentInset
        if let imageWidth = image(for: [])?.size.width ?? configuration.image?.size.width {
            availableWidth = availableWidth - imageWidth - imagePadding
        }

        let size = title.sizeThatFits(CGSize(width: availableWidth, height: .greatestFiniteMagnitude))
        /* Ecosia: Update Size calculation
        return CGSize(width: size.width + widthContentInset,
                      height: size.height + heightContentInset)
         */
        let boundingBox = title.text?.boundingRect(with: size, options: .usesLineFragmentOrigin, context: nil) ?? .zero
        return CGSize(width: boundingBox.width + widthContentInset,
                      height: boundingBox.height + heightContentInset)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        guard let title = titleLabel else { return }

        titleLabel?.preferredMaxLayoutWidth = title.frame.size.width
    }

    private func commonInit() {
        titleLabel?.numberOfLines = 0
        titleLabel?.adjustsFontForContentSizeCategory = true
        adjustsImageSizeForAccessibilityContentSizeCategory = true

        configuration = UIButton.Configuration.plain()
        configuration?.titleLineBreakMode = .byWordWrapping
        updateContentInsets()
        // Ecosia: Add support to custom font
        updateFontConfiguration()
    }

    // Ecosia: Add support to custom font
    private func updateFontConfiguration() {
        guard let font = customFont else { return }

        configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            // Respect Dynamic Type scaling if the original font does
            if incoming.font?.fontDescriptor.symbolicTraits.contains(.traitBold) ?? false {
                outgoing.font = UIFontMetrics.default.scaledFont(for: font)
            } else {
                outgoing.font = font
            }
            return outgoing
        }
    }

    private func updateContentInsets() {
        configuration?.contentInsets = buttonEdgeInsets
    }
}
