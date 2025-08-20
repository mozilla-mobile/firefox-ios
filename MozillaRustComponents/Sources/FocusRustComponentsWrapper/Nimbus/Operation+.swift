/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public extension Operation {
    /// Wait for the operation to finish, or a timeout.
    ///
    /// The operation is cooperatively cancelled on timeout, that is to say, it checks its {isCancelled}.
    func joinOrTimeout(timeout: TimeInterval) -> Bool {
        if isFinished {
            return !isCancelled
        }
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: timeout)
            if !self.isFinished {
                self.cancel()
            }
        }

        waitUntilFinished()
        return !isCancelled
    }
}
