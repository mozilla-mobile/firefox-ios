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
