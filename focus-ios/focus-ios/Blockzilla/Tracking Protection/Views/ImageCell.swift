/* This Source Code Form is subject to the terms of the Mozilla Public
  * License, v. 2.0. If a copy of the MPL was not distributed with this
  * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class ImageCell: UITableViewCell {

    convenience init(image: UIImage, title: String, style: UITableViewCell.CellStyle = .default, reuseIdentifier: String? = nil) {
        self.init(style: style, reuseIdentifier: reuseIdentifier)
        imageView?.image = image
        textLabel?.text = title
        textLabel?.textColor = .primaryText
        textLabel?.numberOfLines = 0
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
