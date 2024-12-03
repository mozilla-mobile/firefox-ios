// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// Monadic bind/flatMap operator for Deferred.
precedencegroup MonadicBindPrecedence {
    associativity: left
    higherThan: MonadicDoPrecedence
    lowerThan: BitwiseShiftPrecedence
}

precedencegroup MonadicDoPrecedence {
    associativity: left
    higherThan: MultiplicationPrecedence
}

infix operator >>== : MonadicBindPrecedence
infix operator >>> : MonadicDoPrecedence

@discardableResult
public func >>== <T, U>(x: Deferred<Maybe<T>>, f: @escaping (T) -> Deferred<Maybe<U>>) -> Deferred<Maybe<U>> {
    return chainDeferred(x, f: f)
}

// A termination case.
public func >>== <T>(x: Deferred<Maybe<T>>, f: @escaping (T) -> Void) {
    return x.upon { result in
        if let v = result.successValue {
            f(v)
        }
    }
}

// Monadic `do` for Deferred.
@discardableResult
public func >>> <T, U>(x: Deferred<Maybe<T>>, f: @escaping () -> Deferred<Maybe<U>>) -> Deferred<Maybe<U>> {
    return x.bind { res in
        if res.isSuccess {
            return f()
        }
        return deferMaybe(res.failureValue!)
    }
}

// Another termination case.
public func >>> <T>(x: Deferred<Maybe<T>>, f: @escaping () -> Void) {
    return x.upon { res in
        if res.isSuccess {
            f()
        }
    }
}

/**
* Returns a thunk that return a Deferred that resolves to the provided value.
*/
public func always<T>(_ t: T) -> () -> Deferred<Maybe<T>> {
    return { deferMaybe(t) }
}

public func deferMaybe<T>(_ s: T) -> Deferred<Maybe<T>> {
    return Deferred(value: Maybe(success: s))
}

// This specific overload prevents Strings, which conform to MaybeErrorType, from
// always matching the failure case. See <https://github.com/mozilla-mobile/firefox-ios/issues/7791>.
public func deferMaybe(_ s: String) -> Deferred<Maybe<String>> {
    return Deferred(value: Maybe(success: s))
}

public func deferMaybe<T>(_ e: MaybeErrorType) -> Deferred<Maybe<T>> {
    return Deferred(value: Maybe(failure: e))
}

public typealias Success = Deferred<Maybe<Void>>

@discardableResult
public func succeed() -> Success {
    return deferMaybe(())
}

/**
 * Return a single Deferred that represents the sequential chaining
 * of f over the provided items.
 */
public func walk<T>(_ items: [T], f: @escaping (T) -> Success) -> Success {
    return items.reduce(succeed()) { success, item -> Success in
        success >>> { f(item) }
    }
}

/**
 * Like `all`, but thanks to its taking thunks as input, each result is
 * generated in strict sequence. Fails immediately if any result is failure.
 */
public func accumulate<T>(_ thunks: [() -> Deferred<Maybe<T>>]) -> Deferred<Maybe<[T]>> {
    if thunks.isEmpty {
        return deferMaybe([])
    }

    let combined = Deferred<Maybe<[T]>>()
    var results: [T] = []
    results.reserveCapacity(thunks.count)

    var onValue: ((T) -> Void)!
    var onResult: ((Maybe<T>) -> Void)!

    // onValue and onResult both hold references to each other niling them out before exiting breaks a reference cycle
    // We also cannot use unowned here because the thunks are not class types.
    onValue = { t in
        results.append(t)
        if results.count == thunks.count {
            onResult = nil
            combined.fill(Maybe(success: results))
        } else {
            thunks[results.count]().upon(onResult)
        }
    }

    onResult = { r in
        if r.isFailure {
            onValue = nil
            combined.fill(Maybe(failure: r.failureValue!))
            return
        }
        onValue(r.successValue!)
    }

    thunks[0]().upon(onResult)

    return combined
}

/**
 * Take a function and turn it into a side-effect that can appear
 * in a chain of async operations without producing its own value.
 */
public func effect<T, U>(_ f: @escaping (T) -> U) -> (T) -> Deferred<Maybe<T>> {
    return { t in
        _ = f(t)
        return deferMaybe(t)
    }
}
// Prevents "Cannot convert call result type '(_) -> Deferred<Maybe<_>>' to expected type '() -> Deferred<Maybe<Void>>"
// SE-0029 introduced this behaviour
// https://github.com/apple/swift-evolution/blob/master/proposals/0029-remove-implicit-tuple-splat.md
public func effect(_ f: @escaping (Swift.Void) -> Void) -> () -> Success {
    return {
        f(())
        return succeed()
    }
}

/**
 * Return a single Deferred that represents the sequential chaining of
 * f over the provided items, with the return value chained through.
 */
public func walk<T, U, S: Sequence>(
    _ items: S,
    start: Deferred<Maybe<U>>,
    f: @escaping (T, U) -> Deferred<Maybe<U>>
) -> Deferred<Maybe<U>> where S.Iterator.Element == T {
    let fs = items.map { item in
        return { val in
            f(item, val)
        }
    }
    return fs.reduce(start, >>==)
}

/**
 * Like `all`, but doesn't accrue individual values.
 */
extension Array where Element: Success {
    public func allSucceed() -> Success {
        return all(self).bind { results -> Success in
            if let failure = results.first(where: { $0.isFailure }) {
                return deferMaybe(failure.failureValue!)
            }

            return succeed()
        }
    }
}

public func chainDeferred<T, U>(_ a: Deferred<Maybe<T>>, f: @escaping (T) -> Deferred<Maybe<U>>) -> Deferred<Maybe<U>> {
    return a.bind { res in
        if let v = res.successValue {
            return f(v)
        }
        return Deferred(value: Maybe<U>(failure: res.failureValue!))
    }
}

public func chainResult<T, U>(_ a: Deferred<Maybe<T>>, f: @escaping (T) -> Maybe<U>) -> Deferred<Maybe<U>> {
    return a.map { res in
        if let v = res.successValue {
            return f(v)
        }
        return Maybe<U>(failure: res.failureValue!)
    }
}

public func chain<T, U>(_ a: Deferred<Maybe<T>>, f: @escaping (T) -> U) -> Deferred<Maybe<U>> {
    return chainResult(a, f: { Maybe<U>(success: f($0)) })
}

/// Defer-ifies a block to an async dispatch queue.
public func deferDispatchAsync<T>(_ queue: DispatchQueue, f: @escaping () -> Deferred<Maybe<T>>) -> Deferred<Maybe<T>> {
    let deferred = Deferred<Maybe<T>>()
    queue.async(execute: {
        f().upon { result in
            deferred.fill(result)
        }
    })

    return deferred
}
