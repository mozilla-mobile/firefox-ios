/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Shared

class UpdateViewController: UIViewController {
    
    private var tableView: CoverSheetTableView?
    
    /* The layout for update view controller.
        
     |----------------|
     |Image           |
     |                |
     |Title Multiline |
     |----------------|
     |(TableView)     |
     |                |
     | [img] Descp.   |
     |                |
     | [img] Descp.   |
     |                |
     |                |
     |----------------|
     |                |
     |                |
     |    [Button]    |
     |----------------|
     
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func setupTableView() {
        self.tableView = CoverSheetTableView()
    }
}

class CustomCoverSheetTableViewCell: UITableViewCell {
    
    // Tableview cell items
    var coverSheetCellImageView: UIImageView = {
        let imgView = UIImageView(image: #imageLiteral(resourceName: "pin_small"))
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        return imgView
    }()
    
    var coverSheetCellDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = Strings.CoverSheetV22DarkModeTitle
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(coverSheetCellImageView)
        addSubview(coverSheetCellDescriptionLabel)
        coverSheetCellImageView.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.width.equalTo(20)
            make.centerY.centerX.equalToSuperview()
        }
        
        coverSheetCellDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(self.snp.top)
            make.bottom.equalTo(self.snp.bottom)
            make.leading.equalTo(coverSheetCellImageView.snp.leading)
            make.trailing.equalTo(self.snp.right)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CoverSheetTableView: UITableView {
    
}
