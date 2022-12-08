// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Storage
import SnapKit
import Shared
import UIKit
import MapKit

// Misc table components used for the PhotonActionSheet table view.

public enum PresentationStyle {
    case centered // used in the home panels
    case bottom // used to display the menu on phone sized devices
    case popover // when displayed on the iPad
}

extension UIModalPresentationStyle {
    func getPhotonPresentationStyle() -> PresentationStyle {
        switch self {
        case .popover:
            return .popover
        case .overFullScreen:
            return .centered
        default:
            return .bottom
        }
    }
}

public enum PhotonActionSheetCellAccessoryType {
    case Disclosure
    case Switch
    case Text
    case None
}

public enum PhotonActionSheetIconType {
    case Image
    case URL
    case TabsButton
    case None
}

// MARK: - PhotonActionSheetTitleHeaderView
class PhotonActionSheetTitleHeaderView: UITableViewHeaderFooterView, ReusableCell {
    static let Padding: CGFloat = 18

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.SmallSizeRegularWeightAS
        titleLabel.numberOfLines = 1
        titleLabel.textColor = UIColor.theme.tableView.headerTextLight
        return titleLabel
    }()

    lazy var separatorView: UIView = {
        let separatorLine = UIView()
        separatorLine.backgroundColor = UIColor.Photon.Grey40
        return separatorLine
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        self.backgroundView = UIView()
        self.backgroundView?.backgroundColor = .clear
        contentView.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(contentView).offset(PhotonActionSheetTitleHeaderView.Padding)
            make.trailing.equalTo(contentView)
            make.top.equalTo(contentView).offset(PhotonActionSheet.UX.tablePadding)
        }

        contentView.addSubview(separatorView)

        separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(titleLabel.snp.bottom).offset(PhotonActionSheet.UX.tablePadding)
            make.bottom.equalTo(contentView).inset(PhotonActionSheet.UX.tablePadding)
            make.height.equalTo(0.5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with title: String) {
        self.titleLabel.text = title
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.titleLabel.text = nil
    }
}

// MARK: - PhotonActionSheetSeparator
class PhotonActionSheetLineSeparator: UITableViewHeaderFooterView, ReusableCell {
    let separatorLineView = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.backgroundView = UIView()
        self.backgroundView?.backgroundColor = .clear
        separatorLineView.backgroundColor = UIColor.Photon.Grey40
        self.contentView.addSubview(separatorLineView)
        separatorLineView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.centerY.equalTo(self)
            make.height.equalTo(0.5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - PhotonActionSheetSeparator
class PhotonActionSheetSeparator: UITableViewHeaderFooterView, ReusableCell {
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.theme.tableView.separator
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
