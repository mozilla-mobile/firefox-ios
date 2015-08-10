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

import Foundation

/// Binding is a protocol that SQLite.swift uses internally to directly map
/// SQLite types to Swift types.
///
/// Do not conform custom types to the Binding protocol. See the Value protocol,
/// instead.
public protocol Binding {}

public protocol Number: Binding {}

public protocol Value {

    typealias ValueType = Self

    typealias Datatype: Binding

    static var declaredDatatype: String { get }

    static func fromDatatypeValue(datatypeValue: Datatype) -> ValueType

    var datatypeValue: Datatype { get }

}

public struct Blob {

    private let data: NSData

    public var bytes: UnsafePointer<()> {
        return data.bytes
    }

    public var length: Int {
        return data.length
    }

    public init(bytes: UnsafePointer<()>, length: Int) {
        data = NSData(bytes: bytes, length: length)
    }

}

extension Blob: Equatable {}

public func ==(lhs: Blob, rhs: Blob) -> Bool {
    return lhs.data == rhs.data
}

extension Blob: Binding, Value {

    public static var declaredDatatype = "BLOB"

    public static func fromDatatypeValue(datatypeValue: Blob) -> Blob {
        return datatypeValue
    }

    public var datatypeValue: Blob {
        return self
    }

}

extension Blob: Printable {

    public var description: String {
        let buf = UnsafeBufferPointer(start: UnsafePointer<UInt8>(bytes), count: length)
        let hex = join("", map(buf) { String(format: "%02x", $0) })
        return "x'\(hex)'"
    }

}

extension Double: Number, Value {

    public static var declaredDatatype = "REAL"

    public static func fromDatatypeValue(datatypeValue: Double) -> Double {
        return datatypeValue
    }

    public var datatypeValue: Double {
        return self
    }

}

extension Int64: Number, Value {

    public static var declaredDatatype = "INTEGER"

    public static func fromDatatypeValue(datatypeValue: Int64) -> Int64 {
        return datatypeValue
    }

    public var datatypeValue: Int64 {
        return self
    }

}

extension String: Binding, Value {

    public static var declaredDatatype = "TEXT"

    public static func fromDatatypeValue(datatypeValue: String) -> String {
        return datatypeValue
    }

    public var datatypeValue: String {
        return self
    }

}

// MARK: -

extension Bool: Binding, Value {

    public static var declaredDatatype = Int64.declaredDatatype

    public static func fromDatatypeValue(datatypeValue: Int64) -> Bool {
        return datatypeValue != 0
    }

    public var datatypeValue: Int64 {
        return self ? 1 : 0
    }

}

extension Int: Binding, Value {

    public static var declaredDatatype = Int64.declaredDatatype

    public static func fromDatatypeValue(datatypeValue: Int64) -> Int {
        return Int(datatypeValue)
    }

    public var datatypeValue: Int64 {
        return Int64(self)
    }

}
