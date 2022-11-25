// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

final class ImpactHeaderCell: UICollectionViewCell, NotificationThemeable {
    private(set) weak var title: UILabel!

    required init?(coder aDecoder: NSCoder) { return nil }

    override init(frame: CGRect) {
        let title = UILabel()
        self.title = title

        super.init(frame: frame)
        title.textColor = UIColor.theme.ecosia.primaryText
        title.font = .preferredFont(forTextStyle: .headline)
        title.adjustsFontForContentSizeCategory = true
        title.numberOfLines = 0
        title.translatesAutoresizingMaskIntoConstraints = false
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        contentView.addSubview(title)

        let top = title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32)
        top.priority = .init(999)
        top.isActive = true

        title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        title.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor).isActive = true
        title.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16).isActive = true
    }

    func applyTheme() {
        title.textColor = .theme.ecosia.primaryText
    }
}
