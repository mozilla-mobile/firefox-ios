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

        let settingsButton = UIButton()
        settingsButton.setImage(#imageLiteral(resourceName: "icon_settings"), for: .normal)
        settingsButton.contentEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
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
            make.top.equalTo(self).offset(10)
            make.trailing.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didPressSettings() {
        delegate?.homeViewDidPressSettings(homeView: self)
    }
}
