//
// SQLite.swift
// https://github.com/stephencelis/SQLite.swift
// Copyright © 2014-2015 Stephen Celis.
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

extension Data : Value {

    public static var declaredDatatype: String {
        return Blob.declaredDatatype
    }

    public static func fromDatatypeValue(_ dataValue: Blob) -> Data {
        return Data(bytes: UnsafePointer<UInt8>(dataValue.bytes), count: dataValue.bytes.count)
    }

    public var datatypeValue: Blob {
        return Blob(bytes: bytes, length: count)
    }

}

extension Date : Value {

    public static var declaredDatatype: String {
        return String.declaredDatatype
    }

    public static func fromDatatypeValue(_ stringValue: String) -> Date {
        return dateFormatter.date(from: stringValue)!
    }

    public var datatypeValue: String {
        return dateFormatter.string(from: self)
    }

}

/// A global date formatter used to serialize and deserialize `NSDate` objects.
/// If multiple date formats are used in an application’s database(s), use a
/// custom `Value` type per additional format.
public var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    formatter.locale = Locale(localeIdentifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(forSecondsFromGMT: 0)
    return formatter
}()

// FIXME: rdar://problem/18673897 // subscript<T>…

extension QueryType {

    public subscript(column: Expression<Data>) -> Expression<Data> {
        return namespace(column)
    }
    public subscript(column: Expression<Data?>) -> Expression<Data?> {
        return namespace(column)
    }

    public subscript(column: Expression<Date>) -> Expression<Date> {
        return namespace(column)
    }
    public subscript(column: Expression<Date?>) -> Expression<Date?> {
        return namespace(column)
    }

}

extension Row {

    public subscript(column: Expression<Data>) -> Data {
        return get(column)
    }
    public subscript(column: Expression<Data?>) -> Data? {
        return get(column)
    }

    public subscript(column: Expression<Date>) -> Date {
        return get(column)
    }
    public subscript(column: Expression<Date?>) -> Date? {
        return get(column)
    }

}
