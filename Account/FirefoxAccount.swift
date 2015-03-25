/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

// The version of the account schema we persist.
let AccountSchemaVersion = 1

/// A FirefoxAccount mediates access to identity attached services.
///
/// All data maintained as part of the account or its state should be
/// considered sensitive and stored appropriately.  Usually, that means
/// storing account data in the iOS keychain.
///
/// Non-sensitive but persistent data should be maintained outside of
/// the account itself.
public class FirefoxAccount {
    /// The email address identifying the account.  A Firefox Account is uniquely identified on a particular server
    /// (auth endpoint) by its email address.
    public let email: String

    /// The auth endpoint user identifier identifying the account.  A Firefox Account is uniquely identified on a
    /// particular server (auth endpoint) by its assigned uid.
    public let uid: String

    /// A Firefox Account exists on a particular server.  The auth endpoint should speak the protocol documented at
    /// https://github.com/mozilla/fxa-auth-server/blob/02f88502700b0c5ef5a4768a8adf332f062ad9bf/docs/api.md
    let authEndpoint: NSURL

    /// The associated content server should speak the protocol implemented (but not yet documented) at
    /// https://github.com/mozilla/fxa-content-server/blob/161bff2d2b50bac86ec46c507e597441c8575189/app/scripts/models/auth_brokers/fx-desktop.js
    let contentEndpoint: NSURL

    /// The associated oauth server should speak the protocol documented at
    /// https://github.com/mozilla/fxa-oauth-server/blob/6cc91e285fc51045a365dbacb3617ef29093dbc3/docs/api.md
    let oauthEndpoint: NSURL

    private var state: FxAState

    public var actionNeeded: FxAActionNeeded {
        return state.actionNeeded
    }

    public init(email: String, uid: String, authEndpoint: NSURL, contentEndpoint: NSURL, oauthEndpoint: NSURL, state: FxAState) {
        self.email = email
        self.uid = uid
        self.authEndpoint = authEndpoint
        self.contentEndpoint = contentEndpoint
        self.oauthEndpoint = oauthEndpoint
        // TODO: It would be nice to fail if any endpoint is not https://, but it's not clear how to do that in a
        // constructor!
        self.state = state
    }

    public class func fromConfigurationAndJSON(configuration: FirefoxAccountConfiguration, data: JSON) -> FirefoxAccount? {
        if let email = data["email"].asString {
            if let uid = data["uid"].asString {
                if let sessionToken = data["sessionToken"].asString?.hexDecodedData {
                    if let keyFetchToken = data["keyFetchToken"].asString?.hexDecodedData {
                        if let unwrapkB = data["unwrapBKey"].asString?.hexDecodedData {
                            let verified = data["verified"].asBool ?? false
                            return FirefoxAccount.fromConfigurationAndParameters(configuration,
                                email: email, uid: uid, verified: verified,
                                sessionToken: sessionToken, keyFetchToken: keyFetchToken, unwrapkB: unwrapkB)
                        }
                    }
                }
            }
        }
        return nil
    }

    public class func fromConfigurationAndLoginResponse(configuration: FirefoxAccountConfiguration,
            response: FxALoginResponse, unwrapkB: NSData) -> FirefoxAccount {
        return FirefoxAccount.fromConfigurationAndParameters(configuration,
            email: response.remoteEmail, uid: response.uid, verified: response.verified,
            sessionToken: response.sessionToken, keyFetchToken: response.keyFetchToken, unwrapkB: unwrapkB)
    }

    private class func fromConfigurationAndParameters(configuration: FirefoxAccountConfiguration,
            email: String, uid: String, verified: Bool,
            sessionToken: NSData, keyFetchToken: NSData, unwrapkB: NSData) -> FirefoxAccount {
        var state: FxAState! = nil
        if !verified {
            let now = Int64(NSDate().timeIntervalSince1970 * 1000)
            state = EngagedBeforeVerifiedState(knownUnverifiedAt: now,
                lastNotifiedUserAt: now,
                sessionToken: sessionToken,
                keyFetchToken: keyFetchToken,
                unwrapkB: unwrapkB
            )
        } else {
            state = EngagedAfterVerifiedState(
                sessionToken: sessionToken,
                keyFetchToken: keyFetchToken,
                unwrapkB: unwrapkB
            )
        }

        let account = FirefoxAccount(
            email: email,
            uid: uid,
            authEndpoint: configuration.authEndpointURL,
            contentEndpoint: configuration.profileEndpointURL,
            oauthEndpoint: configuration.oauthEndpointURL,
            state: state
        )
        return account
    }

    public func asDictionary() -> [String: AnyObject] {
        var dict: [String: AnyObject] = [:]
        dict["version"] = AccountSchemaVersion
        dict["email"] = email
        dict["uid"] = uid
        dict["authEndpoint"] = authEndpoint.absoluteString!
        dict["contentEndpoint"] = contentEndpoint.absoluteString!
        dict["oauthEndpoint"] = oauthEndpoint.absoluteString!
        dict["state"] = state.asDictionary()
        return dict
    }

    public class func fromDictionary(dictionary: [String: AnyObject]) -> FirefoxAccount? {
        if let version = dictionary["version"] as? Int {
            if version == AccountSchemaVersion {
                return FirefoxAccount.fromDictionaryV1(dictionary)
            }
        }
        return nil
    }

    private class func fromDictionaryV1(dictionary: [String: AnyObject]) -> FirefoxAccount? {
        // TODO: throughout, even a semblance of error checking and input validation.
        let email = dictionary["email"] as String
        let uid = dictionary["uid"] as String
        let authEndpoint = NSURL(string: dictionary["authEndpoint"] as String)!
        let contentEndpoint = NSURL(string: dictionary["contentEndpoint"] as String)!
        let oauthEndpoint = NSURL(string: dictionary["oauthEndpoint"] as String)!
        let state = stateFromDictionary(dictionary["state"] as [String: AnyObject])
            ?? SeparatedState()
        return FirefoxAccount(email: email, uid: uid,
                authEndpoint: authEndpoint, contentEndpoint: contentEndpoint, oauthEndpoint: oauthEndpoint,
                state: state)
    }

    public enum AccountError: Printable, ErrorType {
        case NotMarried

        public var description: String {
            switch self {
            case NotMarried: return "Not married."
            }
        }
    }

    public func marriedState() -> Deferred<Result<MarriedState>> {
        let client = FxAClient10(endpoint: authEndpoint)
        let stateMachine = FxALoginStateMachine(client: client)
        let now = Int64(NSDate().timeIntervalSince1970 * 1000)
        return stateMachine.advanceFromState(state, now: now).map { newState in
            self.state = newState
            if newState.label == FxAStateLabel.Married {
                if let married = newState as? MarriedState {
                    return Result(success: married)
                }
            }
            return Result(failure: AccountError.NotMarried)
        }
    }

    public func syncAuthState(tokenServerURL: NSURL) -> SyncAuthState {
        return SyncAuthState(account: self, tokenServerURL: tokenServerURL)
    }
}
