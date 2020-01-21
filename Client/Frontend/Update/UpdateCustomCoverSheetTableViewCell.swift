/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class UpdateCustomCoverSheetTableViewCell: UITableViewCell {
    // Tableview cell items
    var updateCoverSheetCellImageView: UIImageView = {
        let imgView = UIImageView(image: #imageLiteral(resourceName: "darkModeUpdate"))
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        return imgView
    }()
    var coverSheetCellDescriptionLabel: UILabel = {
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
        self.contentView.backgroundColor = .white
        self.selectionStyle = .none
        addSubview(updateCoverSheetCellImageView)
        addSubview(coverSheetCellDescriptionLabel)
        updateCoverSheetCellImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(UpdateViewControllerUX.edgeInset)
            make.height.width.equalTo(30)
            make.top.equalToSuperview().offset(2)
        }
        
        coverSheetCellDescriptionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(2)
            make.trailing.equalToSuperview().inset(UpdateViewControllerUX.edgeInset)
            make.bottom.equalTo(snp.bottom).offset(-10)
            make.leading.equalTo(updateCoverSheetCellImageView.snp.trailing).offset(10)
        }
    }
}
