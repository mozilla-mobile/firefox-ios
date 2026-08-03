// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest

extension XCTestCase {
    /// Depth-first search for the first subview of the given type.
    @MainActor
    func firstSubview<T: UIView>(ofType type: T.Type, in view: UIView?) -> T? {
        guard let view else { return nil }
        for subview in view.subviews {
            if let match = subview as? T { return match }
            if let match = firstSubview(ofType: type, in: subview) { return match }
        }
        return nil
    }

    /// `UIControl.sendActions` needs a running `UIApplication`, which logic tests lack, and it
    /// fails silently. Invoke each registered target/action directly instead. The control is
    /// non-optional so a nil lookup fails at the caller's `XCTUnwrap`, not quietly here.
    @MainActor
    func fireActions(on control: UIControl, for event: UIControl.Event) {
        for target in control.allTargets {
            let object = target as NSObject
            control.actions(forTarget: target, forControlEvent: event)?.forEach {
                object.perform(Selector($0))
            }
        }
    }
}
