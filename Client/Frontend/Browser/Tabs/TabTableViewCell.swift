// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import UIKit
import Shared
import SnapKit

class TabTableViewCell: UITableViewCell, NotificationThemeable {
    static let identifier = "tabCell"
    var screenshotView: UIImageView?
    var websiteTitle: UILabel?
    var urlLabel: UILabel?
    
    lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.templateImageNamed("tab_close"), for: [])
        button.accessibilityIdentifier = "closeTabButtonTabTray"
        button.tintColor = UIColor.theme.tabTray.cellCloseButton
        button.sizeToFit()
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        guard let imageView = imageView, let title = textLabel, let label = detailTextLabel else { return }
        
        self.screenshotView = imageView
        self.websiteTitle = title
        self.urlLabel = label
        
        viewSetup()
        applyTheme()
    }
    
    private func viewSetup() {
        guard let websiteTitle = websiteTitle, let screenshotView = screenshotView, let urlLabel = urlLabel else { return }
        
        screenshotView.contentMode = .scaleAspectFill
        screenshotView.clipsToBounds = true
        screenshotView.layer.cornerRadius = ChronologicalTabsControllerUX.cornerRadius
        screenshotView.layer.borderWidth = 1
        screenshotView.layer.borderColor = UIColor.Photon.Grey30.cgColor
        
        screenshotView.snp.makeConstraints { make in
            make.height.width.equalTo(100)
            make.leading.equalToSuperview().offset(ChronologicalTabsControllerUX.screenshotMarginLeftRight)
            make.top.equalToSuperview().offset(ChronologicalTabsControllerUX.screenshotMarginTopBottom)
            make.bottom.equalToSuperview().offset(-ChronologicalTabsControllerUX.screenshotMarginTopBottom)
        }
        
        websiteTitle.numberOfLines = 2
        websiteTitle.snp.makeConstraints { make in
            make.leading.equalTo(screenshotView.snp.trailing).offset(ChronologicalTabsControllerUX.screenshotMarginLeftRight)
            make.top.equalToSuperview().offset(ChronologicalTabsControllerUX.textMarginTopBottom)
            make.bottom.equalTo(urlLabel.snp.top)
            make.trailing.equalToSuperview().offset(-16)
        }

        urlLabel.snp.makeConstraints { make in
            make.leading.equalTo(screenshotView.snp.trailing).offset(ChronologicalTabsControllerUX.screenshotMarginLeftRight)
            make.trailing.equalToSuperview()
            make.top.equalTo(websiteTitle.snp.bottom).offset(3)
            make.bottom.equalToSuperview().offset(-ChronologicalTabsControllerUX.textMarginTopBottom * CGFloat(websiteTitle.numberOfLines))
        }
    }
    
    // Helper method to remake title constraint
    func remakeTitleConstraint() {
        guard let websiteTitle = websiteTitle, let text = websiteTitle.text, !text.isEmpty, let screenshotView = screenshotView, let urlLabel = urlLabel else { return }
        websiteTitle.numberOfLines = 2
        websiteTitle.snp.remakeConstraints { make in
            make.leading.equalTo(screenshotView.snp.trailing).offset(ChronologicalTabsControllerUX.screenshotMarginLeftRight)
            make.top.equalToSuperview().offset(ChronologicalTabsControllerUX.textMarginTopBottom)
            make.bottom.equalTo(urlLabel.snp.top)
            make.trailing.equalToSuperview().offset(-16)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }

    func applyTheme() {
        backgroundColor = UIColor.secondarySystemGroupedBackground
        textLabel?.textColor = UIColor.label
        detailTextLabel?.textColor = UIColor.secondaryLabel
        closeButton.tintColor = UIColor.secondaryLabel
    }
}
