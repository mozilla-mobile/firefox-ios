/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Haskell, baby.

// Monadic bind/flatMap operator for Deferred.
infix operator >>== { associativity left precedence 160 }
public func >>== <T, U>(x: Deferred<Result<T>>, f: T -> Deferred<Result<U>>) -> Deferred<Result<U>> {
    return chainDeferred(x, f)
}

// A termination case.
public func >>== <T, U>(x: Deferred<Result<T>>, f: T -> ()) {
    return x.upon { result in
        if let v = result.successValue {
            f(v)
        }
    }
}

// Monadic `do` for Deferred.
infix operator >>> { associativity left precedence 150 }
public func >>> <T, U>(x: Deferred<Result<T>>, f: () -> Deferred<Result<U>>) -> Deferred<Result<U>> {
    return x.bind { res in
        if res.isSuccess {
            return f();
        }
        return deferResult(res.failureValue!)
    }
}

/**
* Returns a thunk that return a Deferred that resolves to the provided value.
*/
public func always<T>(t: T) -> () -> Deferred<Result<T>> {
    return { deferResult(t) }
}

public func deferResult<T>(s: T) -> Deferred<Result<T>> {
    return Deferred(value: Result(success: s))
}

public func deferResult<T>(e: ErrorType) -> Deferred<Result<T>> {
    return Deferred(value: Result(failure: e))
}

public typealias Success = Deferred<Result<()>>

public func succeed() -> Success {
    return deferResult(())
}

/**
 * Return a single Deferred that represents the sequential chaining
 * of f over the provided items.
 */
public func walk<T>(items: [T], f: T -> Success) -> Success {
    return items.reduce(succeed()) { success, item -> Success in
        success >>> { f(item) }
    }
}

/**
 * Take a function and turn it into a side-effect that can appear
 * in a chain of async operations without producing its own value.
 */
public func effect<T, U>(f: T -> U) -> T -> Deferred<Result<T>> {
    return { t in
        f(t)
        return deferResult(t)
    }
}

/**
 * Return a single Deferred that represents the sequential chaining of
 * f over the provided items, with the return value chained through.
 */
public func walk<T, U>(items: [T], start: Deferred<Result<U>>, f: (T, U) -> Deferred<Result<U>>) -> Deferred<Result<U>> {
    let fs = items.map { item in
        return { val in
            f(item, val)
        }
    }
    return fs.reduce(start, combine: >>==)
}

public func chainDeferred<T, U>(a: Deferred<Result<T>>, f: T -> Deferred<Result<U>>) -> Deferred<Result<U>> {
    return a.bind { res in
        if let v = res.successValue {
            return f(v)
        }
        return Deferred(value: Result<U>(failure: res.failureValue!))
    }
}

public func chainResult<T, U>(a: Deferred<Result<T>>, f: T -> Result<U>) -> Deferred<Result<U>> {
    return a.map { res in
        if let v = res.successValue {
            return f(v)
        }
        return Result<U>(failure: res.failureValue!)
    }
}

public func chain<T, U>(a: Deferred<Result<T>>, f: T -> U) -> Deferred<Result<U>> {
    return chainResult(a, { Result<U>(success: f($0)) })
}
