// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import DeviceCheck
import Foundation

public enum VPNTelemetryEvent: Equatable, Sendable {
    /// Device attestation succeeded and the backend issued a session token.
    case attestationSucceeded

    /// Device attestation failed.
    case attestationFailed(reason: VPNAttestationFailureReason)
}

public struct VPNAttestationFailureReason: RawRepresentable, Equatable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// The device or build cannot do App Attest at all.
    public static let unsupported = VPNAttestationFailureReason(rawValue: "unsupported")
    /// A key exists but Apple or the backend will not accept it, so the next attempt re-attests.
    public static let keyUnusable = VPNAttestationFailureReason(rawValue: "key_unusable")
    /// Could not reach the backend.
    public static let network = VPNAttestationFailureReason(rawValue: "network")
    /// The attestation succeeded but the resulting session could not be stored.
    public static let sessionNotPersisted = VPNAttestationFailureReason(rawValue: "session_not_persisted")
    /// Reached the backend, but not an attestation rejection.
    public static let notAvailable = VPNAttestationFailureReason(rawValue: "not_available")
    public static let unknown = VPNAttestationFailureReason(rawValue: "unknown")

    init(_ error: Error) {
        switch error {
        case AppAttestServiceError.appAttestNotSupported:
            self = .unsupported
        case AppAttestServiceError.missingKeyID, AppAttestServiceError.invalidKeyID:
            self = .keyUnusable
        case AppAttestServiceError.invalidChallenge:
            self = .unknown
        case AppAttestServiceError.keychain, VPNAuthError.sessionNotPersisted:
            self = .sessionNotPersisted
        case let AppAttestServiceError.serverError(statusCode, description):
            self = Self.forServerError(statusCode: statusCode, body: description)
        case is URLError:
            self = .network
        case let error as DCError where error.code == .serverUnavailable:
            self = .network
        case is DCError:
            self = .keyUnusable
        default:
            self = .unknown
        }
    }

    /// Do not forward entire response, only decoded `reason`.
    private static func forServerError(statusCode: Int, body: String) -> VPNAttestationFailureReason {
        if let reason = decodeReason(from: body) {
            return VPNAttestationFailureReason(rawValue: reason.replacingOccurrences(of: "-", with: "_"))
        }
        // A rejection always carries a reason, so a bare status means the request never reached
        // the enrollment handler.
        return (400..<500).contains(statusCode) ? .notAvailable : .unknown
    }

    private static func decodeReason(from body: String) -> String? {
        struct Rejection: Decodable { let reason: String }

        guard let data = body.data(using: .utf8),
              let rejection = try? JSONDecoder().decode(Rejection.self, from: data) else {
            return nil
        }
        return rejection.reason
    }
}

/// Lets the client record VPNKit events through Glean without VPNKit depending on it.
public protocol VPNTelemetry: Sendable {
    func record(_ event: VPNTelemetryEvent)
}
