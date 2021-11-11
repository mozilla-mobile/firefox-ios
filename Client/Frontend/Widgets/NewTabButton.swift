// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import SnapKit

class NewTabButton: UIButton {
    lazy var plusImage: UIImageView = {
        let plusImage = UIImageView()
        plusImage.image = UIImage.templateImageNamed("menu-NewTab")
        return plusImage
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        viewSetup()
    }
    
    convenience init(target: Any, selector: Selector) {
        self.init()
        addTarget(target, action: selector, for: .touchUpInside)
        viewSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        viewSetup()
    }

    private func viewSetup() {
        addSubview(plusImage)

        plusImage.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalTo(self.snp.centerY)
        }
    }
}
