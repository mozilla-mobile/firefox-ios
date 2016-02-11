/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Pipelining.
infix operator |> { associativity left }
public func |> <T, U>(x: T, f: T -> U) -> U {
    return f(x)
}

// Basic currying.
public func curry<A, B>(f: (A) -> B) -> A -> B {
    return { a in
        return f(a)
    }
}

public func curry<A, B, C>(f: (A, B) -> C) -> A -> B -> C {
    return { a in
        return { b in
            return f(a, b)
        }
    }
}

public func curry<A, B, C, D>(f: (A, B, C) -> D) -> A -> B -> C -> D {
    return { a in
        return { b in
            return { c in
                return f(a, b, c)
            }
        }
    }
}

public func curry<A, B, C, D, E>(f: (A, B, C, D) -> E) -> (A, B, C) -> D -> E {
    return { (a, b, c) in
        return { d in
            return f(a, b, c, d)
        }
    }
}

// Function composition.
infix operator • {}

public func •<T, U, V>(f: T -> U, g: U -> V) -> T -> V {
    return { t in
        return g(f(t))
    }
}
public func •<T, V>(f: T -> (), g: () -> V) -> T -> V {
    return { t in
        f(t)
        return g()
    }
}
public func •<V>(f: () -> (), g: () -> V) -> () -> V {
    return {
        f()
        return g()
    }
}

// Why not simply provide an override for ==? Well, that's scary, and can accidentally recurse.
// This is enough to catch arrays, which Swift will delegate to element-==.
public func optArrayEqual<T: Equatable>(lhs: [T]?, rhs: [T]?) -> Bool {
    switch (lhs, rhs) {
    case (.None, .None):
        return true
    case (.None, _):
        return false
    case (_, .None):
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
public func chunk<T>(arr: [T], by: Int) -> [ArraySlice<T>] {
    let count = arr.count
    let step = max(1, by)     // Handle out-of-range 'by'.

    let s = 0.stride(to: count, by: step)
    return s.map {
        arr[$0..<$0.advancedBy(step, limit: count)]
    }
}

public extension SequenceType {
    // [T] -> (T -> K) -> [K: [T]]
    // As opposed to `groupWith` (to follow Haskell's naming), which would be
    // [T] -> (T -> K) -> [[T]]
    func groupBy<Key, Value>(selector: Self.Generator.Element -> Key, transformer: Self.Generator.Element -> Value) -> [Key: [Value]] {
        var acc: [Key: [Value]] = [:]
        for x in self {
            let k = selector(x)
            var a = acc[k] ?? []
            a.append(transformer(x))
            acc[k] = a
        }
        return acc
    }

    func zip<S: SequenceType>(elems: S) -> [(Self.Generator.Element, S.Generator.Element)] {
        var rights = elems.generate()
        return self.flatMap { lhs in
            guard let rhs = rights.next() else {
                return nil
            }
            return (lhs, rhs)
        }
    }
}

public func optDictionaryEqual<K: Equatable, V: Equatable>(lhs: [K: V]?, rhs: [K: V]?) -> Bool {
    switch (lhs, rhs) {
    case (.None, .None):
        return true
    case (.None, _):
        return false
    case (_, .None):
        return false
    default:
        return lhs! == rhs!
    }
}

/**
 * Return members of `a` that aren't nil, changing the type of the sequence accordingly.
 */
public func optFilter<T>(a: [T?]) -> [T] {
    return a.flatMap { $0 }
}

/**
 * Return a new map with only key-value pairs that have a non-nil value.
 */
public func optFilter<K, V>(source: [K: V?]) -> [K: V] {
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
public func mapValues<K, T, U>(source: [K: T], f: (T -> U)) -> [K: U] {
    var m = [K: U]()
    for (k, v) in source {
        m[k] = f(v)
    }
    return m
}

public func findOneValue<K, V>(map: [K: V], f: V -> Bool) -> V? {
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
public func jsonsToStrings(arr: [JSON]?) -> [String]? {
    if let arr = arr {
        return optFilter(arr.map { j in
            return j.asString
            })
    }
    return nil
}

// Encapsulate a callback in a way that we can use it with NSTimer.
private class Callback {
    private let handler:()->()

    init(handler:()->()) {
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
public func debounce(delay:NSTimeInterval, action:()->()) -> ()->() {
    let callback = Callback(handler: action)
    var timer: NSTimer?

    return {
        // If calling again, invalidate the last timer.
        if let timer = timer {
            timer.invalidate()
        }
        timer = NSTimer(timeInterval: delay, target: callback, selector: "go", userInfo: nil, repeats: false)
        NSRunLoop.currentRunLoop().addTimer(timer!, forMode: NSDefaultRunLoopMode)
    }
}

/**
 * A stack that only allows a particular item to be pushed into it once.
 * Duplicates are determined by a key, which allows us to avoid dealing with
 * general-purpose hashing of some of our custom enums.
 */
public class OnceOnlyStack<T, U: Hashable> {
    var seen: Set<U> = Set()
    var stack: [T] = []
    let key: T -> U

    public init(key: T -> U) {
        self.key = key
    }

    // Returns false if the item has already been seen.
    public func push(item: T) -> Bool {
        let k = self.key(item)
        if self.seen.contains(k) {
            return false
        }
        self.stack.append(item)
        self.seen.insert(k)
        return true
    }

    public func pushAll(items: [T]) {
        self.stack.reserveCapacity(items.count + self.stack.count)
        items.forEach { self.push($0) }
    }

    public func pop() -> T? {
        return self.stack.popLast()
    }

    public var count: Int {
        return self.stack.count
    }

    public func forEach(f: T -> ()) {
        while let v = self.stack.popLast() {
            f(v)
        }
    }

    public func ignoreKey(key: U) {
        self.seen.insert(key)
    }
}
