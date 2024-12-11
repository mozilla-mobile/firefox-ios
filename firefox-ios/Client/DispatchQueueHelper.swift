// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// Only push the task async if we are not already on the main thread.
// Unless you want another event to fire before your work happens.
// This is better than using DispatchQueue.main.async to ensure main thread
func ensureMainThread(execute work: @escaping @convention(block) () -> Swift.Void) {
    if Thread.isMainThread {
        work()
    } else {
        DispatchQueue.main.async {
            work()
        }
    }
}

func ensureMainThread<T>(execute work: @escaping () -> T) {
    if Thread.isMainThread {
        _ = work()
    } else {
        DispatchQueue.main.async {
            _ = work()
        }
    }
}
