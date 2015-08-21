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

/// A typed SQL expression that wraps a raw string and bindings.
public struct Expression<T> {

    public let SQL: String

    public let bindings: [Binding?]

    private var ascending: Bool?

    private var original: Expressible?

    /// Builds an SQL expression with a literal string and an optional list of
    /// bindings.
    ///
    /// :param: SQL      An SQL string.
    ///
    /// :param: bindings Values to be bound to the given SQL.
    public init(literal SQL: String = "", _ bindings: [Binding?] = []) {
        (self.SQL, self.bindings) = (SQL, bindings)
    }

    /// Builds an SQL expression with a quoted identifier.
    ///
    /// :param: identifier An SQL identifier (*e.g.*, a column name).
    public init(_ identifier: String) {
        self.init(literal: quote(identifier: identifier))
    }

    /// Builds an SQL expression with the given value.
    ///
    /// :param: value An encodable SQL value.
    public init<V: Value>(value: V?) {
        self.init(binding: value?.datatypeValue)
    }

    /// Builds an SQL expression with the given value.
    ///
    /// :param: binding A raw SQL value.
    internal init(binding: Binding?) {
        self.init(literal: "?", [binding])
    }

    /// Returns an ascending sort version of the expression.
    public var asc: Expression {
        var expression = self
        expression.ascending = true
        return expression
    }

    /// Returns an descending sort version of the expression.
    public var desc: Expression {
        var expression = self
        expression.ascending = false
        return expression
    }

    /// Returns an aliased version of the expression using AS. The expression is
    /// expanded contextually (e.g., in SELECT clauses).
    public func alias(alias: String) -> Expression {
        return self.alias(Expression(alias))
    }

    private func alias(alias: Expression) -> Expression {
        var expression = Expression(alias)
        expression.original = self
        return expression
    }

    internal static func join(separator: String, _ expressions: [Expressible]) -> Expression<()> {
        var (SQL, bindings) = ([String](), [Binding?]())
        for expressible in expressions {
            let expression = expressible.expression
            SQL.append(expression.SQL)
            bindings.extend(expression.bindings)
        }
        return Expression<()>(literal: Swift.join(separator, SQL), bindings)
    }

    internal init<V>(_ expression: Expression<V>) {
        self.init(literal: expression.SQL, expression.bindings)
        (ascending, original) = (expression.ascending, expression.original)
    }

    internal var ordered: Expression<()> {
        if let ascending = ascending {
            return Expression.join(" ", [self, Expression(literal: ascending ? "ASC" : "DESC")])
        }
        return Expression<()>(self)
    }

    internal var aliased: Expression {
        if let aliased = original?.expression {
            return Expression(literal: "(\(aliased.SQL)) AS \(SQL)", aliased.bindings + bindings)
        }
        return self
    }

    internal var unaliased: Expression {
        return original.map { Expression($0.expression) } ?? self
    }

    internal func reverse() -> Expression {
        var expression = self
        expression.ascending = expression.ascending.map(!) ?? false
        return expression
    }

    // naïve compiler for statements that can't be bound, e.g., CREATE TABLE
    internal func compile() -> String {
        var idx = 0
        return reduce(SQL, "") { SQL, character in
            let string = String(character)
            return SQL + (string == "?" ? transcode(self.bindings[idx++]) : string)
        }
    }

}

public protocol Expressible {

    var expression: Expression<()> { get }

}

extension Blob: Expressible {

    public var expression: Expression<()> {
        return Expression(binding: self)
    }

}

extension Bool: Expressible {

    public var expression: Expression<()> {
        return Expression(value: self)
    }

}

extension Double: Expressible {

    public var expression: Expression<()> {
        return Expression(binding: self)
    }

}

extension Int: Expressible {

    public var expression: Expression<()> {
        // FIXME: rdar://TODO segfaults during archive // return Expression(value: self)
        return Expression(binding: datatypeValue)
    }

}

extension Int64: Expressible {

    public var expression: Expression<()> {
        return Expression(binding: self)
    }

}

extension String: Expressible {

    public var expression: Expression<()> {
        return Expression(binding: self)
    }

}

extension Expression: Expressible {

    public var expression: Expression<()> {
        return Expression<()>(self)
    }

}

extension Query: Expressible {

    public var expression: Expression<()> {
        if tableName.original != nil {
            return selectExpression.alias(tableName)
        }
        return wrap("", selectExpression)
    }

}

// MARK: - Expressions

public func + (lhs: Expression<String>, rhs: Expression<String>) -> Expression<String> { return infix("||", lhs, rhs) }
public func + (lhs: Expression<String>, rhs: Expression<String?>) -> Expression<String?> { return infix("||", lhs, rhs) }
public func + (lhs: Expression<String?>, rhs: Expression<String>) -> Expression<String?> { return infix("||", lhs, rhs) }
public func + (lhs: Expression<String?>, rhs: Expression<String?>) -> Expression<String?> { return infix("||", lhs, rhs) }
public func + (lhs: Expression<String>, rhs: String) -> Expression<String> { return lhs + Expression(binding: rhs) }
public func + (lhs: Expression<String?>, rhs: String) -> Expression<String?> { return lhs + Expression(binding: rhs) }
public func + (lhs: String, rhs: Expression<String>) -> Expression<String> { return Expression(binding: lhs) + rhs }
public func + (lhs: String, rhs: Expression<String?>) -> Expression<String?> { return Expression(binding: lhs) + rhs }

public func + <V: Value where V.Datatype: Number>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> { return infix(__FUNCTION__, lhs, rhs) }
public func + <V: Value where V.Datatype: Number>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func + <V: Value where V.Datatype: Number>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func + <V: Value where V.Datatype: Number>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func + <V: Value where V.Datatype: Number>(lhs: Expression<V>, rhs: V) -> Expression<V> { return lhs + Expression(value: rhs) }
public func + <V: Value where V.Datatype: Number>(lhs: Expression<V?>, rhs: V) -> Expression<V?> { return lhs + Expression(value: rhs) }
public func + <V: Value where V.Datatype: Number>(lhs: V, rhs: Expression<V>) -> Expression<V> { return Expression(value: lhs) + rhs }
public func + <V: Value where V.Datatype: Number>(lhs: V, rhs: Expression<V?>) -> Expression<V?> { return Expression(value: lhs) + rhs }

public func - <V: Value where V.Datatype: Number>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> { return infix(__FUNCTION__, lhs, rhs) }
public func - <V: Value where V.Datatype: Number>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func - <V: Value where V.Datatype: Number>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func - <V: Value where V.Datatype: Number>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func - <V: Value where V.Datatype: Number>(lhs: Expression<V>, rhs: V) -> Expression<V> { return lhs - Expression(value: rhs) }
public func - <V: Value where V.Datatype: Number>(lhs: Expression<V?>, rhs: V) -> Expression<V?> { return lhs - Expression(value: rhs) }
public func - <V: Value where V.Datatype: Number>(lhs: V, rhs: Expression<V>) -> Expression<V> { return Expression(value: lhs) - rhs }
public func - <V: Value where V.Datatype: Number>(lhs: V, rhs: Expression<V?>) -> Expression<V?> { return Expression(value: lhs) - rhs }

public func * <V: Value where V.Datatype: Number>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> { return infix(__FUNCTION__, lhs, rhs) }
public func * <V: Value where V.Datatype: Number>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func * <V: Value where V.Datatype: Number>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func * <V: Value where V.Datatype: Number>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func * <V: Value where V.Datatype: Number>(lhs: Expression<V>, rhs: V) -> Expression<V> { return lhs * Expression(value: rhs) }
public func * <V: Value where V.Datatype: Number>(lhs: Expression<V?>, rhs: V) -> Expression<V?> { return lhs * Expression(value: rhs) }
public func * <V: Value where V.Datatype: Number>(lhs: V, rhs: Expression<V>) -> Expression<V> { return Expression(value: lhs) * rhs }
public func * <V: Value where V.Datatype: Number>(lhs: V, rhs: Expression<V?>) -> Expression<V?> { return Expression(value: lhs) * rhs }

public func / <V: Value where V.Datatype: Number>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> { return infix(__FUNCTION__, lhs, rhs) }
public func / <V: Value where V.Datatype: Number>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func / <V: Value where V.Datatype: Number>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func / <V: Value where V.Datatype: Number>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func / <V: Value where V.Datatype: Number>(lhs: Expression<V>, rhs: V) -> Expression<V> { return lhs / Expression(value: rhs) }
public func / <V: Value where V.Datatype: Number>(lhs: Expression<V?>, rhs: V) -> Expression<V?> { return lhs / Expression(value: rhs) }
public func / <V: Value where V.Datatype: Number>(lhs: V, rhs: Expression<V>) -> Expression<V> { return Expression(value: lhs) / rhs }
public func / <V: Value where V.Datatype: Number>(lhs: V, rhs: Expression<V?>) -> Expression<V?> { return Expression(value: lhs) / rhs }

public func % <V: Value where V.Datatype == Int64>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> { return infix(__FUNCTION__, lhs, rhs) }
public func % <V: Value where V.Datatype == Int64>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func % <V: Value where V.Datatype == Int64>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func % <V: Value where V.Datatype == Int64>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func % <V: Value where V.Datatype == Int64>(lhs: Expression<V>, rhs: V) -> Expression<V> { return lhs % Expression(value: rhs) }
public func % <V: Value where V.Datatype == Int64>(lhs: Expression<V?>, rhs: V) -> Expression<V?> { return lhs % Expression(value: rhs) }
public func % <V: Value where V.Datatype == Int64>(lhs: V, rhs: Expression<V>) -> Expression<V> { return Expression(value: lhs) % rhs }
public func % <V: Value where V.Datatype == Int64>(lhs: V, rhs: Expression<V?>) -> Expression<V?> { return Expression(value: lhs) % rhs }

public func << <V: Value where V.Datatype == Int64>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> { return infix(__FUNCTION__, lhs, rhs) }
public func << <V: Value where V.Datatype == Int64>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func << <V: Value where V.Datatype == Int64>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func << <V: Value where V.Datatype == Int64>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func << <V: Value where V.Datatype == Int64>(lhs: Expression<V>, rhs: V) -> Expression<V> { return lhs << Expression(value: rhs) }
public func << <V: Value where V.Datatype == Int64>(lhs: Expression<V?>, rhs: V) -> Expression<V?> { return lhs << Expression(value: rhs) }
public func << <V: Value where V.Datatype == Int64>(lhs: V, rhs: Expression<V>) -> Expression<V> { return Expression(value: lhs) << rhs }
public func << <V: Value where V.Datatype == Int64>(lhs: V, rhs: Expression<V?>) -> Expression<V?> { return Expression(value: lhs) << rhs }

public func >> <V: Value where V.Datatype == Int64>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> { return infix(__FUNCTION__, lhs, rhs) }
public func >> <V: Value where V.Datatype == Int64>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func >> <V: Value where V.Datatype == Int64>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func >> <V: Value where V.Datatype == Int64>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func >> <V: Value where V.Datatype == Int64>(lhs: Expression<V>, rhs: V) -> Expression<V> { return lhs >> Expression(value: rhs) }
public func >> <V: Value where V.Datatype == Int64>(lhs: Expression<V?>, rhs: V) -> Expression<V?> { return lhs >> Expression(value: rhs) }
public func >> <V: Value where V.Datatype == Int64>(lhs: V, rhs: Expression<V>) -> Expression<V> { return Expression(value: lhs) >> rhs }
public func >> <V: Value where V.Datatype == Int64>(lhs: V, rhs: Expression<V?>) -> Expression<V?> { return Expression(value: lhs) >> rhs }

public func & <V: Value where V.Datatype == Int64>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> { return infix(__FUNCTION__, lhs, rhs) }
public func & <V: Value where V.Datatype == Int64>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func & <V: Value where V.Datatype == Int64>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func & <V: Value where V.Datatype == Int64>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func & <V: Value where V.Datatype == Int64>(lhs: Expression<V>, rhs: V) -> Expression<V> { return lhs & Expression(value: rhs) }
public func & <V: Value where V.Datatype == Int64>(lhs: Expression<V?>, rhs: V) -> Expression<V?> { return lhs & Expression(value: rhs) }
public func & <V: Value where V.Datatype == Int64>(lhs: V, rhs: Expression<V>) -> Expression<V> { return Expression(value: lhs) & rhs }
public func & <V: Value where V.Datatype == Int64>(lhs: V, rhs: Expression<V?>) -> Expression<V?> { return Expression(value: lhs) & rhs }

public func | <V: Value where V.Datatype == Int64>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> { return infix(__FUNCTION__, lhs, rhs) }
public func | <V: Value where V.Datatype == Int64>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func | <V: Value where V.Datatype == Int64>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func | <V: Value where V.Datatype == Int64>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> { return infix(__FUNCTION__, lhs, rhs) }
public func | <V: Value where V.Datatype == Int64>(lhs: Expression<V>, rhs: V) -> Expression<V> { return lhs | Expression(value: rhs) }
public func | <V: Value where V.Datatype == Int64>(lhs: Expression<V?>, rhs: V) -> Expression<V?> { return lhs | Expression(value: rhs) }
public func | <V: Value where V.Datatype == Int64>(lhs: V, rhs: Expression<V>) -> Expression<V> { return Expression(value: lhs) | rhs }
public func | <V: Value where V.Datatype == Int64>(lhs: V, rhs: Expression<V?>) -> Expression<V?> { return Expression(value: lhs) | rhs }

public func ^ <V: Value where V.Datatype == Int64>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<V> { return (~(lhs & rhs)) & (lhs | rhs) }
public func ^ <V: Value where V.Datatype == Int64>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<V?> { return (~(lhs & rhs)) & (lhs | rhs) }
public func ^ <V: Value where V.Datatype == Int64>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<V?> { return (~(lhs & rhs)) & (lhs | rhs) }
public func ^ <V: Value where V.Datatype == Int64>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<V?> { return (~(lhs & rhs)) & (lhs | rhs) }
public func ^ <V: Value where V.Datatype == Int64>(lhs: Expression<V>, rhs: V) -> Expression<V> { return lhs ^ Expression(value: rhs) }
public func ^ <V: Value where V.Datatype == Int64>(lhs: Expression<V?>, rhs: V) -> Expression<V?> { return lhs ^ Expression(value: rhs) }
public func ^ <V: Value where V.Datatype == Int64>(lhs: V, rhs: Expression<V>) -> Expression<V> { return Expression(value: lhs) ^ rhs }
public func ^ <V: Value where V.Datatype == Int64>(lhs: V, rhs: Expression<V?>) -> Expression<V?> { return Expression(value: lhs) ^ rhs }

public prefix func ~ <V: Value where V.Datatype == Int64>(rhs: Expression<V>) -> Expression<V> { return wrap(__FUNCTION__, rhs) }
public prefix func ~ <V: Value where V.Datatype == Int64>(rhs: Expression<V?>) -> Expression<V?> { return wrap(__FUNCTION__, rhs) }

public enum Collation {

    case Binary

    case Nocase

    case Rtrim

    case Custom(String)

}

extension Collation: Printable {

    public var description: String {
        switch self {
        case Binary:
            return "BINARY"
        case Nocase:
            return "NOCASE"
        case Rtrim:
            return "RTRIM"
        case Custom(let collation):
            return collation
        }
    }

}

public func collate(collation: Collation, expression: Expression<String>) -> Expression<String> {
    return infix("COLLATE", expression, Expression<String>(collation.description))
}
public func collate(collation: Collation, expression: Expression<String?>) -> Expression<String?> {
    return infix("COLLATE", expression, Expression<String>(collation.description))
}

public func cast<T: Value, U: Value>(expression: Expression<T>) -> Expression<U> {
    return Expression(literal: "CAST (\(expression.SQL) AS \(U.declaredDatatype))", expression.bindings)
}
public func cast<T: Value, U: Value>(expression: Expression<T?>) -> Expression<U?> {
    return Expression(literal: "CAST (\(expression.SQL) AS \(U.declaredDatatype))", expression.bindings)
}

// MARK: - Predicates

public func == <V: Value where V.Datatype: Equatable>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<Bool> {
    return infix("=", lhs, rhs)
}
public func == <V: Value where V.Datatype: Equatable>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix("=", lhs, rhs)
}
public func == <V: Value where V.Datatype: Equatable>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<Bool?> {
    return infix("=", lhs, rhs)
}
public func == <V: Value where V.Datatype: Equatable>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix("=", lhs, rhs)
}
public func == <V: Value where V.Datatype: Equatable>(lhs: Expression<V>, rhs: V) -> Expression<Bool> {
    return lhs == Expression(value: rhs)
}
public func == <V: Value where V.Datatype: Equatable>(lhs: Expression<V?>, rhs: V?) -> Expression<Bool?> {
    if let rhs = rhs { return lhs == Expression(value: rhs) }
    return Expression(literal: "\(lhs.SQL) IS ?", lhs.bindings + [nil])
}
public func == <V: Value where V.Datatype: Equatable>(lhs: V, rhs: Expression<V>) -> Expression<Bool> {
    return Expression(value: lhs) == rhs
}
public func == <V: Value where V.Datatype: Equatable>(lhs: V?, rhs: Expression<V?>) -> Expression<Bool?> {
    if let lhs = lhs { return Expression(value: lhs) == rhs }
    return Expression(literal: "? IS \(rhs.SQL)", [nil] + rhs.bindings)
}

public func != <V: Value where V.Datatype: Equatable>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<Bool> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func != <V: Value where V.Datatype: Equatable>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func != <V: Value where V.Datatype: Equatable>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func != <V: Value where V.Datatype: Equatable>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func != <V: Value where V.Datatype: Equatable>(lhs: Expression<V>, rhs: V) -> Expression<Bool> {
    return lhs != Expression(value: rhs)
}
public func != <V: Value where V.Datatype: Equatable>(lhs: Expression<V?>, rhs: V?) -> Expression<Bool?> {
    if let rhs = rhs { return lhs != Expression(value: rhs) }
    return Expression(literal: "\(lhs.SQL) IS NOT ?", lhs.bindings + [nil])
}
public func != <V: Value where V.Datatype: Equatable>(lhs: V, rhs: Expression<V>) -> Expression<Bool> {
    return Expression(value: lhs) != rhs
}
public func != <V: Value where V.Datatype: Equatable>(lhs: V?, rhs: Expression<V?>) -> Expression<Bool?> {
    if let lhs = lhs { return Expression(value: lhs) != rhs }
    return Expression(literal: "? IS NOT \(rhs.SQL)", [nil] + rhs.bindings)
}

public func > <V: Value where V.Datatype: Comparable>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<Bool> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func > <V: Value where V.Datatype: Comparable>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func > <V: Value where V.Datatype: Comparable>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func > <V: Value where V.Datatype: Comparable>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func > <V: Value where V.Datatype: Comparable>(lhs: Expression<V>, rhs: V) -> Expression<Bool> {
    return lhs > Expression(value: rhs)
}
public func > <V: Value where V.Datatype: Comparable>(lhs: Expression<V?>, rhs: V) -> Expression<Bool?> {
    return lhs > Expression(value: rhs)
}
public func > <V: Value where V.Datatype: Comparable>(lhs: V, rhs: Expression<V>) -> Expression<Bool> {
    return Expression(value: lhs) > rhs
}
public func > <V: Value where V.Datatype: Comparable>(lhs: V, rhs: Expression<V?>) -> Expression<Bool?> {
    return Expression(value: lhs) > rhs
}

public func >= <V: Value where V.Datatype: Comparable>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<Bool> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func >= <V: Value where V.Datatype: Comparable>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func >= <V: Value where V.Datatype: Comparable>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func >= <V: Value where V.Datatype: Comparable>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func >= <V: Value where V.Datatype: Comparable>(lhs: Expression<V>, rhs: V) -> Expression<Bool> {
    return lhs >= Expression(value: rhs)
}
public func >= <V: Value where V.Datatype: Comparable>(lhs: Expression<V?>, rhs: V) -> Expression<Bool?> {
    return lhs >= Expression(value: rhs)
}
public func >= <V: Value where V.Datatype: Comparable>(lhs: V, rhs: Expression<V>) -> Expression<Bool> {
    return Expression(value: lhs) >= rhs
}
public func >= <V: Value where V.Datatype: Comparable>(lhs: V, rhs: Expression<V?>) -> Expression<Bool?> {
    return Expression(value: lhs) >= rhs
}

public func < <V: Value where V.Datatype: Comparable>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<Bool> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func < <V: Value where V.Datatype: Comparable>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func < <V: Value where V.Datatype: Comparable>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func < <V: Value where V.Datatype: Comparable>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func < <V: Value where V.Datatype: Comparable>(lhs: Expression<V>, rhs: V) -> Expression<Bool> {
    return lhs < Expression(value: rhs)
}
public func < <V: Value where V.Datatype: Comparable>(lhs: Expression<V?>, rhs: V) -> Expression<Bool?> {
    return lhs < Expression(value: rhs)
}
public func < <V: Value where V.Datatype: Comparable>(lhs: V, rhs: Expression<V>) -> Expression<Bool> {
    return Expression(value: lhs) < rhs
}
public func < <V: Value where V.Datatype: Comparable>(lhs: V, rhs: Expression<V?>) -> Expression<Bool?> {
    return Expression(value: lhs) < rhs
}

public func <= <V: Value where V.Datatype: Comparable>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<Bool> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func <= <V: Value where V.Datatype: Comparable>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func <= <V: Value where V.Datatype: Comparable>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func <= <V: Value where V.Datatype: Comparable>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<Bool?> {
    return infix(__FUNCTION__, lhs, rhs)
}
public func <= <V: Value where V.Datatype: Comparable>(lhs: Expression<V>, rhs: V) -> Expression<Bool> {
    return lhs <= Expression(value: rhs)
}
public func <= <V: Value where V.Datatype: Comparable>(lhs: Expression<V?>, rhs: V) -> Expression<Bool?> {
    return lhs <= Expression(value: rhs)
}
public func <= <V: Value where V.Datatype: Comparable>(lhs: V, rhs: Expression<V>) -> Expression<Bool> {
    return Expression(value: lhs) <= rhs
}
public func <= <V: Value where V.Datatype: Comparable>(lhs: V, rhs: Expression<V?>) -> Expression<Bool?> {
    return Expression(value: lhs) <= rhs
}

public prefix func - <V: Value where V.Datatype: Number>(rhs: Expression<V>) -> Expression<V> { return wrap(__FUNCTION__, rhs) }
public prefix func - <V: Value where V.Datatype: Number>(rhs: Expression<V?>) -> Expression<V?> { return wrap(__FUNCTION__, rhs) }

public func ~= <I: IntervalType, V: Value where V.Datatype: protocol<Binding, Comparable>, V.Datatype == I.Bound>(lhs: I, rhs: Expression<V>) -> Expression<Bool> {
    return Expression(literal: "\(rhs.SQL) BETWEEN ? AND ?", rhs.bindings + [lhs.start, lhs.end])
}
public func ~= <I: IntervalType, V: Value where V.Datatype: protocol<Binding, Comparable>, V.Datatype == I.Bound>(lhs: I, rhs: Expression<V?>) -> Expression<Bool?> {
    return Expression<Bool?>(lhs ~= Expression<V>(rhs))
}

// MARK: Operators

public func like(string: String, expression: Expression<String>) -> Expression<Bool> {
    return infix("LIKE", expression, Expression<String>(binding: string))
}
public func like(string: String, expression: Expression<String?>) -> Expression<Bool?> {
    return infix("LIKE", expression, Expression<String>(binding: string))
}

public func glob(string: String, expression: Expression<String>) -> Expression<Bool> {
    return infix("GLOB", expression, Expression<String>(binding: string))
}
public func glob(string: String, expression: Expression<String?>) -> Expression<Bool?> {
    return infix("GLOB", expression, Expression<String>(binding: string))
}

public func match(string: String, expression: Expression<String>) -> Expression<Bool> {
    return infix("MATCH", expression, Expression<String>(binding: string))
}
public func match(string: String, expression: Expression<String?>) -> Expression<Bool?> {
    return infix("MATCH", expression, Expression<String>(binding: string))
}

// MARK: Compound

public func && (lhs: Expression<Bool>, rhs: Expression<Bool>) -> Expression<Bool> { return infix("AND", lhs, rhs) }
public func && (lhs: Expression<Bool>, rhs: Expression<Bool?>) -> Expression<Bool?> { return infix("AND", lhs, rhs) }
public func && (lhs: Expression<Bool?>, rhs: Expression<Bool>) -> Expression<Bool?> { return infix("AND", lhs, rhs) }
public func && (lhs: Expression<Bool?>, rhs: Expression<Bool?>) -> Expression<Bool?> { return infix("AND", lhs, rhs) }
public func && (lhs: Expression<Bool>, rhs: Bool) -> Expression<Bool> { return lhs && Expression(value: rhs) }
public func && (lhs: Expression<Bool?>, rhs: Bool) -> Expression<Bool?> { return lhs && Expression(value: rhs) }
public func && (lhs: Bool, rhs: Expression<Bool>) -> Expression<Bool> { return Expression(value: lhs) && rhs }
public func && (lhs: Bool, rhs: Expression<Bool?>) -> Expression<Bool?> { return Expression(value: lhs) && rhs }

public func || (lhs: Expression<Bool>, rhs: Expression<Bool>) -> Expression<Bool> { return infix("OR", lhs, rhs) }
public func || (lhs: Expression<Bool>, rhs: Expression<Bool?>) -> Expression<Bool?> { return infix("OR", lhs, rhs) }
public func || (lhs: Expression<Bool?>, rhs: Expression<Bool>) -> Expression<Bool?> { return infix("OR", lhs, rhs) }
public func || (lhs: Expression<Bool?>, rhs: Expression<Bool?>) -> Expression<Bool?> { return infix("OR", lhs, rhs) }
public func || (lhs: Expression<Bool>, rhs: Bool) -> Expression<Bool> { return lhs || Expression(value: rhs) }
public func || (lhs: Expression<Bool?>, rhs: Bool) -> Expression<Bool?> { return lhs || Expression(value: rhs) }
public func || (lhs: Bool, rhs: Expression<Bool>) -> Expression<Bool> { return Expression(value: lhs) || rhs }
public func || (lhs: Bool, rhs: Expression<Bool?>) -> Expression<Bool?> { return Expression(value: lhs) || rhs }

public prefix func ! (rhs: Expression<Bool>) -> Expression<Bool> { return wrap("NOT ", rhs) }
public prefix func ! (rhs: Expression<Bool?>) -> Expression<Bool?> { return wrap("NOT ", rhs) }

// MARK: - Core Functions

public func abs<V: Value where V.Datatype: Number>(expression: Expression<V>) -> Expression<V> { return wrap(__FUNCTION__, expression) }
public func abs<V: Value where V.Datatype: Number>(expression: Expression<V?>) -> Expression<V?> { return wrap(__FUNCTION__, expression) }

// FIXME: support Expression<V?>..., Expression<V> when Swift supports inner variadic signatures
public func coalesce<V>(expressions: Expression<V?>...) -> Expression<V?> {
    return wrap(__FUNCTION__, Expression<()>.join(", ", expressions.map { $0 } as [Expressible]))
}

public func ifnull<V: Expressible>(expression: Expression<V?>, defaultValue: V) -> Expression<V> {
    return wrap(__FUNCTION__, Expression<()>.join(", ", [expression, defaultValue]))
}
public func ifnull<V: Expressible>(expression: Expression<V?>, defaultValue: Expression<V>) -> Expression<V> {
    return wrap(__FUNCTION__, Expression<()>.join(", ", [expression, defaultValue]))
}
public func ifnull<V: Expressible>(expression: Expression<V?>, defaultValue: Expression<V?>) -> Expression<V> {
    return wrap(__FUNCTION__, Expression<()>.join(", ", [expression, defaultValue]))
}
public func ?? <V: Expressible>(expression: Expression<V?>, defaultValue: V) -> Expression<V> {
    return ifnull(expression, defaultValue)
}
public func ?? <V: Expressible>(expression: Expression<V?>, defaultValue: Expression<V>) -> Expression<V> {
    return ifnull(expression, defaultValue)
}
public func ?? <V: Expressible>(expression: Expression<V?>, defaultValue: Expression<V?>) -> Expression<V> {
    return ifnull(expression, defaultValue)
}

public func length<V: Value>(expression: Expression<V>) -> Expression<Int> { return wrap(__FUNCTION__, expression) }
public func length<V: Value>(expression: Expression<V?>) -> Expression<Int?> { return wrap(__FUNCTION__, expression) }

public func lower(expression: Expression<String>) -> Expression<String> { return wrap(__FUNCTION__, expression) }
public func lower(expression: Expression<String?>) -> Expression<String?> { return wrap(__FUNCTION__, expression) }

public func ltrim(expression: Expression<String>) -> Expression<String> { return wrap(__FUNCTION__, expression) }
public func ltrim(expression: Expression<String?>) -> Expression<String?> { return wrap(__FUNCTION__, expression) }

public func ltrim(expression: Expression<String>, characters: String) -> Expression<String> {
    return wrap(__FUNCTION__, Expression<()>.join(", ", [expression, characters]))
}
public func ltrim(expression: Expression<String?>, characters: String) -> Expression<String?> {
    return wrap(__FUNCTION__, Expression<()>.join(", ", [expression, characters]))
}

public func random() -> Expression<Int> { return Expression(literal: __FUNCTION__) }

public func replace(expression: Expression<String>, match: String, subtitute: String) -> Expression<String> {
    return wrap(__FUNCTION__, Expression<()>.join(", ", [expression, match, subtitute]))
}
public func replace(expression: Expression<String?>, match: String, subtitute: String) -> Expression<String?> {
    return wrap(__FUNCTION__, Expression<()>.join(", ", [expression, match, subtitute]))
}

public func round(expression: Expression<Double>) -> Expression<Double> { return wrap(__FUNCTION__, expression) }
public func round(expression: Expression<Double?>) -> Expression<Double?> { return wrap(__FUNCTION__, expression) }
public func round(expression: Expression<Double>, precision: Int) -> Expression<Double> {
    return wrap(__FUNCTION__, Expression<()>.join(", ", [expression, precision]))
}
public func round(expression: Expression<Double?>, precision: Int) -> Expression<Double?> {
    return wrap(__FUNCTION__, Expression<()>.join(", ", [expression, precision]))
}

public func rtrim(expression: Expression<String>) -> Expression<String> { return wrap(__FUNCTION__, expression) }
public func rtrim(expression: Expression<String?>) -> Expression<String?> { return wrap(__FUNCTION__, expression) }
public func rtrim(expression: Expression<String>, characters: String) -> Expression<String> {
    return wrap(__FUNCTION__, Expression<()>.join(", ", [expression, characters]))
}
public func rtrim(expression: Expression<String?>, characters: String) -> Expression<String?> {
    return wrap(__FUNCTION__, Expression<()>.join(", ", [expression, characters]))
}

public func substr(expression: Expression<String>, startIndex: Int) -> Expression<String> {
    return wrap(__FUNCTION__, Expression<()>.join(", ", [expression, startIndex]))
}
public func substr(expression: Expression<String?>, startIndex: Int) -> Expression<String?> {
    return wrap(__FUNCTION__, Expression<()>.join(", ", [expression, startIndex]))
}

public func substr(expression: Expression<String>, position: Int, length: Int) -> Expression<String> {
    return wrap(__FUNCTION__, Expression<()>.join(", ", [expression, position, length]))
}
public func substr(expression: Expression<String?>, position: Int, length: Int) -> Expression<String?> {
    return wrap(__FUNCTION__, Expression<()>.join(", ", [expression, position, length]))
}

public func substr(expression: Expression<String>, subRange: Range<Int>) -> Expression<String> {
    return substr(expression, subRange.startIndex, subRange.endIndex - subRange.startIndex)
}
public func substr(expression: Expression<String?>, subRange: Range<Int>) -> Expression<String?> {
    return substr(expression, subRange.startIndex, subRange.endIndex - subRange.startIndex)
}

public func trim(expression: Expression<String>) -> Expression<String> { return wrap(__FUNCTION__, expression) }
public func trim(expression: Expression<String?>) -> Expression<String?> { return wrap(__FUNCTION__, expression) }
public func trim(expression: Expression<String>, characters: String) -> Expression<String> {
    return wrap(__FUNCTION__, Expression<()>.join(", ", [expression, characters]))
}
public func trim(expression: Expression<String?>, characters: String) -> Expression<String?> {
    return wrap(__FUNCTION__, Expression<()>.join(", ", [expression, characters]))
}

public func upper(expression: Expression<String>) -> Expression<String> { return wrap(__FUNCTION__, expression) }
public func upper(expression: Expression<String?>) -> Expression<String?> { return wrap(__FUNCTION__, expression) }

// MARK: - Aggregate Functions

public func count<V: Value>(expression: Expression<V?>) -> Expression<Int> { return wrap(__FUNCTION__, expression) }

public func count<V: Value>(#distinct: Expression<V>) -> Expression<Int> { return wrapDistinct("count", distinct) }
public func count<V: Value>(#distinct: Expression<V?>) -> Expression<Int> { return wrapDistinct("count", distinct) }

public func count(star: Star) -> Expression<Int> { return wrap(__FUNCTION__, star(nil, nil)) }

public func max<V: Value where V.Datatype: Comparable>(expression: Expression<V>) -> Expression<V?> {
    return wrap(__FUNCTION__, expression)
}
public func max<V: Value where V.Datatype: Comparable>(expression: Expression<V?>) -> Expression<V?> {
    return wrap(__FUNCTION__, expression)
}

public func min<V: Value where V.Datatype: Comparable>(expression: Expression<V>) -> Expression<V?> {
    return wrap(__FUNCTION__, expression)
}
public func min<V: Value where V.Datatype: Comparable>(expression: Expression<V?>) -> Expression<V?> {
    return wrap(__FUNCTION__, expression)
}

public func average<V: Value where V.Datatype: Number>(expression: Expression<V>) -> Expression<Double?> { return wrap("avg", expression) }
public func average<V: Value where V.Datatype: Number>(expression: Expression<V?>) -> Expression<Double?> { return wrap("avg", expression) }

public func average<V: Value where V.Datatype: Number>(#distinct: Expression<V>) -> Expression<Double?> { return wrapDistinct("avg", distinct) }
public func average<V: Value where V.Datatype: Number>(#distinct: Expression<V?>) -> Expression<Double?> { return wrapDistinct("avg", distinct) }

public func sum<V: Value where V.Datatype: Number>(expression: Expression<V>) -> Expression<V?> { return wrap(__FUNCTION__, expression) }
public func sum<V: Value where V.Datatype: Number>(expression: Expression<V?>) -> Expression<V?> { return wrap(__FUNCTION__, expression) }

public func sum<V: Value where V.Datatype: Number>(#distinct: Expression<V>) -> Expression<V?> { return wrapDistinct("sum", distinct) }
public func sum<V: Value where V.Datatype: Number>(#distinct: Expression<V?>) -> Expression<V?> { return wrapDistinct("sum", distinct) }

public func total<V: Value where V.Datatype: Number>(expression: Expression<V>) -> Expression<Double> { return wrap(__FUNCTION__, expression) }
public func total<V: Value where V.Datatype: Number>(expression: Expression<V?>) -> Expression<Double> { return wrap(__FUNCTION__, expression) }

public func total<V: Value where V.Datatype: Number>(#distinct: Expression<V>) -> Expression<Double> { return wrapDistinct("total", distinct) }
public func total<V: Value where V.Datatype: Number>(#distinct: Expression<V?>) -> Expression<Double> { return wrapDistinct("total", distinct) }

internal func SQLite_count<V: Value>(expression: Expression<V?>) -> Expression<Int> { return count(expression) }

internal func SQLite_count<V: Value>(#distinct: Expression<V>) -> Expression<Int> { return count(distinct: distinct) }
internal func SQLite_count<V: Value>(#distinct: Expression<V?>) -> Expression<Int> { return count(distinct: distinct) }

internal func SQLite_count(star: Star) -> Expression<Int> { return count(star) }

internal func SQLite_max<V: Value where V.Datatype: Comparable>(expression: Expression<V>) -> Expression<V?> {
    return max(expression)
}
internal func SQLite_max<V: Value where V.Datatype: Comparable>(expression: Expression<V?>) -> Expression<V?> {
    return max(expression)
}

internal func SQLite_min<V: Value where V.Datatype: Comparable>(expression: Expression<V>) -> Expression<V?> {
    return min(expression)
}
internal func SQLite_min<V: Value where V.Datatype: Comparable>(expression: Expression<V?>) -> Expression<V?> {
    return min(expression)
}

internal func SQLite_average<V: Value where V.Datatype: Number>(expression: Expression<V>) -> Expression<Double?> { return average(expression) }
internal func SQLite_average<V: Value where V.Datatype: Number>(expression: Expression<V?>) -> Expression<Double?> { return average(expression) }

internal func SQLite_average<V: Value where V.Datatype: Number>(#distinct: Expression<V>) -> Expression<Double?> { return average(distinct: distinct) }
internal func SQLite_average<V: Value where V.Datatype: Number>(#distinct: Expression<V?>) -> Expression<Double?> { return average(distinct: distinct) }

internal func SQLite_sum<V: Value where V.Datatype: Number>(expression: Expression<V>) -> Expression<V?> { return sum(expression) }
internal func SQLite_sum<V: Value where V.Datatype: Number>(expression: Expression<V?>) -> Expression<V?> { return sum(expression) }

internal func SQLite_sum<V: Value where V.Datatype: Number>(#distinct: Expression<V>) -> Expression<V?> { return sum(distinct: distinct) }
internal func SQLite_sum<V: Value where V.Datatype: Number>(#distinct: Expression<V?>) -> Expression<V?> { return sum(distinct: distinct) }

internal func SQLite_total<V: Value where V.Datatype: Number>(expression: Expression<V>) -> Expression<Double> { return total(expression) }
internal func SQLite_total<V: Value where V.Datatype: Number>(expression: Expression<V?>) -> Expression<Double> { return total(expression) }

internal func SQLite_total<V: Value where V.Datatype: Number>(#distinct: Expression<V>) -> Expression<Double> { return total(distinct: distinct) }
internal func SQLite_total<V: Value where V.Datatype: Number>(#distinct: Expression<V?>) -> Expression<Double> { return total(distinct: distinct) }

private func wrapDistinct<V, U>(function: String, expression: Expression<V>) -> Expression<U> {
    return wrap(function, Expression<()>.join(" ", [Expression<()>(literal: "DISTINCT"), expression]))
}

// MARK: - Helper

public typealias Star = (Expression<Binding>?, Expression<Binding>?) -> Expression<()>

public func * (Expression<Binding>?, Expression<Binding>?) -> Expression<()> {
    return Expression(literal: "*")
}
public func contains<V: Value, C: CollectionType where C.Generator.Element == V, C.Index.Distance == Int>(values: C, column: Expression<V>) -> Expression<Bool> {
    let templates = join(", ", [String](count: count(values), repeatedValue: "?"))
    return infix("IN", column, Expression<V>(literal: "(\(templates))", map(values) { $0.datatypeValue }))
}
public func contains<V: Value, C: CollectionType where C.Generator.Element == V, C.Index.Distance == Int>(values: C, column: Expression<V?>) -> Expression<Bool> {
    return contains(values, Expression<V>(column))
}
public func contains<V: Value>(values: Query, column: Expression<V>) -> Expression<Bool> {
    return infix("IN", column, wrap("", values.selectExpression) as Expression<()>)
}

// MARK: - Modifying

/// A pair of expressions used to set values in INSERT and UPDATE statements.
public typealias Setter = (Expressible, Expressible)

/// Returns a setter to be used with INSERT and UPDATE statements.
///
/// :param: column The column being set.
///
/// :param: value  The value the column is being set to.
///
/// :returns: A setter that can be used in a Query's insert and update
///           functions.
public func set<V: Value>(column: Expression<V>, value: V) -> Setter {
    return (column, Expression<()>(value: value))
}
public func set<V: Value>(column: Expression<V?>, value: V?) -> Setter {
    return (column, Expression<()>(value: value))
}
public func set<V: Value>(column: Expression<V>, value: Expression<V>) -> Setter { return (column, value) }
public func set<V: Value>(column: Expression<V>, value: Expression<V?>) -> Setter { return (column, value) }
public func set<V: Value>(column: Expression<V?>, value: Expression<V>) -> Setter { return (column, value) }
public func set<V: Value>(column: Expression<V?>, value: Expression<V?>) -> Setter { return (column, value) }

infix operator <- { associativity left precedence 140 }
public func <- <V: Value>(column: Expression<V>, value: Expression<V>) -> Setter { return set(column, value) }
public func <- <V: Value>(column: Expression<V>, value: Expression<V?>) -> Setter { return set(column, value) }
public func <- <V: Value>(column: Expression<V?>, value: Expression<V>) -> Setter { return set(column, value) }
public func <- <V: Value>(column: Expression<V?>, value: Expression<V?>) -> Setter { return set(column, value) }
public func <- <V: Value>(column: Expression<V>, value: V) -> Setter { return set(column, value) }
public func <- <V: Value>(column: Expression<V?>, value: V?) -> Setter { return set(column, value) }

public func += (column: Expression<String>, value: Expression<String>) -> Setter { return set(column, column + value) }
public func += (column: Expression<String>, value: Expression<String?>) -> Setter { return set(column, column + value) }
public func += (column: Expression<String?>, value: Expression<String>) -> Setter { return set(column, column + value) }
public func += (column: Expression<String?>, value: Expression<String?>) -> Setter { return set(column, column + value) }
public func += (column: Expression<String>, value: String) -> Setter { return set(column, column + value) }
public func += (column: Expression<String?>, value: String) -> Setter { return set(column, column + value) }

public func += <V: Value where V.Datatype: Number>(column: Expression<V>, value: Expression<V>) -> Setter {
    return set(column, column + value)
}
public func += <V: Value where V.Datatype: Number>(column: Expression<V>, value: Expression<V?>) -> Setter {
    return set(column, column + value)
}
public func += <V: Value where V.Datatype: Number>(column: Expression<V?>, value: Expression<V>) -> Setter {
    return set(column, column + value)
}
public func += <V: Value where V.Datatype: Number>(column: Expression<V?>, value: Expression<V?>) -> Setter {
    return set(column, column + value)
}
public func += <V: Value where V.Datatype: Number>(column: Expression<V>, value: V) -> Setter { return set(column, column + value) }
public func += <V: Value where V.Datatype: Number>(column: Expression<V?>, value: V) -> Setter { return set(column, column + value) }

public func -= <V: Value where V.Datatype: Number>(column: Expression<V>, value: Expression<V>) -> Setter {
    return set(column, column - value)
}
public func -= <V: Value where V.Datatype: Number>(column: Expression<V>, value: Expression<V?>) -> Setter {
    return set(column, column - value)
}
public func -= <V: Value where V.Datatype: Number>(column: Expression<V?>, value: Expression<V>) -> Setter {
    return set(column, column - value)
}
public func -= <V: Value where V.Datatype: Number>(column: Expression<V?>, value: Expression<V?>) -> Setter {
    return set(column, column - value)
}
public func -= <V: Value where V.Datatype: Number>(column: Expression<V>, value: V) -> Setter { return set(column, column - value) }
public func -= <V: Value where V.Datatype: Number>(column: Expression<V?>, value: V) -> Setter { return set(column, column - value) }

public func *= <V: Value where V.Datatype: Number>(column: Expression<V>, value: Expression<V>) -> Setter {
    return set(column, column * value)
}
public func *= <V: Value where V.Datatype: Number>(column: Expression<V>, value: Expression<V?>) -> Setter {
    return set(column, column * value)
}
public func *= <V: Value where V.Datatype: Number>(column: Expression<V?>, value: Expression<V>) -> Setter {
    return set(column, column * value)
}
public func *= <V: Value where V.Datatype: Number>(column: Expression<V?>, value: Expression<V?>) -> Setter {
    return set(column, column * value)
}
public func *= <V: Value where V.Datatype: Number>(column: Expression<V>, value: V) -> Setter { return set(column, column * value) }
public func *= <V: Value where V.Datatype: Number>(column: Expression<V?>, value: V) -> Setter { return set(column, column * value) }

public func /= <V: Value where V.Datatype: Number>(column: Expression<V>, value: Expression<V>) -> Setter {
    return set(column, column / value)
}
public func /= <V: Value where V.Datatype: Number>(column: Expression<V>, value: Expression<V?>) -> Setter {
    return set(column, column / value)
}
public func /= <V: Value where V.Datatype: Number>(column: Expression<V?>, value: Expression<V>) -> Setter {
    return set(column, column / value)
}
public func /= <V: Value where V.Datatype: Number>(column: Expression<V?>, value: Expression<V?>) -> Setter {
    return set(column, column / value)
}
public func /= <V: Value where V.Datatype: Number>(column: Expression<V>, value: V) -> Setter {
    return set(column, column / value)
}
public func /= <V: Value where V.Datatype: Number>(column: Expression<V?>, value: V) -> Setter {
    return set(column, column / value)
}

public func %= <V: Value where V.Datatype == Int64>(column: Expression<V>, value: Expression<V>) -> Setter { return set(column, column % value) }
public func %= <V: Value where V.Datatype == Int64>(column: Expression<V>, value: Expression<V?>) -> Setter { return set(column, column % value) }
public func %= <V: Value where V.Datatype == Int64>(column: Expression<V?>, value: Expression<V>) -> Setter { return set(column, column % value) }
public func %= <V: Value where V.Datatype == Int64>(column: Expression<V?>, value: Expression<V?>) -> Setter { return set(column, column % value) }
public func %= <V: Value where V.Datatype == Int64>(column: Expression<V>, value: V) -> Setter { return set(column, column % value) }
public func %= <V: Value where V.Datatype == Int64>(column: Expression<V?>, value: V) -> Setter { return set(column, column % value) }

public func <<= <V: Value where V.Datatype == Int64>(column: Expression<V>, value: Expression<V>) -> Setter { return set(column, column << value) }
public func <<= <V: Value where V.Datatype == Int64>(column: Expression<V>, value: Expression<V?>) -> Setter { return set(column, column << value) }
public func <<= <V: Value where V.Datatype == Int64>(column: Expression<V?>, value: Expression<V>) -> Setter { return set(column, column << value) }
public func <<= <V: Value where V.Datatype == Int64>(column: Expression<V?>, value: Expression<V?>) -> Setter { return set(column, column << value) }
public func <<= <V: Value where V.Datatype == Int64>(column: Expression<V>, value: V) -> Setter { return set(column, column << value) }
public func <<= <V: Value where V.Datatype == Int64>(column: Expression<V?>, value: V) -> Setter { return set(column, column << value) }

public func >>= <V: Value where V.Datatype == Int64>(column: Expression<V>, value: Expression<V>) -> Setter { return set(column, column >> value) }
public func >>= <V: Value where V.Datatype == Int64>(column: Expression<V>, value: Expression<V?>) -> Setter { return set(column, column >> value) }
public func >>= <V: Value where V.Datatype == Int64>(column: Expression<V?>, value: Expression<V>) -> Setter { return set(column, column >> value) }
public func >>= <V: Value where V.Datatype == Int64>(column: Expression<V?>, value: Expression<V?>) -> Setter { return set(column, column >> value) }
public func >>= <V: Value where V.Datatype == Int64>(column: Expression<V>, value: V) -> Setter { return set(column, column >> value) }
public func >>= <V: Value where V.Datatype == Int64>(column: Expression<V?>, value: V) -> Setter { return set(column, column >> value) }

public func &= <V: Value where V.Datatype == Int64>(column: Expression<V>, value: Expression<V>) -> Setter { return set(column, column & value) }
public func &= <V: Value where V.Datatype == Int64>(column: Expression<V>, value: Expression<V?>) -> Setter { return set(column, column & value) }
public func &= <V: Value where V.Datatype == Int64>(column: Expression<V?>, value: Expression<V>) -> Setter { return set(column, column & value) }
public func &= <V: Value where V.Datatype == Int64>(column: Expression<V?>, value: Expression<V?>) -> Setter { return set(column, column & value) }
public func &= <V: Value where V.Datatype == Int64>(column: Expression<V>, value: V) -> Setter { return set(column, column & value) }
public func &= <V: Value where V.Datatype == Int64>(column: Expression<V?>, value: V) -> Setter { return set(column, column & value) }

public func |= <V: Value where V.Datatype == Int64>(column: Expression<V>, value: Expression<V>) -> Setter { return set(column, column | value) }
public func |= <V: Value where V.Datatype == Int64>(column: Expression<V>, value: Expression<V?>) -> Setter { return set(column, column | value) }
public func |= <V: Value where V.Datatype == Int64>(column: Expression<V?>, value: Expression<V>) -> Setter { return set(column, column | value) }
public func |= <V: Value where V.Datatype == Int64>(column: Expression<V?>, value: Expression<V?>) -> Setter { return set(column, column | value) }
public func |= <V: Value where V.Datatype == Int64>(column: Expression<V>, value: V) -> Setter { return set(column, column | value) }
public func |= <V: Value where V.Datatype == Int64>(column: Expression<V?>, value: V) -> Setter { return set(column, column | value) }

public func ^= <V: Value where V.Datatype == Int64>(column: Expression<V>, value: Expression<V>) -> Setter { return set(column, column ^ value) }
public func ^= <V: Value where V.Datatype == Int64>(column: Expression<V>, value: Expression<V?>) -> Setter { return set(column, column ^ value) }
public func ^= <V: Value where V.Datatype == Int64>(column: Expression<V?>, value: Expression<V>) -> Setter { return set(column, column ^ value) }
public func ^= <V: Value where V.Datatype == Int64>(column: Expression<V?>, value: Expression<V?>) -> Setter { return set(column, column ^ value) }
public func ^= <V: Value where V.Datatype == Int64>(column: Expression<V>, value: V) -> Setter { return set(column, column ^ value) }
public func ^= <V: Value where V.Datatype == Int64>(column: Expression<V?>, value: V) -> Setter { return set(column, column ^ value) }

public postfix func ++ <V: Value where V.Datatype == Int64>(column: Expression<V>) -> Setter { return Expression<Int>(column) += 1 }
public postfix func ++ <V: Value where V.Datatype == Int64>(column: Expression<V?>) -> Setter { return Expression<Int>(column) += 1 }
public postfix func -- <V: Value where V.Datatype == Int64>(column: Expression<V>) -> Setter { return Expression<Int>(column) -= 1 }
public postfix func -- <V: Value where V.Datatype == Int64>(column: Expression<V?>) -> Setter { return Expression<Int>(column) -= 1 }

// MARK: - Internal

internal let rowid = Expression<Int64>("ROWID")

internal func transcode(literal: Binding?) -> String {
    if let literal = literal {
        if let literal = literal as? Blob { return literal.description }
        if let literal = literal as? String { return quote(literal: literal) }
        return "\(literal)"
    }
    return "NULL"
}

internal func wrap<T, U>(function: String, expression: Expression<T>) -> Expression<U> {
    return Expression(literal: "\(function)\(surround(expression.SQL))", expression.bindings)
}

internal func infix<T, U, V>(function: String, lhs: Expression<T>, rhs: Expression<U>) -> Expression<V> {
    return Expression(literal: surround("\(lhs.SQL) \(function) \(rhs.SQL)"), lhs.bindings + rhs.bindings)
}

private func surround(expression: String) -> String { return "(\(expression))" }
