/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public final class LockProtected<T> {
    private var lock: ReadWriteLock
    private var item: T

    public convenience init(item: T) {
        self.init(item: item, lock: CASSpinLock())
    }

    public init(item: T, lock: ReadWriteLock) {
        self.item = item
        self.lock = lock
    }

    public func withReadLock<U>(block: (T) -> U) -> U {
        return lock.withReadLock { [unowned self] in
            return block(self.item)
        }
    }

    public func withWriteLock<U>(block: (inout T) -> U) -> U {
        return lock.withWriteLock { [unowned self] in
            return block(&self.item)
        }
    }
}
