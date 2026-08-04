// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension UIPasteboard {
    /// Preferred way to read the pasteboard's string contents. Reading `string` blocks the calling
    /// thread on an IPC (Inter-process communication) call that can wait on the paste consent alert or a Universal Clipboard
    /// fetch, so it is never done on the main thread.
    ///
    /// - Parameter completion: Called off the main thread. Hop back to it before touching UI.
    nonisolated public func asyncString(completion: @Sendable @escaping (String?) -> Void) {
        Task(priority: .medium) { completion(self.string) }
    }
}
