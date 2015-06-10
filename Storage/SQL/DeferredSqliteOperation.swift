/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private var log = XCGLogger.defaultInstance()
private var DeferredQueue = dispatch_queue_create("BrowserDBQueue", DISPATCH_QUEUE_SERIAL)

/**
    This class is written to mimick an NSOperation, but also provide Deferred capabilities as well.
    
    Usage:
    let deferred = DeferredSqliteOperation({ (db, err) -> Int
      // ... Do something long running
      return 1
    }, withDb: myDb, onQueue: myQueue).start(onQueue: myQueue)
    deferred.upon { res in
      // if cancelled res.isFailure = true
    })

    // ... Some time later
    deferred.cancel()
*/
class DeferredSqliteOperation<T>: Deferred<Result<T>>, Cancellable {
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
    var executingLock = LockProtected<Bool>(item: false)
    var executing: Bool {
        get {
            return self.executingLock.withReadLock({ executing -> Bool in
                return executing
            })
        }
        set {
            executingLock.withWriteLock { executing -> T? in
                executing = newValue
                return nil
            }
        }
    }

    private var db: SwiftData
    private var block: (connection: SQLiteDBConnection, inout err: NSError?) -> T

    init(block: (connection: SQLiteDBConnection, inout err: NSError?) -> T, withDB db: SwiftData) {
        self.block = block
        self.db = db
        super.init()
    }

    func start(onQueue queue: dispatch_queue_t = DeferredQueue) -> DeferredSqliteOperation<T> {
        dispatch_async(queue) {
            self.main()
        }
        return self
    }

    private func main() {
        let start = NSDate.now()
        var result: T? = nil
        var err = db.withConnection(SwiftData.Flags.ReadWriteCreate) { (db) -> NSError? in
            self.executing = true
            if self.cancelled {
                return NSError(domain: "mozilla", code: 9, userInfo: [NSLocalizedDescriptionKey: "Operation was cancelled  before starting"])
            }

            var err: NSError? = nil
            result = self.block(connection: db, err: &err)
            log.debug("Modified rows: \(db.numberOfRowsModified).")
            self.executing = false
            return err
        }
        log.debug("SQL took \(NSDate.now() - start)")

        if let result = result {
            fill(Result(success: result))
        } else {
            fill(Result(failure: DatabaseError(err: err)))
        }
    }

    func cancel() {
        self.cancelled = true
        if executing {
            self.db.interrupt()
        }
    }
}

