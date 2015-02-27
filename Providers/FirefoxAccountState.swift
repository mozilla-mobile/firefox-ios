/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import FxA

public enum FirefoxAccountStateLabel: String {
    case Engaged = "engaged"
    case Cohabiting = "cohabiting"
    case Married = "married"
    case Separated = "separated"
    case Doghouse = "doghouse"
}

public enum FirefoxAccountActionNeeded {
    case None
    case NeedsVerification
    case NeedsPassword
    case NeedsUpgrade
}

public class FirefoxAccountState {
    let version = 1

    let label: FirefoxAccountStateLabel
    let verified: Bool

    init(label: FirefoxAccountStateLabel, verified: Bool) {
        self.label = label
        self.verified = verified
    }

    func asDictionary() -> [String: AnyObject] {
        var dict: [String: AnyObject] = [:]
        dict["version"] = version
        dict["label"] = self.label.rawValue
        return dict
    }

    func getActionNeeded() -> FirefoxAccountActionNeeded {
        return .NeedsUpgrade
    }

    public class Separated: FirefoxAccountState {
        public init() {
            super.init(label: .Separated, verified: false)
        }

        override func getActionNeeded() -> FirefoxAccountActionNeeded {
            return .NeedsPassword
        }
    }

    public class Engaged: FirefoxAccountState {
        let sessionToken: NSData
        let keyFetchToken: NSData
        let unwrapkB: NSData

        public init(verified: Bool, sessionToken: NSData, keyFetchToken: NSData, unwrapkB: NSData) {
            self.sessionToken = sessionToken
            self.keyFetchToken = keyFetchToken
            self.unwrapkB = unwrapkB
            super.init(label: .Engaged, verified: verified)
        }

        override func asDictionary() -> [String: AnyObject] {
            var d = super.asDictionary()
            d["verified"] = self.verified
            d["sessionToken"] = sessionToken.base16EncodedStringWithOptions(NSDataBase16EncodingOptions.LowerCase)
            d["keyFetchToken"] = keyFetchToken.base16EncodedStringWithOptions(NSDataBase16EncodingOptions.LowerCase)
            d["unwrapkB"] = unwrapkB.base16EncodedStringWithOptions(NSDataBase16EncodingOptions.LowerCase)
            return d
        }

        override func getActionNeeded() -> FirefoxAccountActionNeeded {
            if verified {
                return .None
            } else {
                return .NeedsVerification
            }
        }
    }

    public class TokenAndKeys: FirefoxAccountState {
        let sessionToken: NSData
        let kA: NSData
        let kB: NSData
        // TODO: make key pair required.
        // TODO: maintain key pair issued at timestamp for key rotation.
        let keyPair: KeyPair?

        init(label: FirefoxAccountStateLabel, sessionToken: NSData, kA: NSData, kB: NSData, keyPair: KeyPair?) {
            self.sessionToken = sessionToken
            self.kA = kA
            self.kB = kB
            self.keyPair = keyPair
            super.init(label: label, verified: true)
        }

        override func asDictionary() -> [String: AnyObject] {
            var d = super.asDictionary()
            d["kA"] = kA.base16EncodedStringWithOptions(NSDataBase16EncodingOptions.LowerCase)
            d["kB"] = kB.base16EncodedStringWithOptions(NSDataBase16EncodingOptions.LowerCase)
            // TODO: persist key pair.
            return d
        }

        override func getActionNeeded() -> FirefoxAccountActionNeeded {
            return .None
        }
    }

    public class Cohabiting: TokenAndKeys {
        init(sessionToken: NSData, kA: NSData, kB: NSData, keyPair: KeyPair?) {
            super.init(label: .Cohabiting, sessionToken: sessionToken, kA: kA, kB: kB, keyPair: keyPair)
        }
    }

    public class Married: TokenAndKeys {
        // TODO: Maintain certificate issued at timestamp for invalidation.
        let certificate: String

        init(sessionToken: NSData, kA: NSData, kB: NSData, keyPair: KeyPair?, certificate: String) {
            self.certificate = certificate
            super.init(label: .Married, sessionToken: sessionToken, kA: kA, kB: kB, keyPair: keyPair)
        }

        override func asDictionary() -> [String: AnyObject] {
            var d = super.asDictionary()
            d["certificate"] = certificate
            return d
        }
    }

    public class Doghouse: FirefoxAccountState {
        public init() {
            super.init(label: .Doghouse, verified: false)
        }

        override func getActionNeeded() -> FirefoxAccountActionNeeded {
            return .NeedsUpgrade
        }
    }

    class func fromDictionary(dictionary: [String: AnyObject]) -> FirefoxAccountState? {
        if let version = dictionary["version"] as? Int {
            if version == 1 {
                return FirefoxAccountState.fromDictionaryV1(dictionary)
            }
        }
        return nil
    }

    private class func fromDictionaryV1(dictionary: [String: AnyObject]) -> FirefoxAccountState? {
        // Oh, for a proper monad.

        // TODO: throughout, even a semblance of error checking and input validation.
        if let label = dictionary["label"] as? String {
            if let label = FirefoxAccountStateLabel(rawValue: label) {
                switch label {
                case .Separated:
                    return Separated()

                case .Engaged:
                    let verified = dictionary["verified"] as Bool
                    let sessionToken = NSData(base16EncodedString: dictionary["sessionToken"] as String, options: NSDataBase16DecodingOptions.allZeros)
                    let keyFetchToken = NSData(base16EncodedString: dictionary["keyFetchToken"] as String, options: NSDataBase16DecodingOptions.allZeros)
                    let unwrapkB = NSData(base16EncodedString: dictionary["unwrapkB"] as String, options: NSDataBase16DecodingOptions.allZeros)
                    return Engaged(verified: verified, sessionToken: sessionToken, keyFetchToken: keyFetchToken, unwrapkB: unwrapkB)

                case .Cohabiting:
                    let sessionToken = NSData(base16EncodedString: dictionary["sessionToken"] as String, options: NSDataBase16DecodingOptions.allZeros)
                    let kA = NSData(base16EncodedString: dictionary["kA"] as String, options: NSDataBase16DecodingOptions.allZeros)
                    let kB = NSData(base16EncodedString: dictionary["kB"] as String, options: NSDataBase16DecodingOptions.allZeros)
                    // TODO: extract key pair.
                    return Cohabiting(sessionToken: sessionToken, kA: kA, kB: kB, keyPair: nil)

                case .Married:
                    let sessionToken = NSData(base16EncodedString: dictionary["sessionToken"] as String, options: NSDataBase16DecodingOptions.allZeros)
                    let kA = NSData(base16EncodedString: dictionary["kA"] as String, options: NSDataBase16DecodingOptions.allZeros)
                    let kB = NSData(base16EncodedString: dictionary["kB"] as String, options: NSDataBase16DecodingOptions.allZeros)
                    // TODO: extract key pair.
                    let certificate = dictionary["certificate"] as String
                    return Married(sessionToken: sessionToken, kA: kA, kB: kB, keyPair: nil, certificate: certificate)

                case .Doghouse:
                    return Doghouse()
                }
            }
        }
        return nil
    }
}
