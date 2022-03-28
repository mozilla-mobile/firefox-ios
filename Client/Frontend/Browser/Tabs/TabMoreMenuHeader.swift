// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import UIKit

class TabMoreMenuHeader: UIView {
    lazy var imageView: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        imgView.clipsToBounds = true
        imgView.layer.cornerRadius = ChronologicalTabsControllerUX.cornerRadius
        imgView.layer.borderWidth = 1
        imgView.layer.borderColor = UIColor.Photon.Grey30.cgColor
        return imgView
    }()
    
    lazy var titleLabel: UILabel = {
        let title = UILabel()
        title.numberOfLines = 2
        title.lineBreakMode = .byTruncatingTail
        title.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        title.textColor = UIColor.theme.defaultBrowserCard.textColor
        return title
    }()
    
    lazy var descriptionLabel: UILabel = {
        let descriptionText = UILabel()
        descriptionText.text = String.DefaultBrowserCardDescription
        descriptionText.numberOfLines = 0
        descriptionText.lineBreakMode = .byWordWrapping
        descriptionText.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        descriptionText.textColor = UIColor.theme.defaultBrowserCard.textColor
        return descriptionText
    }()
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupView()
    }
    
    private func setupView() {
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        
        imageView.snp.makeConstraints { make in
            make.height.width.equalTo(100)
            make.leading.equalToSuperview().offset(ChronologicalTabsControllerUX.screenshotMarginLeftRight)
            make.top.equalToSuperview().offset(ChronologicalTabsControllerUX.screenshotMarginTopBottom)
            make.bottom.equalToSuperview().offset(-ChronologicalTabsControllerUX.screenshotMarginTopBottom)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(imageView.snp.trailing).offset(ChronologicalTabsControllerUX.screenshotMarginLeftRight)
            make.top.equalToSuperview().offset(ChronologicalTabsControllerUX.textMarginTopBottom)
            make.bottom.equalTo(descriptionLabel.snp.top)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.leading.equalTo(imageView.snp.trailing).offset(ChronologicalTabsControllerUX.screenshotMarginLeftRight)
            make.trailing.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(3)
            make.bottom.equalToSuperview().offset(-ChronologicalTabsControllerUX.textMarginTopBottom * CGFloat(titleLabel.numberOfLines))
        }
        
        applyTheme()
    }
    
    func applyTheme() {
        backgroundColor = UIColor.secondarySystemGroupedBackground
        titleLabel.textColor = UIColor.label
        descriptionLabel.textColor = UIColor.secondaryLabel
    }
}
