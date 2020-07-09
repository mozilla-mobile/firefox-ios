/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class ImageButtonWithLabel: UIView {
    lazy var button = UIButton()
    lazy var label = UILabel()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        performLayout()
    }

    fileprivate func performLayout() {
        addSubview(button)
        addSubview(label)
        button.imageView?.contentMode = .scaleAspectFit

        button.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(self.safeAreaLayoutGuide).offset(5)
            make.right.greaterThanOrEqualTo(self.safeAreaLayoutGuide).offset(40)
            make.left.greaterThanOrEqualTo(self.safeAreaLayoutGuide).inset(40)
            make.height.greaterThanOrEqualTo(60)
        }

        label.snp.makeConstraints { make in
            make.top.equalTo(button.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalTo(self)
            make.height.greaterThanOrEqualTo(10)
        }

        label.numberOfLines = 1
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
    }

    func addTarget(_ target: AnyObject?, action: Selector, forControlEvents events: UIControl.Event) {
        button.addTarget(target, action: action, for: events)
    }
}
