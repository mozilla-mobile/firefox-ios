// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared
import IPProtectionKit

/// Shared code for the IP Protection debug actions
class IPProtectionDebugSetting: HiddenSetting {
    fileprivate let prefs: Prefs = { return (AppContainer.shared.resolve() as Profile).prefs }()
    fileprivate let creator: IPProtectionAuthCreating

    init(settings: SettingsTableViewController, creator: IPProtectionAuthCreating = IPProtectionAuthCreator()) {
        self.creator = creator
        super.init(settings: settings)
    }

    /// Title shown in the alert.
    var alertTitle: String { "IP Protection" }

    /// Runs against the configured auth service and returns a success message.
    func perform(with service: IPProtectionAuthenticating) async throws -> String {
        fatalError("Subclasses must override perform(with:)")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        guard let service = creator.makeAuthService(using: prefs) else {
            present(title: alertTitle, message: "Failed to create auth service (App Attest unsupported?).")
            return
        }

        Task { @MainActor in
            do {
                present(title: "\(alertTitle) ✅", message: try await perform(with: service))
            } catch {
                present(title: "\(alertTitle) ❌", message: "\(error)")
            }
        }
    }

    func attributedTitle(_ text: String) -> NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(
            string: text,
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
        )
    }

    /// Summary of a DSJ, highlighting what changed against a previous one
    func summary(of session: IPProtectionDeviceSession?, comparedTo previous: IPProtectionDeviceSession?) -> String {
        guard let session else { return "No session stored." }

        let claims = Self.decodeClaims(session.deviceSessionJwt)
        let device = claims["sub"] as? String ?? "?"

        var lines = ["device (sub): \(device)"]
        if let issuedAt = claims["iat"] as? TimeInterval {
            lines.append("issued (iat): \(Self.format(msSinceEpoch: issuedAt * 1000))")
        }

        if let previous {
            let previousClaims = Self.decodeClaims(previous.deviceSessionJwt)
            let previousDevice = previousClaims["sub"] as? String ?? "?"
            let changed = session.deviceSessionJwt != previous.deviceSessionJwt
            // The DSJ has no `jti`, so its payload is fully determined by (sub, iat, exp): an
            // identical token within the same second is normal
            let sameSecond = (claims["iat"] as? TimeInterval) == (previousClaims["iat"] as? TimeInterval)
            if changed {
                lines.append("token changed: YES")
            } else if sameSecond {
                lines.append("token changed: no — same iat second (expected, DSJ has no jti)")
            } else {
                lines.append("token changed: NO ⚠️")
            }
            lines.append("device kept: \(device == previousDevice ? "YES" : "NO ⚠️")")
        }

        lines.append("expires: \(Self.format(msSinceEpoch: session.expiresAt))")
        lines.append("renew after: \(Self.format(msSinceEpoch: session.renewAfter))")
        lines.append("needs renewal now: \(session.needsRenewal() ? "YES" : "no")")
        return lines.joined(separator: "\n")
    }

    /// Decodes the JWT payload for DISPLAY ONLY — no signature verification. Debug use only.
    fileprivate static func decodeClaims(_ jwt: String) -> [String: Any] {
        let parts = jwt.split(separator: ".")
        guard parts.count > 1 else { return [:] }

        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)

        guard let data = Data(base64Encoded: base64),
              let claims = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return claims
    }

    fileprivate static func format(msSinceEpoch: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date(timeIntervalSince1970: msSinceEpoch / 1000))
    }

    @MainActor
    fileprivate func present(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        settings.present(alert, animated: true)
    }
}

/// Runs the full auth flow: cached DSJ, else assertion refresh, else full attestation.
final class TriggerIPProtectionAttestationSetting: IPProtectionDebugSetting {
    override var title: NSAttributedString? { attributedTitle("IP Protection: Authenticate") }
    override var alertTitle: String { "IP Protection Authenticate" }

    override func perform(with service: IPProtectionAuthenticating) async throws -> String {
        let before = service.currentSession()
        _ = try await service.authenticate()
        return summary(of: service.currentSession(), comparedTo: before)
    }
}

/// Forces an assertion-based refresh, bypassing the cached DSJ short-circuit.
final class RefreshIPProtectionSessionSetting: IPProtectionDebugSetting {
    override var title: NSAttributedString? { attributedTitle("IP Protection: Refresh (Assertion)") }
    override var alertTitle: String { "IP Protection Refresh" }

    override func perform(with service: IPProtectionAuthenticating) async throws -> String {
        let before = service.currentSession()
        _ = try await service.refresh()
        return summary(of: service.currentSession(), comparedTo: before)
    }
}

/// Exchanges the current DSJ for a short-lived proxy token (vpnJWT).
final class FetchIPProtectionProxyTokenSetting: IPProtectionDebugSetting {
    override var title: NSAttributedString? { attributedTitle("IP Protection: Fetch Proxy Token") }
    override var alertTitle: String { "IP Protection Proxy Token" }

    override func onClick(_ navigationController: UINavigationController?) {
        guard let service = creator.makeProxyTokenService(using: prefs) else {
            present(title: alertTitle, message: "Failed to create proxy token service.")
            return
        }

        Task { @MainActor in
            do {
                let proxyToken = try await service.fetchProxyToken()
                present(title: "\(alertTitle) ✅", message: Self.describe(proxyToken))
            } catch IPProtectionError.noStoredSession {
                present(title: "\(alertTitle) ❌",
                        message: "No stored session. Run Authenticate first.\n\nStrict mode: this button never enrolls.")
            } catch {
                present(title: "\(alertTitle) ❌", message: "\(error)")
            }
        }
    }

    private static func describe(_ proxyToken: IPProtectionProxyToken) -> String {
        let claims = decodeClaims(proxyToken.token)
        // Falls back to the signature tail, which is the only part that differs between two
        // otherwise-identical tokens.
        let identifier = claims["jti"] as? String
            ?? String(proxyToken.token.split(separator: ".").last ?? "?")

        var lines = ["token id: \(identifier.prefix(12))…"]
        lines.append("expiresIn: \(proxyToken.expiresIn)s")
        if proxyToken.expiresIn <= 180 {
            lines.append("(short TTL — DSJ is past renewAfter)")
        }
        lines.append("subject: \(claims["sub"] as? String ?? "?")")
        lines.append("audience: \(claims["aud"] as? String ?? "?")")
        if let exp = claims["exp"] as? TimeInterval {
            lines.append("expires: \(format(msSinceEpoch: exp * 1000))")
        }
        return lines.joined(separator: "\n")
    }
}

/// Clears the stored session and attestation key so the next run performs a full enrollment.
final class ClearIPProtectionSessionSetting: IPProtectionDebugSetting {
    override var title: NSAttributedString? { attributedTitle("IP Protection: Clear Session & Key ⚠️") }
    override var alertTitle: String { "IP Protection Reset" }

    override func perform(with service: IPProtectionAuthenticating) async throws -> String {
        try service.reset()
        return "Cleared stored DSJ and App Attest key."
    }
}
