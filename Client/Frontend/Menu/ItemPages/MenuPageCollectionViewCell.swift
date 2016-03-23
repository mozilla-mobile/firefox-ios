/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import UIKit

class MenuPageCollectionViewCell: UICollectionViewCell {

    var pageView: MenuPageView = MenuPageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.pageView)
        self.pageView.snp_makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
