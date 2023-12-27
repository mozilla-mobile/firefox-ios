// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/**
 * Button whose insets are included in its intrinsic size.
 */
class InsetButton: UIButton {
    override var intrinsicContentSize: CGSize {
        guard let title = titleLabel, let configuration else {
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
