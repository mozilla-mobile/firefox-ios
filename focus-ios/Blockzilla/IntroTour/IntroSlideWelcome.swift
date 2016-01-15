/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class IntroSlideWelcome: UIView {
    init() {
        super.init(frame: CGRectZero)

        let welcomeLabel = UILabel()
        welcomeLabel.text = NSLocalizedString("Welcome", comment: "Text displayed under the wave on the first intro slide at launch")
        welcomeLabel.textColor = UIConstants.Colors.FocusOrange
        addSubview(welcomeLabel)

        let waveView = WaveView()
        waveView.active = true
        addSubview(waveView)

        let descriptionLabel = UILabel()
        let descriptionText = NSLocalizedString("%@ helps you improve the privacy and performance of your mobile browsing experience. You control what types of page content are allowed.", comment: "Description text shown on the welcome slide of the tour")
        descriptionLabel.text = String(format: descriptionText, AppInfo.ProductName)
        descriptionLabel.textColor = UIConstants.Colors.DefaultFont
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = NSTextAlignment.Center
        addSubview(descriptionLabel)

        waveView.snp_makeConstraints { make in
            make.top.equalTo(self).offset(50)
            make.leading.trailing.equalTo(self)
            make.height.equalTo(200)
        }

        welcomeLabel.snp_makeConstraints { make in
            make.centerX.equalTo(self)
            make.bottom.equalTo(descriptionLabel.snp_top).offset(-20)
        }

        descriptionLabel.snp_makeConstraints { make in
            make.bottom.equalTo(self).offset(-100)
            make.leading.trailing.equalTo(self).inset(30)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
