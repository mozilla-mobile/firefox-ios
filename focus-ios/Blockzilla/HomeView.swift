/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol HomeViewDelegate: class {
    func homeViewDidPressSettings(homeView: HomeView)
}

class HomeView: UIView {
    weak var delegate: HomeViewDelegate?

    init() {
        super.init(frame: CGRect.zero)

        let wordmark = AppInfo.isFocus ? #imageLiteral(resourceName: "img_focus_wordmark") : #imageLiteral(resourceName: "img_klar_wordmark")
        let textLogo = UIImageView(image: wordmark)
        addSubview(textLogo)

        let description1 = UILabel()
        description1.textColor = .white
        description1.font = UIConstants.fonts.homeLabel
        description1.textAlignment = .center
        description1.text = UIConstants.strings.homeLabel1
        description1.numberOfLines = 0
        addSubview(description1)

        let description2 = UILabel()
        description2.textColor = .white
        description2.font = UIConstants.fonts.homeLabel
        description2.textAlignment = .center
        description2.text = UIConstants.strings.homeLabel2
        description2.numberOfLines = 0
        addSubview(description2)

        let settingsButton = UIButton()
        settingsButton.setImage(#imageLiteral(resourceName: "icon_settings"), for: .normal)
        settingsButton.contentEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        settingsButton.addTarget(self, action: #selector(didPressSettings), for: .touchUpInside)
        addSubview(settingsButton)

        textLogo.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.bottom.equalTo(snp.centerY).offset(-60)
        }

        description1.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(snp.centerY).offset(50)
        }

        description2.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(description1.snp.bottom).offset(5)
        }

        settingsButton.snp.makeConstraints { make in
            make.top.trailing.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didPressSettings() {
        delegate?.homeViewDidPressSettings(homeView: self)
    }
}
