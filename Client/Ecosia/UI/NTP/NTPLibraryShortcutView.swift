/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class NTPLibraryShortcutView: UIView {
    static let spacing: CGFloat = 14
    static let iconSize: CGFloat = 52
    static let titleMargin: CGFloat = 2
    static let margin: CGFloat = 10
    static let titleButtonMargin: CGFloat = 4

    var button = UIButton()
    var title = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(button)
        addSubview(title)

        title.allowsDefaultTighteningForTruncation = true
        title.lineBreakMode = .byTruncatingTail
        title.font = .preferredFont(forTextStyle: .footnote)
        title.adjustsFontForContentSizeCategory = true
        title.textAlignment = .center
        title.numberOfLines = 2
        title.setContentHuggingPriority(.required, for: .vertical)
        title.setContentCompressionResistancePriority(.required, for: .vertical)
        title.translatesAutoresizingMaskIntoConstraints = false

        button.imageView?.contentMode = .scaleToFill
        button.layer.cornerRadius = Self.iconSize/2.0
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(equalInset: Self.spacing)
        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor, constant: Self.margin),
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.widthAnchor.constraint(equalToConstant: Self.iconSize),
            button.heightAnchor.constraint(equalToConstant: Self.iconSize),
            title.topAnchor.constraint(equalTo: button.bottomAnchor, constant: Self.titleButtonMargin),
            title.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -Self.margin),
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.titleMargin),
            title.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.titleMargin),
            title.heightAnchor.constraint(equalToConstant: 10).priority(.defaultHigh)
        ])

    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
