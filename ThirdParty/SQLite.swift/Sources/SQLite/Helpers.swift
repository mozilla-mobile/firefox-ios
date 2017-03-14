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

#if SQLITE_SWIFT_STANDALONE
import sqlite3
#elseif SQLITE_SWIFT_SQLCIPHER
import SQLCipher
#else
import CSQLite
#endif

public typealias Star = (Expression<Binding>?, Expression<Binding>?) -> Expression<Void>

public func *(_: Expression<Binding>?, _: Expression<Binding>?) -> Expression<Void> {
    return Expression(literal: "*")
}

public protocol _OptionalType {

    associatedtype WrappedType

}

extension Optional : _OptionalType {

    public typealias WrappedType = Wrapped

}

// let SQLITE_STATIC = unsafeBitCast(0, sqlite3_destructor_type.self)
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

extension String {

    func quote(_ mark: Character = "\"") -> String {
        let escaped = characters.reduce("") { string, character in
            string + (character == mark ? "\(mark)\(mark)" : "\(character)")
        }
        return "\(mark)\(escaped)\(mark)"
    }

    func join(_ expressions: [Expressible]) -> Expressible {
        var (template, bindings) = ([String](), [Binding?]())
        for expressible in expressions {
            let expression = expressible.expression
            template.append(expression.template)
            bindings.append(contentsOf: expression.bindings)
        }
        return Expression<Void>(template.joined(separator: self), bindings)
    }

    func infix<T>(_ lhs: Expressible, _ rhs: Expressible, wrap: Bool = true) -> Expression<T> {
        let expression = Expression<T>(" \(self) ".join([lhs, rhs]).expression)
        guard wrap else {
            return expression
        }
        return "".wrap(expression)
    }

    func prefix(_ expressions: Expressible) -> Expressible {
        return "\(self) ".wrap(expressions) as Expression<Void>
    }

    func prefix(_ expressions: [Expressible]) -> Expressible {
        return "\(self) ".wrap(expressions) as Expression<Void>
    }

    func wrap<T>(_ expression: Expressible) -> Expression<T> {
        return Expression("\(self)(\(expression.expression.template))", expression.expression.bindings)
    }

    func wrap<T>(_ expressions: [Expressible]) -> Expression<T> {
        return wrap(", ".join(expressions))
    }

}

func infix<T>(_ lhs: Expressible, _ rhs: Expressible, wrap: Bool = true, function: String = #function) -> Expression<T> {
    return function.infix(lhs, rhs, wrap: wrap)
}

func wrap<T>(_ expression: Expressible, function: String = #function) -> Expression<T> {
    return function.wrap(expression)
}

func wrap<T>(_ expressions: [Expressible], function: String = #function) -> Expression<T> {
    return function.wrap(", ".join(expressions))
}

func transcode(_ literal: Binding?) -> String {
    guard let literal = literal else { return "NULL" }

    switch literal {
    case let blob as Blob:
        return blob.description
    case let string as String:
        return string.quote("'")
    case let binding:
        return "\(binding)"
    }
}

func value<A: Value>(_ v: Binding) -> A {
    return A.fromDatatypeValue(v as! A.Datatype) as! A
}

func value<A: Value>(_ v: Binding?) -> A {
    return value(v!)
}
