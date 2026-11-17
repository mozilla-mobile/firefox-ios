// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import Foundation
import Glean
import VPNKit

enum VPNStartFailureReason: String {
    case notSignedIn = "not_signed_in"
    case noServerFound = "no_server_found"
    case proxyURLCannotBeGenerated = "proxy_url_cannot_be_generated"
    case tokenProviderUnavailable = "token_provider_unavailable"
    case network
    case serverError = "server_error"
    case auth
    /// Details are recorded separately by `vpn.attestation.failed`.
    case attestation
    case unknown

    init(_ error: Error) {
        switch error {
        case VPNError.notSignedIn:
            self = .notSignedIn
        case VPNError.noServerFound:
            self = .noServerFound
        case VPNError.proxyURLCannotBeGenerated:
            self = .proxyURLCannotBeGenerated
        case VPNError.tokenProviderUnavailable:
            self = .tokenProviderUnavailable
        case is URLError:
            self = .network
        case AppAttestServiceError.serverError:
            self = .serverError
        case is AppAttestServiceError:
            self = .attestation
        case is VPNAuthError:
            self = .auth
        default:
            self = .unknown
        }
    }
}

enum VPNStartTrigger: String {
    case user
    case reconnectAtLaunch = "reconnect_at_launch"
}

enum VPNStopTrigger: String {
    case user
    case continueWithoutVPN = "continue_without_vpn"
    case closeThisTab = "close_this_tab"
    case closeAllTabs = "close_all_tabs"
}

/// Records VPN events that originate in the client rather than in VPNKit.
protocol VPNClientTelemetry {
    /// `countryCode` is the selected location, or `VPNServerManager.recommendedCountryCode`.
    func recordStartSucceeded(countryCode: String, trigger: VPNStartTrigger)
    func recordStartFailed(reason: VPNStartFailureReason, countryCode: String, trigger: VPNStartTrigger)
    func recordStopCompleted(trigger: VPNStopTrigger)
}

struct DefaultVPNTelemetry: VPNTelemetry, VPNClientTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func record(_ event: VPNTelemetryEvent) {
        switch event {
        case .attestationSucceeded:
            gleanWrapper.recordEvent(for: GleanMetrics.VpnAttestation.succeeded)
        case .attestationFailed(let reason):
            let extras = GleanMetrics.VpnAttestation.FailedExtra(failureReason: reason.rawValue)
            gleanWrapper.recordEvent(for: GleanMetrics.VpnAttestation.failed, extras: extras)
        }
    }

    func recordStartSucceeded(countryCode: String, trigger: VPNStartTrigger) {
        let extras = GleanMetrics.VpnStart.SucceededExtra(countryCode: countryCode, trigger: trigger.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.VpnStart.succeeded, extras: extras)
    }

    func recordStartFailed(reason: VPNStartFailureReason, countryCode: String, trigger: VPNStartTrigger) {
        let extras = GleanMetrics.VpnStart.FailedExtra(
            countryCode: countryCode,
            failureReason: reason.rawValue,
            trigger: trigger.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.VpnStart.failed, extras: extras)
    }

    func recordStopCompleted(trigger: VPNStopTrigger) {
        let extras = GleanMetrics.VpnStop.CompletedExtra(trigger: trigger.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.VpnStop.completed, extras: extras)
    }
}
