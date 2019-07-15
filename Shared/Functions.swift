/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import SwiftyJSON

// Pipelining.
precedencegroup PipelinePrecedence {
    associativity: left
}
infix operator |> : PipelinePrecedence

public func |> <T, U>(x: T, f: (T) -> U) -> U {
    return f(x)
}

// Basic currying.
public func curry<A, B>(_ f: @escaping (A) -> B) -> (A) -> B {
    return { a in
        return f(a)
    }
}

public func curry<A, B, C>(_ f: @escaping (A, B) -> C) -> (A) -> (B) -> C {
    return { a in
        return { b in
            return f(a, b)
        }
    }
}

public func curry<A, B, C, D>(_ f: @escaping (A, B, C) -> D) -> (A) -> (B) -> (C) -> D {
    return { a in
        return { b in
            return { c in
                return f(a, b, c)
            }
        }
    }
}

public func curry<A, B, C, D, E>(_ f: @escaping (A, B, C, D) -> E) -> (A, B, C) -> (D) -> E {
    return { (a, b, c) in
        return { d in
            return f(a, b, c, d)
        }
    }
}

// Function composition.
infix operator •

public func •<T, U, V>(f: @escaping (T) -> U, g: @escaping (U) -> V) -> (T) -> V {
    return { t in
        return g(f(t))
    }
}
public func •<T, V>(f: @escaping (T) -> Void, g: @escaping () -> V) -> (T) -> V {
    return { t in
        f(t)
        return g()
    }
}
public func •<V>(f: @escaping () -> Void, g: @escaping () -> V) -> () -> V {
    return {
        f()
        return g()
    }
}

// Why not simply provide an override for ==? Well, that's scary, and can accidentally recurse.
// This is enough to catch arrays, which Swift will delegate to element-==.
public func optArrayEqual<T: Equatable>(_ lhs: [T]?, rhs: [T]?) -> Bool {
    switch (lhs, rhs) {
    case (.none, .none):
        return true
    case (.none, _):
        return false
    case (_, .none):
        return false
    default:
        // This delegates to Swift's own array '==', which calls T's == on each element.
        return lhs! == rhs!
    }
}

/**
 * Given an array, return an array of slices of size `by` (possibly excepting the last slice).
 *
 * If `by` is longer than the input, returns a single chunk.
 * If `by` is less than 1, acts as if `by` is 1.
 * If the length of the array isn't a multiple of `by`, the final slice will
 * be smaller than `by`, but never empty.
 *
 * If the input array is empty, returns an empty array.
 */

public func chunk<T>(_ arr: [T], by: Int) -> [ArraySlice<T>] {
    var result = [ArraySlice<T>]()
    var chunk = -1
    let size = max(1, by)
    for (index, elem) in arr.enumerated() {
        if index % size == 0 {
            result.append(ArraySlice<T>())
            chunk += 1
        }
        result[chunk].append(elem)
    }
    return result
}

public func chunkCollection<E, X, T: Collection>(_ items: T, by: Int, f: ([E]) -> [X]) -> [X] where T.Iterator.Element == E {
    assert(by >= 0)
    let max = by > 0 ? by : 1
    var i = 0
    var acc: [E] = []
    var results: [X] = []
    var iter = items.makeIterator()

    while let item = iter.next() {
        if i >= max {
            results.append(contentsOf: f(acc))
            acc = []
            i = 0
        }
        acc.append(item)
        i += 1
    }

    if !acc.isEmpty {
        results.append(contentsOf: f(acc))
    }

    return results
}

public extension Sequence {
    // [T] -> (T -> K) -> [K: [T]]
    // As opposed to `groupWith` (to follow Haskell's naming), which would be
    // [T] -> (T -> K) -> [[T]]
    func groupBy<Key, Value>(_ selector: (Self.Iterator.Element) -> Key, transformer: (Self.Iterator.Element) -> Value) -> [Key: [Value]] {
        var acc: [Key: [Value]] = [:]
        for x in self {
            let k = selector(x)
            var a = acc[k] ?? []
            a.append(transformer(x))
            acc[k] = a
        }
        return acc
    }

    func zip<S: Sequence>(_ elems: S) -> [(Self.Iterator.Element, S.Iterator.Element)] {
        var rights = elems.makeIterator()
        return self.compactMap { lhs in
            guard let rhs = rights.next() else {
                return nil
            }
            return (lhs, rhs)
        }
    }
}

public func optDictionaryEqual<K, V: Equatable>(_ lhs: [K: V]?, rhs: [K: V]?) -> Bool {
    switch (lhs, rhs) {
    case (.none, .none):
        return true
    case (.none, _):
        return false
    case (_, .none):
        return false
    default:
        return lhs! == rhs!
    }
}

/**
 * Return members of `a` that aren't nil, changing the type of the sequence accordingly.
 */
public func optFilter<T>(_ a: [T?]) -> [T] {
    return a.compactMap { $0 }
}

/**
 * Return a new map with only key-value pairs that have a non-nil value.
 */
public func optFilter<K, V>(_ source: [K: V?]) -> [K: V] {
    var m = [K: V]()
    for (k, v) in source {
        if let v = v {
            m[k] = v
        }
    }
    return m
}

/**
 * Map a function over the values of a map.
 */
public func mapValues<K, T, U>(_ source: [K: T], f: ((T) -> U)) -> [K: U] {
    var m = [K: U]()
    for (k, v) in source {
        m[k] = f(v)
    }
    return m
}

public func findOneValue<K, V>(_ map: [K: V], f: (V) -> Bool) -> V? {
    for v in map.values {
        if f(v) {
            return v
        }
    }
    return nil
}

/**
 * Take a JSON array, returning the String elements as an array.
 * It's usually convenient for this to accept an optional.
 */
public func jsonsToStrings(_ arr: [JSON]?) -> [String]? {
    return arr?.compactMap { $0.stringValue }
}

// Encapsulate a callback in a way that we can use it with NSTimer.
private class Callback {
    private let handler:() -> Void

    init(handler:@escaping () -> Void) {
        self.handler = handler
    }

    @objc
    func go() {
        handler()
    }
}

/**
 * Taken from http://stackoverflow.com/questions/27116684/how-can-i-debounce-a-method-call
 * Allows creating a block that will fire after a delay. Resets the timer if called again before the delay expires.
 **/
public func debounce(_ delay: TimeInterval, action:@escaping () -> Void) -> () -> Void {
    let callback = Callback(handler: action)
    var timer: Timer?

    return {
        // If calling again, invalidate the last timer.
        if let timer = timer {
            timer.invalidate()
        }
        timer = Timer(timeInterval: delay, target: callback, selector: #selector(Callback.go), userInfo: nil, repeats: false)
        RunLoop.current.add(timer!, forMode: RunLoop.Mode.default)
    }
}
