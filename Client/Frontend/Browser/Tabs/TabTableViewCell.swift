/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

class TabTableViewCell: UITableViewCell, Themeable {
    static let identifier = "tabCell"
    
    lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.templateImageNamed("tab_close"), for: [])
        button.tintColor = UIColor.theme.tabTray.cellCloseButton
        button.sizeToFit()
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        guard let screenshotView = imageView,
            let websiteTitle = textLabel,
            let urlLabel = detailTextLabel
            else { return }
        
        screenshotView.contentMode = .scaleAspectFill
        screenshotView.clipsToBounds = true
        screenshotView.layer.cornerRadius = TabTrayV2ControllerUX.cornerRadius
        screenshotView.layer.borderWidth = 1
        screenshotView.layer.borderColor = UIColor.Photon.Grey30.cgColor

        urlLabel.textColor = UIColor.Photon.Grey40
        
        screenshotView.snp.makeConstraints { make in
            make.height.width.equalTo(68)
            make.leading.equalToSuperview().offset(TabTrayV2ControllerUX.screenshotMarginLeftRight)
            make.top.equalToSuperview().offset(TabTrayV2ControllerUX.screenshotMarginTopBottom)
            make.bottom.equalToSuperview().offset(-TabTrayV2ControllerUX.screenshotMarginTopBottom)
        }
        
        websiteTitle.snp.makeConstraints { make in
            make.leading.equalTo(screenshotView.snp.trailing).offset(TabTrayV2ControllerUX.screenshotMarginLeftRight)
            make.top.equalToSuperview().offset(TabTrayV2ControllerUX.textMarginTopBottom)
            make.bottom.equalTo(urlLabel.snp.top)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        urlLabel.snp.makeConstraints { make in
            make.leading.equalTo(screenshotView.snp.trailing).offset(TabTrayV2ControllerUX.screenshotMarginLeftRight)
            make.trailing.equalToSuperview()
            make.top.equalTo(websiteTitle.snp.bottom).offset(3)
            make.bottom.equalToSuperview().offset(-TabTrayV2ControllerUX.textMarginTopBottom)
        }

        applyTheme()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
