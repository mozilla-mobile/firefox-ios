// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

private let ImagePathReveal = "visible-text.png"

class PasswordTextField: ImageTextField {
    required override init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        didInitView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        didInitView()
    }

    override init() {
        // init() calls init(frame) with a 0 rect.
        super.init()
    }

    private func didInitView() {
        let image = UIImage(named: ImagePathReveal)!
        // TODO: We should resize the raw image instead of programmatically scaling it.
        let scale: CGFloat = 0.7
        let button = UIButton(frame: CGRectMake(0, 0, image.size.width * scale, image.size.height * scale))
        button.setImage(image, forState: UIControlState.Normal)
        let padding: CGFloat = 10
        let paddingView = UIView(frame: CGRectMake(0, 0, button.bounds.width + padding, button.bounds.height))
        button.center = paddingView.center
        paddingView.addSubview(button)
        rightView = paddingView
        rightViewMode = UITextFieldViewMode.Always

        button.addTarget(self, action: "didClickPasswordReveal", forControlEvents: UIControlEvents.TouchUpInside)
    }

    // Referenced as button selector.
    func didClickPasswordReveal() {
        secureTextEntry = !secureTextEntry
    }
}
