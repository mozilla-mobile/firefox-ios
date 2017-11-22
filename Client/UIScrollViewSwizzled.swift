/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

// Workaround for bug 1417152, whereby NaN bounds are being set on the scrollview when viewing PDFs in the web view.

private let swizzling: (UIScrollView.Type) -> Void = { obj in
    let originalSelector = #selector(setter: UIView.bounds)
    let swizzledSelector = #selector(obj.swizzle_setBounds(bounds:))
    let originalMethod = class_getInstanceMethod(obj, originalSelector)
    let swizzledMethod = class_getInstanceMethod(obj, swizzledSelector)
    method_exchangeImplementations(originalMethod, swizzledMethod)
}

extension UIScrollView {
    open override class func initialize() {
        // This code will mask the problem, so disable it in Beta in order that we can research it further.
        guard AppConstants.BuildChannel == .release else {
            return
        }

        // make sure this isn't a subclass
        guard self === UIScrollView.self else {
            return
        }
        swizzling(self)
    }

    func swizzle_setBounds(bounds: CGRect) {
        [bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height].forEach() { val in
            if val.isNaN || val.isInfinite {
                Sentry.shared.send(message: "Bad scrollview bounds detected.")
                return
            }
        }

        self.swizzle_setBounds(bounds: bounds)
    }
}
