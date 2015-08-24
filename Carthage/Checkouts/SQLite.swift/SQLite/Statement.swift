//
// SQLite.swift
// https://github.com/stephencelis/SQLite.swift
// Copyright (c) 2014-2015 Stephen Celis.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import sqlite3

internal let SQLITE_STATIC = sqlite3_destructor_type(COpaquePointer(bitPattern: 0))
internal let SQLITE_TRANSIENT = sqlite3_destructor_type(COpaquePointer(bitPattern: -1))

/// A single SQL statement.
public final class Statement {

    private var handle: COpaquePointer = nil

    private let database: Database

    public lazy var row: Cursor = { Cursor(self) }()

    internal init(_ database: Database, _ SQL: String) {
        self.database = database
        database.try { sqlite3_prepare_v2(database.handle, SQL, -1, &self.handle, nil) }
    }

    deinit { sqlite3_finalize(handle) }

    public lazy var columnCount: Int = { Int(sqlite3_column_count(self.handle)) }()

    public lazy var columnNames: [String] = {
        (0..<Int32(self.columnCount)).map { String.fromCString(sqlite3_column_name(self.handle, $0))! }
    }()

    // MARK: - Binding

    /// Binds a list of parameters to a statement.
    ///
    /// :param: values A list of parameters to bind to the statement.
    ///
    /// :returns: The statement object (useful for chaining).
    public func bind(values: Binding?...) -> Statement {
        return bind(values)
    }

    /// Binds a list of parameters to a statement.
    ///
    /// :param: values A list of parameters to bind to the statement.
    ///
    /// :returns: The statement object (useful for chaining).
    public func bind(values: [Binding?]) -> Statement {
        if values.isEmpty { return self }
        reset()
        assert(values.count == Int(sqlite3_bind_parameter_count(handle)), "\(sqlite3_bind_parameter_count(handle)) values expected, \(values.count) passed")
        for idx in 1...values.count { bind(values[idx - 1], atIndex: idx) }
        return self
    }

    /// Binds a dictionary of named parameters to a statement.
    ///
    /// :param: values A dictionary of named parameters to bind to the
    ///                statement.
    ///
    /// :returns: The statement object (useful for chaining).
    public func bind(values: [String: Binding?]) -> Statement {
        reset()
        for (name, value) in values {
            let idx = sqlite3_bind_parameter_index(handle, name)
            assert(idx > 0, "parameter not found: \(name)")
            bind(value, atIndex: Int(idx))
        }
        return self
    }

    private func bind(value: Binding?, atIndex idx: Int) {
        if value == nil {
            try { sqlite3_bind_null(self.handle, Int32(idx)) }
        } else if let value = value as? Blob {
            try { sqlite3_bind_blob(self.handle, Int32(idx), value.bytes, Int32(value.length), SQLITE_TRANSIENT) }
        } else if let value = value as? Double {
            try { sqlite3_bind_double(self.handle, Int32(idx), value) }
        } else if let value = value as? Int64 {
            try { sqlite3_bind_int64(self.handle, Int32(idx), value) }
        } else if let value = value as? String {
            try { sqlite3_bind_text(self.handle, Int32(idx), value, -1, SQLITE_TRANSIENT) }
        } else if let value = value as? Bool {
            bind(value.datatypeValue, atIndex: idx)
        } else if let value = value as? Int {
            bind(value.datatypeValue, atIndex: idx)
        } else if let value = value {
            fatalError("tried to bind unexpected value \(value)")
        }
    }

    // MARK: - Run

    /// :param: bindings A list of parameters to bind to the statement.
    ///
    /// :returns: The statement object (useful for chaining).
    public func run(bindings: Binding?...) -> Statement {
        if !bindings.isEmpty { return run(bindings) }
        reset(clearBindings: false)
        while step() {}
        return self
    }

    /// :param: bindings A list of parameters to bind to the statement.
    ///
    /// :returns: The statement object (useful for chaining).
    public func run(bindings: [Binding?]) -> Statement {
        return bind(bindings).run()
    }

    /// :param: bindings A dictionary of named parameters to bind to the
    ///                  statement.
    ///
    /// :returns: The statement object (useful for chaining).
    public func run(bindings: [String: Binding?]) -> Statement {
        return bind(bindings).run()
    }

    // MARK: - Scalar

    /// :param: bindings A list of parameters to bind to the statement.
    ///
    /// :returns: The first value of the first row returned.
    public func scalar(bindings: Binding?...) -> Binding? {
        if !bindings.isEmpty { return scalar(bindings) }
        reset(clearBindings: false)
        step()
        return row[0]
    }

    /// :param: bindings A list of parameters to bind to the statement.
    ///
    /// :returns: The first value of the first row returned.
    public func scalar(bindings: [Binding?]) -> Binding? {
        return bind(bindings).scalar()
    }

    /// :param: bindings A dictionary of named parameters to bind to the
    ///                  statement.
    ///
    /// :returns: The first value of the first row returned.
    public func scalar(bindings: [String: Binding?]) -> Binding? {
        return bind(bindings).scalar()
    }

    // MARK: -

    public func step() -> Bool {
        try { sqlite3_step(self.handle) }
        return status == SQLITE_ROW
    }

    private func reset(clearBindings: Bool = true) {
        (status, reason) = (SQLITE_OK, nil)
        sqlite3_reset(handle)
        if (clearBindings) { sqlite3_clear_bindings(handle) }
    }

    // MARK: - Error Handling

    /// :returns: Whether or not a statement has produced an error.
    public var failed: Bool {
        return !(status == SQLITE_OK || status == SQLITE_ROW || status == SQLITE_DONE)
    }

    /// :returns: The reason for an error.
    public var reason: String?

    private var status: Int32 = SQLITE_OK

    private func try(block: () -> Int32) {
        if failed { return }
        database.perform {
            self.status = block()
            if self.failed {
                self.reason = String.fromCString(sqlite3_errmsg(self.database.handle))
                assert(self.status == SQLITE_CONSTRAINT || self.status == SQLITE_INTERRUPT, "\(self.reason!)")
            }
        }
    }

}

// MARK: - SequenceType
extension Statement: SequenceType {

    public func generate() -> Statement {
        reset(clearBindings: false)
        return self
    }

}

// MARK: - GeneratorType
extension Statement: GeneratorType {

    /// :returns: The next row from the result set (or nil).
    public func next() -> [Binding?]? {
        return step() ? Array(row) : nil
    }

}

// MARK: - Printable
extension Statement: Printable {

    public var description: String {
        return String.fromCString(sqlite3_sql(handle))!
    }

}

public func && (lhs: Statement, @autoclosure rhs: () -> Statement) -> Statement {
    if lhs.status == SQLITE_OK { lhs.run() }
    return lhs.failed ? lhs : rhs()
}

public func || (lhs: Statement, @autoclosure rhs: () -> Statement) -> Statement {
    if lhs.status == SQLITE_OK { lhs.run() }
    return lhs.failed ? rhs() : lhs
}

/// Cursors provide direct access to a statement's current row.
public struct Cursor {

    private let handle: COpaquePointer

    private let columnCount: Int

    private init(_ statement: Statement) {
        handle = statement.handle
        columnCount = statement.columnCount
    }

    public subscript(idx: Int) -> Blob {
        let bytes = sqlite3_column_blob(handle, Int32(idx))
        let length = sqlite3_column_bytes(handle, Int32(idx))
        return Blob(bytes: bytes, length: Int(length))
    }

    public subscript(idx: Int) -> Double {
        return sqlite3_column_double(handle, Int32(idx))
    }

    public subscript(idx: Int) -> Int64 {
        return sqlite3_column_int64(handle, Int32(idx))
    }

    public subscript(idx: Int) -> String {
        return String.fromCString(UnsafePointer(sqlite3_column_text(handle, Int32(idx)))) ?? ""
    }

    public subscript(idx: Int) -> Bool {
        return Bool.fromDatatypeValue(self[idx])
    }

    public subscript(idx: Int) -> Int {
        return Int.fromDatatypeValue(self[idx])
    }

}

// MARK: - SequenceType
extension Cursor: SequenceType {

    public subscript(idx: Int) -> Binding? {
        switch sqlite3_column_type(handle, Int32(idx)) {
        case SQLITE_BLOB:
            return self[idx] as Blob
        case SQLITE_FLOAT:
            return self[idx] as Double
        case SQLITE_INTEGER:
            return self[idx] as Int64
        case SQLITE_NULL:
            return nil
        case SQLITE_TEXT:
            return self[idx] as String
        case let type:
            fatalError("unsupported column type: \(type)")
        }
    }

    public func generate() -> GeneratorOf<Binding?> {
        var idx = 0
        return GeneratorOf {
            idx >= self.columnCount ? Optional<Binding?>.None : self[idx++]
        }
    }

}
