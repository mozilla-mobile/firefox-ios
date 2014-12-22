/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/*
 * A simple read-write lock
 */
class Lock {
    let queue: dispatch_queue_t

    init(name: String) {
        queue = dispatch_queue_create(name, DISPATCH_QUEUE_CONCURRENT)
    }

    func withReadLock(closure: () -> Void) {
        dispatch_sync(queue) {
            closure()
        }
    }

    func withWriteLock(closure: () -> Void) {
        dispatch_barrier_sync(queue) {
            closure()
        }
    }
}

/*
 * A convenience class to wrap a locked object. All access to the object must go through
 * blocks passed to this object.
 */
class Protector<T> {
    private let lock : Lock
    private var item: T

    init(name: String, item: T) {
        self.lock = Lock(name: name)
        self.item = item
    }

    func withReadLock(block: (T) -> Void) {
        lock.withReadLock() { [unowned self] in
            block(self.item)
        }
    }

    func withWriteLock(block: (inout T) -> Void) {
        lock.withWriteLock() { [unowned self] in
            block(&self.item)
        }
    }
}
