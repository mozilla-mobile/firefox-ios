/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/// A FirefoxAccount mediates access to identity attached services.
///
/// All data maintained as part of the account or its state should be
/// considered sensitive and stored appropriately.  Usually, that means
/// storing account data in the iOS keychain.
///
/// Non-sensitive but persistent data should be maintained outside of
/// the account itself.
public class FirefoxAccount {
    let version = 1

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

    private var state: FirefoxAccountState

    public init(email: String, uid: String, authEndpoint: NSURL, contentEndpoint: NSURL, oauthEndpoint: NSURL, state: FirefoxAccountState) {
        self.email = email
        self.uid = uid
        self.authEndpoint = authEndpoint
        self.contentEndpoint = contentEndpoint
        self.oauthEndpoint = oauthEndpoint
        // TODO: It would be nice to fail if any endpoint is not https://, but it's not clear how to do that in a
        // constructor!
        self.state = state
    }

    public func asDictionary() -> [String: AnyObject] {
        var dict: [String: AnyObject] = [:]
        dict["version"] = version
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
            if version == 1 {
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
        let state = FirefoxAccountState.fromDictionary(dictionary["state"] as [String: AnyObject])
            ?? FirefoxAccountState.Separated()
        return FirefoxAccount(email: email, uid: uid,
                authEndpoint: authEndpoint, contentEndpoint: contentEndpoint, oauthEndpoint: oauthEndpoint,
                state: state)
   }

    public func getActionNeeded() -> FirefoxAccountActionNeeded {
        return state.getActionNeeded()
    }
}
