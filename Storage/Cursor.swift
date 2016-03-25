/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/**
 * Status results for a Cursor
 */
public enum CursorStatus {
    case Success
    case Failure
    case Closed
}

public protocol TypedCursor: SequenceType {
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
public class Cursor<T>: TypedCursor {
    public var count: Int {
        get { return 0 }
    }

    // Extra status information
    public var status: CursorStatus
    public var statusMessage: String

    init(err: NSError) {
        self.status = .Failure
        self.statusMessage = err.description
    }

    public init(status: CursorStatus = CursorStatus.Success, msg: String = "") {
        self.status = status
        self.statusMessage = msg
    }

    // Collection iteration and access functions
    public subscript(index: Int) -> T? {
        get { return nil }
    }

    public func asArray() -> [T] {
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

    public func generate() -> AnyGenerator<T?> {
        var nextIndex = 0
        return anyGenerator() {
            if (nextIndex >= self.count || self.status != CursorStatus.Success) {
                return nil
            }

            return self[nextIndex++]
        }
    }

    public func close() {
        status = .Closed
        statusMessage = "Closed"
    }

    deinit {
        if status != CursorStatus.Closed {
            close()
        }
    }
}

/*
 * A cursor implementation that wraps an array.
 */
public class ArrayCursor<T> : Cursor<T> {
    private var data : [T]

    public override var count : Int {
        if (status != .Success) {
            return 0
        }
        return data.count
    }

    public init(data: [T], status: CursorStatus, statusMessage: String) {
        self.data = data;
        super.init(status: status, msg: statusMessage)
    }

    public convenience init(data: [T]) {
        self.init(data: data, status: CursorStatus.Success, statusMessage: "Success")
    }

    public override subscript(index: Int) -> T? {
        get {
            if (index >= data.count || index < 0 || status != .Success) {
                return nil
            }
            return data[index]
        }
    }

    override public func close() {
        data = [T]()
        super.close()
    }
}