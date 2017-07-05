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
    static let StatusIconSize = 28
    static let SelectedOverlayColor = UIColor(white: 0.0, alpha: 0.25)
    static let CornerRadius: CGFloat = 3
}

class ActionOverlayTableViewCell: UITableViewCell {
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.LargeSizeRegularWeightAS
        titleLabel.minimumScaleFactor = 0.8 // Scale the font if we run out of space
        titleLabel.textColor = ActionOverlayTableViewCellUX.LabelColor
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1
        return titleLabel
    }()

    lazy var statusIcon: UIImageView = {
        let siteImageView = UIImageView()
        siteImageView.contentMode = UIViewContentMode.scaleAspectFit
        siteImageView.clipsToBounds = true
        siteImageView.layer.cornerRadius = ActionOverlayTableViewCellUX.CornerRadius
        return siteImageView
    }()

    lazy var selectedOverlay: UIView = {
        let selectedOverlay = UIView()
        selectedOverlay.backgroundColor = ActionOverlayTableViewCellUX.SelectedOverlayColor
        selectedOverlay.isHidden = true
        return selectedOverlay
    }()

    override var isSelected: Bool {
        didSet {
            self.selectedOverlay.isHidden = !isSelected
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale

        isAccessibilityElement = true

        contentView.addSubview(selectedOverlay)
        contentView.addSubview(titleLabel)
        contentView.addSubview(statusIcon)

        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor.lightGray
        contentView.addSubview(separatorLineView)

        separatorLineView.snp.makeConstraints { make in
            make.leading.top.trailing.equalTo(self)
            make.height.equalTo(0.25)
        }

        selectedOverlay.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(contentView).offset(12)
            make.trailing.equalTo(statusIcon.snp.leading)
            make.centerY.equalTo(contentView)
        }

        statusIcon.snp.makeConstraints { make in
            make.size.equalTo(ActionOverlayTableViewCellUX.StatusIconSize)
            make.trailing.equalTo(contentView).inset(12)
            make.centerY.equalTo(contentView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureCell(_ label: String, imageString: String) {
        titleLabel.text = label

        if let uiImage = UIImage(named: imageString) {
            let image = uiImage.withRenderingMode(.alwaysTemplate)
            statusIcon.image = image
            statusIcon.tintColor = UIConstants.SystemBlueColor
        }
    }
}
