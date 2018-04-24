/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

// Workaround for bug 1417152, whereby NaN bounds are being set on the scrollview when viewing PDFs in the web view.
// Is fixed in WebKit, remove this file when the fix arrives in iOS release.

private let swizzling: (UIScrollView.Type) -> Void = { obj in
    let originalSelector = #selector(setter: UIView.bounds)
    let swizzledSelector = #selector(obj.swizzle_setBounds(bounds:))
    guard let originalMethod = class_getInstanceMethod(obj, originalSelector), let swizzledMethod = class_getInstanceMethod(obj, swizzledSelector) else { return }
    method_exchangeImplementations(originalMethod, swizzledMethod)
}

private var hasSwizzled = false

extension UIScrollView {

    final public class func doBadSwizzleStuff() {
        guard !hasSwizzled else { return }

        hasSwizzled = true
        swizzling(self)
    }

    @objc func swizzle_setBounds(bounds: CGRect) {
        let validSize = [bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height].every({ !$0.isNaN })
        let validBounds = [bounds.size.width, bounds.size.height].every({ $0 >= 0 })

        guard validBounds && validSize && !bounds.isInfinite else {
            Sentry.shared.send(message: "Bad scrollview bounds detected [negative size].")
            return
        }
        self.swizzle_setBounds(bounds: bounds)
    }
}
