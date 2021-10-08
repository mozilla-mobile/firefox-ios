/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public extension UIViewController {
    func install(_ child: UIViewController, on view: UIView, insets: UIEdgeInsets = .zero) {
        addChild(child)

        child.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child.view)
        
        child.view.snp.makeConstraints {
            $0.top.equalToSuperview().inset(insets.top)
            $0.bottom.equalToSuperview().inset(insets.bottom)
            $0.leading.equalToSuperview().inset(insets.left)
            $0.trailing.equalToSuperview().inset(insets.right)
        }

        child.didMove(toParent: self)
    }
    
    func removeAsChild() {
        self.view.removeFromSuperview()
        self.removeFromParent()
        self.didMove(toParent: nil)
    }
}
