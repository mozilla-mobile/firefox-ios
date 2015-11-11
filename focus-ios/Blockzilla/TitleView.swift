/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class TitleView: UIView {
    init() {
        super.init(frame: CGRectZero)

        let logo = UIImage(named: "HeaderLogo")!
        let logoView = UIImageView(image: logo)
        addSubview(logoView)

        translatesAutoresizingMaskIntoConstraints = false

        logoView.snp_makeConstraints { make in
            make.bottom.equalTo(self).inset(5)
            make.top.equalTo(self).inset(10)
            make.centerX.equalTo(self)
            make.size.equalTo(logo.size)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}