/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

struct OneLineCellUX {
    static let ImageSize: CGFloat = 29
    static let ImageCornerRadius: CGFloat = 6
    static let HorizontalMargin: CGFloat = 16
}

class OneLineTableViewCell: UITableViewCell, Themeable {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.separatorInset = .zero
        self.applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let indentation = CGFloat(indentationLevel) * indentationWidth

        imageView?.translatesAutoresizingMaskIntoConstraints = true
        imageView?.contentMode = .scaleAspectFill
        imageView?.layer.cornerRadius = OneLineCellUX.ImageCornerRadius
        imageView?.layer.masksToBounds = true
        imageView?.snp.remakeConstraints { make in
            guard let _ = imageView?.superview else { return }

            make.width.height.equalTo(OneLineCellUX.ImageSize)
            make.leading.equalTo(indentation + OneLineCellUX.HorizontalMargin)
            make.centerY.equalToSuperview()
        }

        textLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        textLabel?.snp.remakeConstraints { make in
            guard let _ = textLabel?.superview else { return }

            make.leading.equalTo(indentation + OneLineCellUX.ImageSize + OneLineCellUX.HorizontalMargin*2)
            make.trailing.equalTo(isEditing ? 0 : -OneLineCellUX.HorizontalMargin)
            make.centerY.equalToSuperview()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.applyTheme()
    }

    func applyTheme() {
        backgroundColor = UIColor.theme.tableView.rowBackground
        textLabel?.textColor = UIColor.theme.tableView.rowText
    }
}
