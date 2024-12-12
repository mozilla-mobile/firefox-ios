// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

open class CancellableDeferred<T>: Deferred<T> {
    public var dispatchWorkItem: DispatchWorkItem?

    internal var _running = false
    internal var _cancelled = false

    open func cancel() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        let queue = OperationQueue.current?.underlyingQueue
        queue?.suspend()
        defer { queue?.resume() }

        dispatchWorkItem?.cancel()
        _cancelled = true
    }

    open var cancelled: Bool {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        return _cancelled
    }

    open var running: Bool {
        get {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            return _running
        }
        set {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            _running = newValue
        }
    }

    override open func fill(_ value: T) {
        defer {
            dispatchWorkItem = nil
        }

        guard !cancelled else { return }

        super.fill(value)
    }
}
