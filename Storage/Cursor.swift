// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/**
 * Status results for a Cursor
 */
public enum CursorStatus {
    case success
    case failure
    case closed
}

public protocol TypedCursor: Sequence {
    associatedtype T
    var count: Int { get }
    var status: CursorStatus { get }
    var statusMessage: String { get }
    subscript(index: Int) -> T? { get }
    func asArray() -> [T]
}

/**
 * Provides a generic method of returning some data and status information about a request.
 */
open class Cursor<T>: TypedCursor {
    open var count: Int { return 0 }

    // Extra status information
    open var status: CursorStatus
    public var statusMessage: String

    init(err: NSError) {
        self.status = .failure
        self.statusMessage = err.description
    }

    public init(status: CursorStatus = .success, msg: String = "") {
        self.statusMessage = msg
        self.status = status
    }

    // Collection iteration and access functions
    open subscript(index: Int) -> T? { return nil }

    open func asArray() -> [T] {
        var acc = [T]()
        acc.reserveCapacity(self.count)
        for row in self {
            // Shouldn't ever be nil -- that's to allow the generator or subscript to be
            // out of range.
            if let row = row {
                acc.append(row)
            }
        }
        return acc
    }

    open func makeIterator() -> AnyIterator<T?> {
        var nextIndex = 0
        return AnyIterator {
            if nextIndex >= self.count || self.status != CursorStatus.success {
                return nil
            }

            defer { nextIndex += 1 }
            return self[nextIndex]
        }
    }

    open func close() {
        status = .closed
        statusMessage = "Closed"
    }

    deinit {
        if status != CursorStatus.closed {
            close()
        }
    }
}

/*
 * A cursor implementation that wraps an array.
 */
open class ArrayCursor<T>: Cursor<T> {
    fileprivate var data: [T]

    override open var count: Int {
        if status != .success {
            return 0
        }
        return data.count
    }

    public init(data: [T], status: CursorStatus, statusMessage: String) {
        self.data = data
        super.init(status: status, msg: statusMessage)
    }

    public convenience init(data: [T]) {
        self.init(data: data, status: CursorStatus.success, statusMessage: "Success")
    }

    override open subscript(index: Int) -> T? {
        if index >= data.count || index < 0 || status != .success { return nil }
        return data[index]
    }

    override open func close() {
        data = [T]()
        super.close()
    }
}
