/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Shared

class UpdateViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // Constants
    static let buttonEdgeInset = 15
    static let buttonHeight = 46
    static let buttonSpacing = 16
    static let buttonBlue = UIColor.Photon.Blue50
    
    // Private Vars
    private var debugItems:[String] = ["\(Strings.CoverSheetV22DarkModeTitle)\n\n\(Strings.CoverSheetV22DarkModeDescription)"]
    private var tableView: CoverSheetTableView?
    private var imageView: UIImageView = {
        let imgView = UIImageView(image: #imageLiteral(resourceName: "splash"))
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        return imgView
    }()
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.text = Strings.WhatsNewString
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private var startBrowsingButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.StartBrowsingButtonTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 10
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = buttonBlue
        return button
    }()
    
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
        self.tableView = CoverSheetTableView(frame: CGRect.zero, style: .grouped)
        self.view.addSubview(imageView)
        self.view.addSubview(titleLabel)
        self.view.addSubview(startBrowsingButton)
        self.view.addSubview(tableView!)
        setupTopView()
        setupTableView()
        setupButtonView()
    }
    
    func setupTopView() {
        imageView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(UpdateViewController.buttonEdgeInset)
//            let h = view.frame.height
            // On large iPhone screens, bump this up from the bottom
//            let offset: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 20 : (h > 800 ? 60 : 20)
//            make.bottom.equalTo(titleLabel.snp.top)
            make.top.equalToSuperview().inset(50)
            make.height.width.equalTo(70)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(UpdateViewController.buttonEdgeInset)
            make.right.equalToSuperview()
            make.height.equalTo(40)
            make.top.equalTo(imageView.snp.bottom)
        }
    }
    
    func setupTableView() {
        self.tableView?.register(CustomCoverSheetTableViewCell.self, forCellReuseIdentifier: "CustomCoverSheetTableViewCellIdentifier")
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        self.tableView?.backgroundColor = UIColor.green
        self.tableView?.separatorStyle = .none
        self.tableView?.sectionHeaderHeight = 0
        self.tableView?.sectionFooterHeight = 0
        self.tableView?.snp.makeConstraints({ make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
//            make.top.equalTo(self.view.snp.top)
            make.bottom.equalTo(startBrowsingButton.snp.top).offset(-10)
//            make.height.equalTo(self.view.snp.height)
            make.width.equalTo(self.view.snp.width)
//            make.leading.equalToSuperview()
//            make.trailing.equalToSuperview()
//            make.right.equalToSuperview()
            make.centerX.equalToSuperview()
        })
    }
    
    func setupButtonView() {
        startBrowsingButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(UpdateViewController.buttonEdgeInset)
            let h = view.frame.height
            // On large iPhone screens, bump this up from the bottom
            let offset: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 20 : (h > 800 ? 60 : 20)
            make.bottom.equalToSuperview().inset(offset)
            make.height.equalTo(UpdateViewController.buttonHeight)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return debugItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCoverSheetTableViewCellIdentifier", for: indexPath) as? CustomCoverSheetTableViewCell
        let currentLastItem = debugItems[indexPath.row]
        cell?.coverSheetCellDescriptionLabel.text = currentLastItem
        return cell!
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
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(coverSheetCellImageView)
        addSubview(coverSheetCellDescriptionLabel)
        coverSheetCellImageView.snp.makeConstraints { make in
            
            make.left.equalToSuperview().inset(UpdateViewController.buttonEdgeInset)
            make.height.width.equalTo(40)
            make.top.equalToSuperview().offset(2)
//            make.bottom.equalToSuperview().offset(-10)
//            make.centerY.equalToSuperview()
//            make.centerY.centerX.equalToSuperview()
        }
        
        coverSheetCellDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(self.snp.top)
            make.bottom.equalTo(self.snp.bottom)
//            make.leading.equalTo(coverSheetCellImageView.snp.leading)
            make.leading.equalTo(self.snp.leading)
            make.trailing.equalTo(self.snp.trailing)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CoverSheetTableView: UITableView {
    
}
