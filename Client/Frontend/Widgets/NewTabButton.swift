/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SnapKit

class NewTabButton: UIButton {
    lazy var plusImage: UIImageView = {
        let plusImage = UIImageView()
        plusImage.image = UIImage(named: "menu-NewTab")?.tinted(withColor: .systemBlue)
        return plusImage
    }()
    lazy var newTabTitle: UILabel = {
        let newTabCopy = UILabel()
        newTabCopy.text = Strings.NewTabTitle
        newTabCopy.textColor = .systemBlue
        return newTabCopy
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
        addSubview(newTabTitle)
        
        plusImage.snp.makeConstraints { make in
            make.left.equalTo(newTabTitle.snp.right)
            make.right.equalToSuperview()
            make.centerY.equalTo(self.snp.centerY)
        }
        newTabTitle.snp.makeConstraints { make in
            make.right.equalTo(plusImage.snp.left).offset(-10)
            make.left.equalToSuperview()
            make.height.equalTo(24)
            make.centerY.equalTo(self.snp.centerY)
        }
    }
}
