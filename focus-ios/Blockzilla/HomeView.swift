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

        let background = GradientBackgroundView(alpha: 0.6, startPoint: CGPoint.zero, endPoint: CGPoint(x: 1, y: 1))
        addSubview(background)

        let textLogo = UIImageView(image: #imageLiteral(resourceName: "img_focus_wordmark"))
        addSubview(textLogo)

        let iconLogo = UIImageView(image: #imageLiteral(resourceName: "img_focus_app"))
        addSubview(iconLogo)

        let settingsButton = InsetButton()
        settingsButton.setTitle(UIConstants.strings.openSettings, for: .normal)
        settingsButton.titleLabel?.font = UIConstants.fonts.settingsHomeButton
        settingsButton.titleEdgeInsets = UIEdgeInsetsMake(10, 20, 10, 20)
        settingsButton.addTarget(self, action: #selector(didPressSettings), for: .touchUpInside)
        addSubview(settingsButton)

        background.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        textLogo.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.bottom.equalTo(snp.centerY).offset(-50)
        }

        iconLogo.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(snp.centerY).offset(50)
        }

        settingsButton.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.bottom.equalTo(self).offset(-20)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didPressSettings() {
        delegate?.homeViewDidPressSettings(homeView: self)
    }
}
