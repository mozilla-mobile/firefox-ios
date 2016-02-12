/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import Deferred

private let log = Logger.syncLogger
private let DeferredQueue = dispatch_queue_create("BrowserDBQueue", DISPATCH_QUEUE_SERIAL)

/**
    This class is written to mimick an NSOperation, but also provide Deferred capabilities as well.
    
    Usage:
    let deferred = DeferredDBOperation({ (db, err) -> Int
      // ... Do something long running
      return 1
    }, withDb: myDb, onQueue: myQueue).start(onQueue: myQueue)
    deferred.upon { res in
      // if cancelled res.isFailure = true
    })

    // ... Some time later
    deferred.cancel()
*/
class DeferredDBOperation<T>: Deferred<Maybe<T>>, Cancellable {
    /// Cancelled is wrapping a ReadWrite lock to make access to it thread-safe.
    private var cancelledLock = LockProtected<Bool>(item: false)
    var cancelled: Bool {
        get {
            return self.cancelledLock.withReadLock({ cancelled -> Bool in
                return cancelled
            })
        }
        set {
            cancelledLock.withWriteLock { cancelled -> T? in
                cancelled = newValue
                return nil
            }
        }
    }

    /// Executing is wrapping a ReadWrite lock to make access to it thread-safe.
    private var connectionLock = LockProtected<SQLiteDBConnection?>(item: nil)
    private var connection: SQLiteDBConnection? {
        get {
            // We want to avoid leaking this connection. If you want access to it,
            // you should use a read/write lock directly.
            return nil
        }
        set {
            connectionLock.withWriteLock { connection -> T? in
                connection = newValue
                return nil
            }
        }
    }

    private var db: SwiftData
    private var block: (connection: SQLiteDBConnection, inout err: NSError?) -> T

    init(db: SwiftData, block: (connection: SQLiteDBConnection, inout err: NSError?) -> T) {
        self.block = block
        self.db = db
        super.init()
    }

    func start(onQueue queue: dispatch_queue_t = DeferredQueue) -> DeferredDBOperation<T> {
        dispatch_async(queue, self.main)
        return self
    }

    private func main() {
        if self.cancelled {
            let err = NSError(domain: "mozilla", code: 9, userInfo: [NSLocalizedDescriptionKey: "Operation was cancelled before starting"])
            fill(Maybe(failure: DatabaseError(err: err)))
            return
        }

        var result: T? = nil
        let err = db.withConnection(SwiftData.Flags.ReadWriteCreate) { (db) -> NSError? in
            self.connection = db
            if self.cancelled {
                return NSError(domain: "mozilla", code: 9, userInfo: [NSLocalizedDescriptionKey: "Operation was cancelled before starting"])
            }

            var error: NSError? = nil
            result = self.block(connection: db, err: &error)
            if error == nil {
                log.verbose("Modified rows: \(db.numberOfRowsModified).")
            }
            self.connection = nil
            return error
        }

        if let result = result {
            fill(Maybe(success: result))
            return
        }
        fill(Maybe(failure: DatabaseError(err: err)))
    }

    func cancel() {
        self.cancelled = true
        self.connectionLock.withReadLock({ connection -> () in
            connection?.interrupt()
            return ()
        })
    }
}

