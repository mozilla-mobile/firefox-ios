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

public extension Database {

    // MARK: - Type-Safe Function Creation Shims

    // MARK: 0 Arguments

    /// Creates or redefines a custom SQL function.
    ///
    /// :param: function The name of the function to create or redefine.
    ///
    /// :param: block    A block of code to run when the function is called.
    ///                  The assigned types must be explicit.
    ///
    /// :returns: A closure returning an SQL expression to call the function.
    public func create<Z: Value>(#function: String, deterministic: Bool = false, _ block: () -> Z) -> (() -> Expression<Z>) {
        return { self.create(function, 0, deterministic) { _ in return block() }([]) }
    }

    public func create<Z: Value>(#function: String, deterministic: Bool = false, _ block: () -> Z?) -> (() -> Expression<Z?>) {
        return { self.create(function, 0, deterministic) { _ in return block() }([]) }
    }

    // MARK: 1 Argument

    public func create<Z: Value, A: Value>(#function: String, deterministic: Bool = false, _ block: A -> Z) -> (Expression<A> -> Expression<Z>) {
        return { self.create(function, 1, deterministic) { block(asValue($0[0])) }([$0]) }
    }

    public func create<Z: Value, A: Value>(#function: String, deterministic: Bool = false, _ block: A? -> Z) -> (Expression<A?> -> Expression<Z>) {
        return { self.create(function, 1, deterministic) { block($0[0].map(asValue)) }([$0]) }
    }

    public func create<Z: Value, A: Value>(#function: String, deterministic: Bool = false, _ block: A -> Z?) -> (Expression<A> -> Expression<Z?>) {
        return { self.create(function, 1, deterministic) { block(asValue($0[0])) }([$0]) }
    }

    public func create<Z: Value, A: Value>(#function: String, deterministic: Bool = false, _ block: A? -> Z?) -> (Expression<A?> -> Expression<Z?>) {
        return { self.create(function, 1, deterministic) { block($0[0].map(asValue)) }([$0]) }
    }

    // MARK: 2 Arguments

    public func create<Z: Value, A: protocol<Value, Expressible>, B: Value>(#function: String, deterministic: Bool = false, _ block: (A, B) -> Z) -> ((A, Expression<B>) -> Expression<Z>) {
        return { self.create(function, 2, deterministic) { block(asValue($0[0]), asValue($0[1])) }([$0, $1]) }
    }

    public func create<Z: Value, A: protocol<Value, Expressible>, B: Value>(#function: String, deterministic: Bool = false, _ block: (A?, B) -> Z) -> ((A?, Expression<B>) -> Expression<Z>) {
        return { self.create(function, 2, deterministic) { block($0[0].map(asValue), asValue($0[1])) }([Expression<A?>(value: $0), $1]) }
    }

    public func create<Z: Value, A: protocol<Value, Expressible>, B: Value>(#function: String, deterministic: Bool = false, _ block: (A, B?) -> Z) -> ((A, Expression<B?>) -> Expression<Z>) {
        return { self.create(function, 2, deterministic) { block(asValue($0[0]), $0[1].map(asValue)) }([$0, $1]) }
    }

    public func create<Z: Value, A: protocol<Value, Expressible>, B: Value>(#function: String, deterministic: Bool = false, _ block: (A?, B?) -> Z) -> ((A?, Expression<B?>) -> Expression<Z>) {
        return { self.create(function, 2, deterministic) { block($0[0].map(asValue), $0[1].map(asValue)) }([Expression<A?>(value: $0), $1]) }
    }

    public func create<Z: Value, A: protocol<Value, Expressible>, B: Value>(#function: String, deterministic: Bool = false, _ block: (A, B) -> Z?) -> ((A, Expression<B>) -> Expression<Z?>) {
        return { self.create(function, 2, deterministic) { block(asValue($0[0]), asValue($0[1])) }([$0, $1]) }
    }

    public func create<Z: Value, A: protocol<Value, Expressible>, B: Value>(#function: String, deterministic: Bool = false, _ block: (A?, B) -> Z?) -> ((A?, Expression<B>) -> Expression<Z?>) {
        return { self.create(function, 2, deterministic) { block($0[0].map(asValue), asValue($0[1])) }([Expression<A?>(value: $0), $1]) }
    }

    public func create<Z: Value, A: protocol<Value, Expressible>, B: Value>(#function: String, deterministic: Bool = false, _ block: (A, B?) -> Z?) -> ((A, Expression<B?>) -> Expression<Z?>) {
        return { self.create(function, 2, deterministic) { block(asValue($0[0]), $0[1].map(asValue)) }([$0, $1]) }
    }

    public func create<Z: Value, A: protocol<Value, Expressible>, B: Value>(#function: String, deterministic: Bool = false, _ block: (A?, B?) -> Z?) -> ((A?, Expression<B?>) -> Expression<Z?>) {
        return { self.create(function, 2, deterministic) { block($0[0].map(asValue), $0[1].map(asValue)) }([Expression<A?>(value: $0), $1]) }
    }

    public func create<Z: Value, A: Value, B: Value>(#function: String, deterministic: Bool = false, _ block: (A, B) -> Z) -> ((Expression<A>, Expression<B>) -> Expression<Z>) {
        return { self.create(function, 2, deterministic) { block(asValue($0[0]), asValue($0[1])) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: Value>(#function: String, deterministic: Bool = false, _ block: (A?, B) -> Z) -> ((Expression<A?>, Expression<B>) -> Expression<Z>) {
        return { self.create(function, 2, deterministic) { block($0[0].map(asValue), asValue($0[1])) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: Value>(#function: String, deterministic: Bool = false, _ block: (A, B?) -> Z) -> ((Expression<A>, Expression<B?>) -> Expression<Z>) {
        return { self.create(function, 2, deterministic) { block(asValue($0[0]), $0[1].map(asValue)) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: Value>(#function: String, deterministic: Bool = false, _ block: (A?, B?) -> Z) -> ((Expression<A?>, Expression<B?>) -> Expression<Z>) {
        return { self.create(function, 2, deterministic) { block($0[0].map(asValue), $0[1].map(asValue)) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: Value>(#function: String, deterministic: Bool = false, _ block: (A, B) -> Z?) -> ((Expression<A>, Expression<B>) -> Expression<Z?>) {
        return { self.create(function, 2, deterministic) { block(asValue($0[0]), asValue($0[1])) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: Value>(#function: String, deterministic: Bool = false, _ block: (A?, B) -> Z?) -> ((Expression<A?>, Expression<B>) -> Expression<Z?>) {
        return { self.create(function, 2, deterministic) { block($0[0].map(asValue), asValue($0[1])) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: Value>(#function: String, deterministic: Bool = false, _ block: (A, B?) -> Z?) -> ((Expression<A>, Expression<B?>) -> Expression<Z?>) {
        return { self.create(function, 2, deterministic) { block(asValue($0[0]), $0[1].map(asValue)) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: Value>(#function: String, deterministic: Bool = false, _ block: (A?, B?) -> Z?) -> ((Expression<A?>, Expression<B?>) -> Expression<Z?>) {
        return { self.create(function, 2, deterministic) { block($0[0].map(asValue), $0[1].map(asValue)) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: protocol<Value, Expressible>>(#function: String, deterministic: Bool = false, _ block: (A, B) -> Z) -> ((Expression<A>, B) -> Expression<Z>) {
        return { self.create(function, 2, deterministic) { block(asValue($0[0]), asValue($0[1])) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: protocol<Value, Expressible>>(#function: String, deterministic: Bool = false, _ block: (A?, B) -> Z) -> ((Expression<A?>, B) -> Expression<Z>) {
        return { self.create(function, 2, deterministic) { block($0[0].map(asValue), asValue($0[1])) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: protocol<Value, Expressible>>(#function: String, deterministic: Bool = false, _ block: (A, B?) -> Z) -> ((Expression<A>, B?) -> Expression<Z>) {
        return { self.create(function, 2, deterministic) { block(asValue($0[0]), $0[1].map(asValue)) }([$0, Expression<B?>(value: $1)]) }
    }

    public func create<Z: Value, A: Value, B: protocol<Value, Expressible>>(#function: String, deterministic: Bool = false, _ block: (A?, B?) -> Z) -> ((Expression<A?>, B?) -> Expression<Z>) {
        return { self.create(function, 2, deterministic) { block($0[0].map(asValue), $0[1].map(asValue)) }([$0, Expression<B?>(value: $1)]) }
    }

    public func create<Z: Value, A: Value, B: protocol<Value, Expressible>>(#function: String, deterministic: Bool = false, _ block: (A, B) -> Z?) -> ((Expression<A>, B) -> Expression<Z?>) {
        return { self.create(function, 2, deterministic) { block(asValue($0[0]), asValue($0[1])) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: protocol<Value, Expressible>>(#function: String, deterministic: Bool = false, _ block: (A?, B) -> Z?) -> ((Expression<A?>, B) -> Expression<Z?>) {
        return { self.create(function, 2, deterministic) { block($0[0].map(asValue), asValue($0[1])) }([$0, $1]) }
    }

    public func create<Z: Value, A: Value, B: protocol<Value, Expressible>>(#function: String, deterministic: Bool = false, _ block: (A, B?) -> Z?) -> ((Expression<A>, B?) -> Expression<Z?>) {
        return { self.create(function, 2, deterministic) { block(asValue($0[0]), $0[1].map(asValue)) }([$0, Expression<B?>(value: $1)]) }
    }

    public func create<Z: Value, A: Value, B: protocol<Value, Expressible>>(#function: String, deterministic: Bool = false, _ block: (A?, B?) -> Z?) -> ((Expression<A?>, B?) -> Expression<Z?>) {
        return { self.create(function, 2, deterministic) { block($0[0].map(asValue), $0[1].map(asValue)) }([$0, Expression<B?>(value: $1)]) }
    }

    // MARK: -

    private func create<Z: Value>(function: String, _ argc: Int, _ deterministic: Bool, _ block: [Binding?] -> Z) -> ([Expressible] -> Expression<Z>) {
        return { Expression<Z>(self.create(function, argc, deterministic) { (arguments: [Binding?]) -> Z? in block(arguments) }($0)) }
    }

    private func create<Z: Value>(function: String, _ argc: Int, _ deterministic: Bool, _ block: [Binding?] -> Z?) -> ([Expressible] -> Expression<Z?>) {
        create(function: function, argc: argc, deterministic: deterministic) { block($0)?.datatypeValue }
        return { arguments in wrap(quote(identifier: function), Expression<Z>.join(", ", arguments)) }
    }

}

private func asValue<A: Value>(value: Binding) -> A {
    return A.fromDatatypeValue(value as! A.Datatype) as! A
}

private func asValue<A: Value>(value: Binding?) -> A {
    return asValue(value!)
}
