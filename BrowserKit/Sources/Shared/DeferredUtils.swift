// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

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

public func chainDeferred<T, U>(
    _ a: Deferred<Maybe<T>>,
    f: @escaping @Sendable (T) -> Deferred<Maybe<U>>
) -> Deferred<Maybe<U>> {
    return a.bind { res in
        if let v = res.successValue {
            return f(v)
        }
        return Deferred(value: Maybe<U>(failure: res.failureValue!))
    }
}
