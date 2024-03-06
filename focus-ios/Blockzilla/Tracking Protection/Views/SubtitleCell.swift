/* This Source Code Form is subject to the terms of the Mozilla Public
  * License, v. 2.0. If a copy of the MPL was not distributed with this
  * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class SubtitleCell: UITableViewCell {

    convenience init(title: String, subtitle: String, reuseIdentifier: String? = nil) {
        self.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        textLabel?.text = title
        textLabel?.textColor = .primaryText.withAlphaComponent(0.6)
        textLabel?.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .body15)
        textLabel?.adjustsFontForContentSizeCategory = true
        textLabel?.numberOfLines = 0
        detailTextLabel?.text = subtitle
        detailTextLabel?.textColor = .primaryText
        detailTextLabel?.font = UIFontMetrics(forTextStyle: .title1).scaledFont(for: .title20)
        detailTextLabel?.adjustsFontForContentSizeCategory = true
        backgroundColor = .secondarySystemGroupedBackground
        selectionStyle = .none
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
