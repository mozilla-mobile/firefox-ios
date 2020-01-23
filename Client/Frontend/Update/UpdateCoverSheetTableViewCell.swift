/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

struct UpdateCoverSheetTableViewCellUX {
    struct ImageView {
        static let paddingTop = 2
        static let paddingLeft = 18
        static let height = 30
    }
    
    struct DescriptionLabel {
        static let paddingTop = 2
        static let paddingTrailing = 18
        static let bottom = -10
        static let leading = 10
    }
}
    
class UpdateCoverSheetTableViewCell: UITableViewCell {
    // Tableview cell items
    var updateCoverSheetCellImageView: UIImageView = {
        let imgView = UIImageView(image: #imageLiteral(resourceName: "darkModeUpdate"))
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        return imgView
    }()
    var updateCoverSheetCellDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = Strings.CoverSheetV22DarkModeTitle
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialViewSetup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initialViewSetup() {
        self.selectionStyle = .none
        addSubview(updateCoverSheetCellImageView)
        addSubview(updateCoverSheetCellDescriptionLabel)
        updateCoverSheetCellImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(UpdateCoverSheetTableViewCellUX.ImageView.paddingLeft)
            make.height.width.equalTo(UpdateCoverSheetTableViewCellUX.ImageView.height)
            make.top.equalToSuperview().offset(UpdateCoverSheetTableViewCellUX.ImageView.paddingTop)
        }
        
        updateCoverSheetCellDescriptionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(UpdateCoverSheetTableViewCellUX.DescriptionLabel.paddingTop)
            make.trailing.equalToSuperview().inset(UpdateCoverSheetTableViewCellUX.DescriptionLabel.paddingTrailing)
            make.bottom.equalTo(snp.bottom).offset(UpdateCoverSheetTableViewCellUX.DescriptionLabel.bottom)
            make.leading.equalTo(updateCoverSheetCellImageView.snp.trailing).offset(UpdateCoverSheetTableViewCellUX.DescriptionLabel.leading)
        }
        fxThemeSupport()
    }
    
    func fxThemeSupport() {
        if UpdateViewController.theme == .dark {
            self.updateCoverSheetCellImageView.setImageColor(color: .white)
            self.updateCoverSheetCellDescriptionLabel.textColor = .white
            self.contentView.backgroundColor = .black
        } else {
            self.updateCoverSheetCellImageView.setImageColor(color: .black)
            self.updateCoverSheetCellDescriptionLabel.textColor = .black
            self.contentView.backgroundColor = .white
        }
    }
}
