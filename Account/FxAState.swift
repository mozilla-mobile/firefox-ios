/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import FxA
import Shared

// The version of the state schema we persist.
let StateSchemaVersion = 1

// We want an enum because the set of states is closed.  However, each state has state-specific
// behaviour, and the state's behaviour accumulates, so each state is a class.  Switch on the
// label to get exhaustive cases.
public enum FxAStateLabel: String {
    case EngagedBeforeVerified = "engagedBeforeVerified"
    case EngagedAfterVerified = "engagedAfterVerified"
    case CohabitingBeforeKeyPair = "cohabitingBeforeKeyPair"
    case CohabitingAfterKeyPair = "cohabitingAfterKeyPair"
    case Married = "married"
    case Separated = "separated"
    case Doghouse = "doghouse"

    // See http://stackoverflow.com/a/24137319
    static let allValues: [FxAStateLabel] = [
        EngagedBeforeVerified,
        EngagedAfterVerified,
        CohabitingBeforeKeyPair,
        CohabitingAfterKeyPair,
        Married,
        Separated,
        Doghouse,
    ]
}

public enum FxAActionNeeded {
    case None
    case NeedsVerification
    case NeedsPassword
    case NeedsUpgrade
}

func stateFromJSON(json: JSON) -> FxAState? {
    if json.isError {
        return nil
    }
    if let version = json["version"].asInt {
        if version == StateSchemaVersion {
            return stateFromJSONV1(json)
        }
    }
    return nil
}

func stateFromJSONV1(json: JSON) -> FxAState? {
    if let labelString = json["label"].asString {
        if let label = FxAStateLabel(rawValue:  labelString) {
            switch label {
            case .EngagedBeforeVerified:
                if let
                    sessionToken = json["sessionToken"].asString?.hexDecodedData,
                    keyFetchToken = json["keyFetchToken"].asString?.hexDecodedData,
                    unwrapkB = json["unwrapkB"].asString?.hexDecodedData,
                    knownUnverifiedAt = json["knownUnverifiedAt"].asInt64,
                    lastNotifiedUserAt = json["lastNotifiedUserAt"].asInt64 {
                    return EngagedBeforeVerifiedState(
                        knownUnverifiedAt: UInt64(knownUnverifiedAt), lastNotifiedUserAt: UInt64(lastNotifiedUserAt),
                        sessionToken: sessionToken, keyFetchToken: keyFetchToken, unwrapkB: unwrapkB)
                }

            case .EngagedAfterVerified:
                if let
                    sessionToken = json["sessionToken"].asString?.hexDecodedData,
                    keyFetchToken = json["keyFetchToken"].asString?.hexDecodedData,
                    unwrapkB = json["unwrapkB"].asString?.hexDecodedData {
                    return EngagedAfterVerifiedState(sessionToken: sessionToken, keyFetchToken: keyFetchToken, unwrapkB: unwrapkB)
                }

            case .CohabitingBeforeKeyPair:
                if let
                    sessionToken = json["sessionToken"].asString?.hexDecodedData,
                    kA = json["kA"].asString?.hexDecodedData,
                    kB = json["kB"].asString?.hexDecodedData {
                    return CohabitingBeforeKeyPairState(sessionToken: sessionToken, kA: kA, kB: kB)
                }

            case .CohabitingAfterKeyPair:
                if let
                    sessionToken = json["sessionToken"].asString?.hexDecodedData,
                    kA = json["kA"].asString?.hexDecodedData,
                    kB = json["kB"].asString?.hexDecodedData,
                    keyPairJSON = JSON.unwrap(json["keyPair"]) as? [String: AnyObject],
                    keyPair = RSAKeyPair(JSONRepresentation: keyPairJSON),
                    keyPairExpiresAt = json["keyPairExpiresAt"].asInt64 {
                        return CohabitingAfterKeyPairState(sessionToken: sessionToken, kA: kA, kB: kB,
                            keyPair: keyPair, keyPairExpiresAt: UInt64(keyPairExpiresAt))
                }

            case .Married:
                if let
                    sessionToken = json["sessionToken"].asString?.hexDecodedData,
                    kA = json["kA"].asString?.hexDecodedData,
                    kB = json["kB"].asString?.hexDecodedData,
                    keyPairJSON = JSON.unwrap(json["keyPair"]) as? [String: AnyObject],
                    keyPair = RSAKeyPair(JSONRepresentation: keyPairJSON),
                    keyPairExpiresAt = json["keyPairExpiresAt"].asInt64,
                    certificate = json["certificate"].asString,
                    certificateExpiresAt = json["certificateExpiresAt"].asInt64 {
                    return MarriedState(sessionToken: sessionToken, kA: kA, kB: kB,
                        keyPair: keyPair, keyPairExpiresAt: UInt64(keyPairExpiresAt),
                        certificate: certificate, certificateExpiresAt: UInt64(certificateExpiresAt))
                }

            case .Separated:
                return SeparatedState()

            case .Doghouse:
                return DoghouseState()
            }
        }
    }
    return nil
}

// Not an externally facing state!
public class FxAState: JSONLiteralConvertible {
    public var label: FxAStateLabel { return FxAStateLabel.Separated } // This is bogus, but we have to do something!

    public var actionNeeded: FxAActionNeeded {
        // Kind of nice to have this in one place.
        switch label {
        case .EngagedBeforeVerified: return .NeedsVerification
        case .EngagedAfterVerified: return .None
        case .CohabitingBeforeKeyPair: return .None
        case .CohabitingAfterKeyPair: return .None
        case .Married: return .None
        case .Separated: return .NeedsPassword
        case .Doghouse: return .NeedsUpgrade
        }
    }

    public func asJSON() -> JSON {
        return JSON([
            "version": StateSchemaVersion,
            "label": self.label.rawValue,
        ])
    }
}

public class SeparatedState: FxAState {
    override public var label: FxAStateLabel { return FxAStateLabel.Separated }

    override public init() {
        super.init()
    }
}

// Not an externally facing state!
public class ReadyForKeys: FxAState {
    let sessionToken: NSData
    let keyFetchToken: NSData
    let unwrapkB: NSData

    init(sessionToken: NSData, keyFetchToken: NSData, unwrapkB: NSData) {
        self.sessionToken = sessionToken
        self.keyFetchToken = keyFetchToken
        self.unwrapkB = unwrapkB
        super.init()
    }

    public override func asJSON() -> JSON {
        var d: [String: JSON] = super.asJSON().asDictionary!
        d["sessionToken"] = JSON(sessionToken.hexEncodedString)
        d["keyFetchToken"] = JSON(keyFetchToken.hexEncodedString)
        d["unwrapkB"] = JSON(unwrapkB.hexEncodedString)
        return JSON(d)
    }
}

public class EngagedBeforeVerifiedState: ReadyForKeys {
    override public var label: FxAStateLabel { return FxAStateLabel.EngagedBeforeVerified }

    // Timestamp, in milliseconds after the epoch, when we first knew the account was unverified.
    // Use this to avoid nagging the user to verify her account immediately after connecting.
    let knownUnverifiedAt: Timestamp
    let lastNotifiedUserAt: Timestamp

    public init(knownUnverifiedAt: Timestamp, lastNotifiedUserAt: Timestamp, sessionToken: NSData, keyFetchToken: NSData, unwrapkB: NSData) {
        self.knownUnverifiedAt = knownUnverifiedAt
        self.lastNotifiedUserAt = lastNotifiedUserAt
        super.init(sessionToken: sessionToken, keyFetchToken: keyFetchToken, unwrapkB: unwrapkB)
    }

    public override func asJSON() -> JSON {
        var d = super.asJSON().asDictionary!
        d["knownUnverifiedAt"] = JSON(NSNumber(unsignedLongLong: knownUnverifiedAt))
        d["lastNotifiedUserAt"] = JSON(NSNumber(unsignedLongLong: lastNotifiedUserAt))
        return JSON(d)
    }

    func withUnwrapKey(unwrapkB: NSData) -> EngagedBeforeVerifiedState {
        return EngagedBeforeVerifiedState(
            knownUnverifiedAt: knownUnverifiedAt, lastNotifiedUserAt: lastNotifiedUserAt,
            sessionToken: sessionToken, keyFetchToken: keyFetchToken, unwrapkB: unwrapkB)
    }
}

public class EngagedAfterVerifiedState: ReadyForKeys {
    override public var label: FxAStateLabel { return FxAStateLabel.EngagedAfterVerified }

    override public init(sessionToken: NSData, keyFetchToken: NSData, unwrapkB: NSData) {
        super.init(sessionToken: sessionToken, keyFetchToken: keyFetchToken, unwrapkB: unwrapkB)
    }

    func withUnwrapKey(unwrapkB: NSData) -> EngagedAfterVerifiedState {
        return EngagedAfterVerifiedState(sessionToken: sessionToken, keyFetchToken: keyFetchToken, unwrapkB: unwrapkB)
    }
}

// Not an externally facing state!
public class TokenAndKeys: FxAState {
    let sessionToken: NSData
    public let kA: NSData
    public let kB: NSData

    init(sessionToken: NSData, kA: NSData, kB: NSData) {
        self.sessionToken = sessionToken
        self.kA = kA
        self.kB = kB
        super.init()
    }

    public override func asJSON() -> JSON {
        var d = super.asJSON().asDictionary!
        d["sessionToken"] = JSON(sessionToken.hexEncodedString)
        d["kA"] = JSON(kA.hexEncodedString)
        d["kB"] = JSON(kB.hexEncodedString)
        return JSON(d)
    }
}

public class CohabitingBeforeKeyPairState: TokenAndKeys {
    override public var label: FxAStateLabel { return FxAStateLabel.CohabitingBeforeKeyPair }
}

// Not an externally facing state!
public class TokenKeysAndKeyPair: TokenAndKeys {
    let keyPair: KeyPair
    // Timestamp, in milliseconds after the epoch, when keyPair expires.  After this time, generate a new keyPair.
    let keyPairExpiresAt: Timestamp

    init(sessionToken: NSData, kA: NSData, kB: NSData, keyPair: KeyPair, keyPairExpiresAt: Timestamp) {
        self.keyPair = keyPair
        self.keyPairExpiresAt = keyPairExpiresAt
        super.init(sessionToken: sessionToken, kA: kA, kB: kB)
    }

    public override func asJSON() -> JSON {
        var d = super.asJSON().asDictionary!
        d["keyPair"] = JSON(keyPair.JSONRepresentation())
        d["keyPairExpiresAt"] = JSON(NSNumber(unsignedLongLong: keyPairExpiresAt))
        return JSON(d)
    }

    func isKeyPairExpired(now: Timestamp) -> Bool {
        return keyPairExpiresAt < now
    }
}

public class CohabitingAfterKeyPairState: TokenKeysAndKeyPair {
    override public var label: FxAStateLabel { return FxAStateLabel.CohabitingAfterKeyPair }
}

public class MarriedState: TokenKeysAndKeyPair {
    override public var label: FxAStateLabel { return FxAStateLabel.Married }

    let certificate: String
    let certificateExpiresAt: Timestamp

    init(sessionToken: NSData, kA: NSData, kB: NSData, keyPair: KeyPair, keyPairExpiresAt: Timestamp, certificate: String, certificateExpiresAt: Timestamp) {
        self.certificate = certificate
        self.certificateExpiresAt = certificateExpiresAt
        super.init(sessionToken: sessionToken, kA: kA, kB: kB, keyPair: keyPair, keyPairExpiresAt: keyPairExpiresAt)
    }

    public override func asJSON() -> JSON {
        var d = super.asJSON().asDictionary!
        d["certificate"] = JSON(certificate)
        d["certificateExpiresAt"] = JSON(NSNumber(unsignedLongLong: certificateExpiresAt))
        return JSON(d)
    }

    func isCertificateExpired(now: Timestamp) -> Bool {
        return certificateExpiresAt < now
    }

    func withoutKeyPair() -> CohabitingBeforeKeyPairState {
        let newState = CohabitingBeforeKeyPairState(sessionToken: sessionToken,
            kA: kA, kB: kB)
        return newState
    }

    func withoutCertificate() -> CohabitingAfterKeyPairState {
        let newState = CohabitingAfterKeyPairState(sessionToken: sessionToken,
            kA: kA, kB: kB,
            keyPair: keyPair, keyPairExpiresAt: keyPairExpiresAt)
        return newState
    }

    public func generateAssertionForAudience(audience: String, now: Timestamp) -> String {
        let assertion = JSONWebTokenUtils.createAssertionWithPrivateKeyToSignWith(keyPair.privateKey,
            certificate: certificate,
            audience: audience,
            issuer: "127.0.0.1",
            issuedAt: now,
            duration: OneHourInMilliseconds)
        return assertion
    }
}

public class DoghouseState: FxAState {
    override public var label: FxAStateLabel { return FxAStateLabel.Doghouse }

    override public init() {
        super.init()
    }
}
