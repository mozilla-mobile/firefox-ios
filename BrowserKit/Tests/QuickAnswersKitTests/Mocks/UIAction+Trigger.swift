// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension UIAction {
    /// UIKit has no public API to run an action's handler, so the block is read through KVC.
    func trigger() {
        typealias Handler = @convention(block) (UIAction) -> Void
        guard let handler = value(forKey: "handler") else { return }
        unsafeBitCast(handler as AnyObject, to: Handler.self)(self)
    }
}
