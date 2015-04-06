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
                let assertion = married.generateAssertionForAudience(TokenServerClient.getAudienceForURL(self.tokenServerURL), now: now)
                let client = TokenServerClient(URL: self.tokenServerURL)
                let clientState = FxAClient10.computeClientState(married.kB)
                let deferred = client.token(assertion, clientState: clientState)
                log.debug("Fetching token server token.")
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
                return deferred.map { result in
                    return result.map { token in
                        (token: token, forKey: married.kB)
                    }
                }
            } else {
                return Deferred(value: Result(failure: result.failureValue!))
            }
        }
    }
}
