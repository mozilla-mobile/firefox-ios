/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage

struct ActionOverlayTableViewCellUX {
    static let LabelColor = UIConstants.SystemBlueColor
    static let BorderWidth: CGFloat = CGFloat(0.5)
    static let CellSideOffset = 20
    static let TitleLabelOffset = 10
    static let CellTopBottomOffset = 12
    static let StatusIconSize = 24
    static let SelectedOverlayColor = UIColor(white: 0.0, alpha: 0.25)
    static let CornerRadius: CGFloat = 3
}

class ActionOverlayTableViewCell: UITableViewCell {
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFontMedium
        titleLabel.textColor = ActionOverlayTableViewCellUX.LabelColor
        titleLabel.textAlignment = .Left
        titleLabel.numberOfLines = 1
        return titleLabel
    }()

    lazy var statusIcon: UIImageView = {
        let siteImageView = UIImageView()
        siteImageView.contentMode = UIViewContentMode.ScaleAspectFit
        siteImageView.clipsToBounds = true
        siteImageView.layer.cornerRadius = ActionOverlayTableViewCellUX.CornerRadius
        return siteImageView
    }()

    lazy var selectedOverlay: UIView = {
        let selectedOverlay = UIView()
        selectedOverlay.backgroundColor = ActionOverlayTableViewCellUX.SelectedOverlayColor
        selectedOverlay.hidden = true
        return selectedOverlay
    }()

    override var selected: Bool {
        didSet {
            self.selectedOverlay.hidden = !selected
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.mainScreen().scale

        isAccessibilityElement = true

        contentView.addSubview(selectedOverlay)
        contentView.addSubview(titleLabel)
        contentView.addSubview(statusIcon)

        let separatorLineView = UIView(frame:CGRectMake(0, 0, contentView.frame.width, 0.25))
        separatorLineView.backgroundColor = UIColor.grayColor()
        contentView.addSubview(separatorLineView)

        selectedOverlay.snp_remakeConstraints { make in
            make.edges.equalTo(contentView)
        }

        titleLabel.snp_remakeConstraints { make in
            make.leading.equalTo(contentView).offset(12)
            make.trailing.equalTo(statusIcon.snp_leading)
            make.centerY.equalTo(contentView)
        }

        statusIcon.snp_remakeConstraints { make in
            make.size.equalTo(ActionOverlayTableViewCellUX.StatusIconSize)
            make.trailing.equalTo(contentView).inset(12)
            make.centerY.equalTo(contentView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureCell(label: String, imageString: String) {
        titleLabel.text = label

        if let uiImage = UIImage(named: imageString) {
            let image = uiImage.imageWithRenderingMode(.AlwaysTemplate)
            statusIcon.image = image
            statusIcon.tintColor = UIConstants.SystemBlueColor
        }
    }
}
