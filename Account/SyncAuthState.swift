/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import SwiftyJSON
import MozillaAppServices


public let FxAClientErrorDomain = "org.mozilla.fxa.error"
public let FxAClientUnknownError = NSError(domain: FxAClientErrorDomain, code: 999,
    userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])

public struct FxAccountRemoteError {
    static let AttemptToOperateOnAnUnverifiedAccount: Int32     = 104
    static let InvalidAuthenticationToken: Int32                = 110
    static let EndpointIsNoLongerSupported: Int32               = 116
    static let IncorrectLoginMethodForThisAccount: Int32        = 117
    static let IncorrectKeyRetrievalMethodForThisAccount: Int32 = 118
    static let IncorrectAPIVersionForThisAccount: Int32         = 119
    static let UnknownDevice: Int32                             = 123
    static let DeviceSessionConflict: Int32                     = 124
    static let UnknownError: Int32                              = 999
}

public enum FxAClientError: Error, CustomStringConvertible {
    case remote(RemoteError)
    case local(NSError)

    public var description : String {
        switch self {
        case .remote(let err): return "FxA remote error: \(err)"
        case .local(let err): return "FxA local error: \(err)"
        }
    }
}

public struct RemoteError {
    let code: Int32
    let errno: Int32
    let error: String?
    let message: String?
    let info: String?

    var isUpgradeRequired: Bool {
        return errno == FxAccountRemoteError.EndpointIsNoLongerSupported
            || errno == FxAccountRemoteError.IncorrectLoginMethodForThisAccount
            || errno == FxAccountRemoteError.IncorrectKeyRetrievalMethodForThisAccount
            || errno == FxAccountRemoteError.IncorrectAPIVersionForThisAccount
    }

    var isInvalidAuthentication: Bool {
        return code == 401
    }

    var isUnverified: Bool {
        return errno == FxAccountRemoteError.AttemptToOperateOnAnUnverifiedAccount
    }
}


private let CurrentSyncAuthStateCacheVersion = 1

private let log = Logger.syncLogger

public struct SyncAuthStateCache {
    let token: TokenServerToken
    let forKey: Data
    let expiresAt: Timestamp
}

public protocol SyncAuthState {
    func invalidate()
    func token(_ now: Timestamp, canBeExpired: Bool) -> Deferred<Maybe<(token: TokenServerToken, forKey: Data)>>
    var enginesEnablements: [String: Bool]? { get set }
    var clientName: String? { get set }
}

public func syncAuthStateCachefromJSON(_ json: JSON) -> SyncAuthStateCache? {
    if let version = json["version"].int {
        if version != CurrentSyncAuthStateCacheVersion {
            log.warning("Sync Auth State Cache is wrong version; dropping.")
            return nil
        }
        if let
            token = TokenServerToken.fromJSON(json["token"]),
            let forKey = json["forKey"].string?.hexDecodedData,
            let expiresAt = json["expiresAt"].int64 {
            return SyncAuthStateCache(token: token, forKey: forKey, expiresAt: Timestamp(expiresAt))
        }
    }
    return nil
}

extension SyncAuthStateCache: JSONLiteralConvertible {
    public func asJSON() -> JSON {
        return JSON([
            "version": CurrentSyncAuthStateCacheVersion,
            "token": token.asJSON(),
            "forKey": forKey.hexEncodedString,
            "expiresAt": NSNumber(value: expiresAt),
        ] as NSDictionary)
    }
}

open class FirefoxAccountSyncAuthState: SyncAuthState {
    fileprivate let cache: KeychainCache<SyncAuthStateCache>
    public var enginesEnablements: [String: Bool]?
    public var clientName: String?

    init(cache: KeychainCache<SyncAuthStateCache>) {
        self.cache = cache
    }

    // If a token gives you a 401, invalidate it and request a new one.
    open func invalidate() {
        log.info("Invalidating cached token server token.")
        self.cache.value = nil
    }

    open func token(_ now: Timestamp, canBeExpired: Bool) -> Deferred<Maybe<(token: TokenServerToken, forKey: Data)>> {
        if let value = cache.value {
            // Give ourselves some room to do work.
            let isExpired = value.expiresAt < now + 5 * OneMinuteInMilliseconds
            if canBeExpired {
                if isExpired {
                    log.info("Returning cached expired token.")
                } else {
                    log.info("Returning cached token, which should be valid.")
                }
                return deferMaybe((token: value.token, forKey: value.forKey))
            }

            if !isExpired {
                log.info("Returning cached token, which should be valid.")
                return deferMaybe((token: value.token, forKey: value.forKey))
            }
        }

        let deferred = Deferred<Maybe<(token: TokenServerToken, forKey: Data)>>()

        RustFirefoxAccounts.shared.accountManager.getTokenServerEndpointURL() { result in
            guard case .success(let tokenServerEndpointURL) = result else {
                deferred.fill(Maybe(failure: FxAClientError.local(NSError())))
                return
            }

            let client = TokenServerClient(url: tokenServerEndpointURL)
            RustFirefoxAccounts.shared.accountManager.getAccessToken(scope: OAuthScope.oldSync) { res in
                switch res {
                    case .failure(let err):
                        deferred.fill(Maybe(failure: err as MaybeErrorType))
                    case .success(let accessToken):
                        log.debug("Fetching token server token.")
                        client.token(token: accessToken.token, kid: accessToken.key!.kid).upon { result in
                        guard let token = result.successValue else {
                            deferred.fill(Maybe(failure: result.failureValue!))
                            return
                        }
                        let kSync = accessToken.key!.k.base64urlSafeDecodedData!
                        let newCache = SyncAuthStateCache(token: token, forKey: kSync,expiresAt: now + 1000 * token.durationInSeconds)
                        log.debug("Fetched token server token!  Token expires at \(newCache.expiresAt).")
                        self.cache.value = newCache
                        deferred.fill(Maybe(success: (token: token, forKey: kSync)))
                    }
                }
            }
        }
        return deferred
    }
}
