/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

// TODO: manage this logging better.
private let log = XCGLogger.defaultInstance()

public class SyncAuthState {
    private let account: FirefoxAccount
    private let tokenServerURL: NSURL

    typealias Cache = (token: TokenServerToken, forKey: NSData, expiresAt: Timestamp)
    private var cache: Cache? = nil

    init(account: FirefoxAccount, tokenServerURL: NSURL) {
        self.account = account
        self.tokenServerURL = tokenServerURL
    }

    // If a token gives you a 401, invalidate it and request a new one.
    public func invalidate() {
        self.cache = nil
    }

    // Generate an assertion and try to fetch a token server token, retrying at most a fixed number
    // of times.
    //
    // It's tricky to get Swift to recurse into a closure that captures from the environment without
    // segfaulting the compiler, so we pass everything around, like barbarians.
    private func generateAssertionAndFetchTokenAt(audience: String, client: TokenServerClient, clientState: String?, married: MarriedState,
            now: Timestamp, retryCount: Int) -> Deferred<Result<TokenServerToken>> {
        let assertion = married.generateAssertionForAudience(audience, now: now)
        return client.token(assertion, clientState: clientState).bind { result in
            if retryCount > 0 {
                if let tokenServerError = result.failureValue as? TokenServerError {
                    switch tokenServerError {
                    case let .Remote(code, status, remoteTimestamp) where code == 401 && status == "invalid-timestamp":
                        if let remoteTimestamp = remoteTimestamp {
                            let skew = Int64(remoteTimestamp) - Int64(now) // Without casts, runtime crash due to overflow.
                            log.info("Token server responded with 401/invalid-timestamp: retrying with remote timestamp \(remoteTimestamp), which is local timestamp + skew = \(now) + \(skew).")
                            return self.generateAssertionAndFetchTokenAt(audience, client: client, clientState: clientState, married: married, now: remoteTimestamp, retryCount: retryCount - 1)
                        }
                    default:
                        break
                    }
                }
            }
            // Fall-through.
            return Deferred(value: result)
        }
    }

    public func token(now: Timestamp, canBeExpired: Bool) -> Deferred<Result<(token: TokenServerToken, forKey: NSData)>> {
        if let (token, forKey, expiresAt) = cache {
            // Give ourselves some room to do work.
            let isExpired = expiresAt < now + 5 * OneMinuteInMilliseconds
            if canBeExpired {
                if isExpired {
                    log.info("Returning cached expired token.")
                } else {
                    log.info("Returning cached token, which should be valid.")
                }
                return Deferred(value: Result(success: (token: token, forKey: forKey)))
            }

            if !isExpired {
                log.info("Returning cached token, which should be valid.")
                return Deferred(value: Result(success: (token: token, forKey: forKey)))
            }
        }

        log.debug("Advancing Account state.")
        return account.marriedState().bind { result in
            if let married = result.successValue {
                log.info("Account is in Married state; generating assertion.")
                let audience = TokenServerClient.getAudienceForURL(self.tokenServerURL)
                let client = TokenServerClient(URL: self.tokenServerURL)
                let clientState = FxAClient10.computeClientState(married.kB)
                log.debug("Fetching token server token.")
                let deferred = self.generateAssertionAndFetchTokenAt(audience, client: client, clientState: clientState, married: married, now: now, retryCount: 1)
                deferred.upon { result in
                    // This could race to update the cache with multiple token results.
                    // One racer will win -- that's fine, presumably she has the freshest token.
                    // If not, that's okay, 'cuz the slightly dated token is still a valid token.
                    if let token = result.successValue {
                        let newCache = (token: token, forKey: married.kB,
                            expiresAt: now + 1000 * token.durationInSeconds)
                        log.debug("Fetched token server token!  Token expires at \(newCache.expiresAt).")
                        self.cache = newCache
                    }
                }
                return chain(deferred, { (token: $0, forKey: married.kB) })
            }
            return deferResult(result.failureValue!)
        }
    }
}
