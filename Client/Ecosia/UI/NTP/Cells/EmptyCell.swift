/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class EmptyCell: UICollectionViewCell, NotificationThemeable, ReusableCell {
    let view = UIView()
    var widthConstraint: NSLayoutConstraint!
    var heightConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)

        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)

        view.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        view.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        view.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        let width = view.widthAnchor.constraint(equalToConstant: frame.width)
        width.priority = .defaultHigh
        width.isActive = true
        self.widthConstraint = width

        let height = view.heightAnchor.constraint(equalToConstant: frame.height)
        height.priority = .defaultHigh
        height.isActive = true
        self.heightConstraint = height
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func applyTheme() {
        contentView.backgroundColor = .theme.ecosia.ntpBackground
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
