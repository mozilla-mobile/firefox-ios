// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import Foundation
import Glean
import Shared
import VPNKit

enum VPNConnectionFailureReason: String {
    case notSignedIn = "not_signed_in"
    case noServerFound = "no_server_found"
    case proxyURLCannotBeGenerated = "proxy_url_cannot_be_generated"
    case tokenProviderUnavailable = "token_provider_unavailable"
    case network
    case serverError = "server_error"
    /// The device has used its monthly bandwidth quota.
    case quotaExceeded = "quota_exceeded"
    case auth
    /// The device can't do App Attest, so the VPN can never connect on it.
    case attestationUnsupported = "attestation_unsupported"
    /// For first-time enrollment, `vpn.attestation.failed` also records the details.
    case attestation
    case keychain
    case invalidResponse = "invalid_response"
    case invalidURL = "invalid_url"
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
        case AppAttestServiceError.appAttestNotSupported:
            self = .attestationUnsupported
        case AppAttestServiceError.invalidKeyID,
             AppAttestServiceError.missingKeyID,
             AppAttestServiceError.invalidChallenge:
            self = .attestation
        case AppAttestServiceError.keychain:
            self = .keychain
        case AppAttestServiceError.invalidPayload:
            self = .invalidResponse
        case AppAttestServiceError.invalidURL:
            self = .invalidURL
        case VPNAuthError.quotaExceeded:
            self = .quotaExceeded
        case is VPNAuthError:
            self = .auth
        default:
            self = .unknown
        }
    }
}

enum VPNConnectionStartSource: String {
    case settings
}

enum VPNConnectionStopSource: String {
    case settings
    case continueWithoutVPN = "continue_without_vpn"
    case closeThisTab = "close_this_tab"
    case closeAllTabs = "close_all_tabs"
}

enum VPNAlertType: String {
    case monthlyLimit = "monthly_limit"
    case sessionError = "session_error"
}

enum VPNAlertOption: String {
    case continueWithoutVPN = "continue_without_vpn"
    case closeThisTab = "close_this_tab"
    case closeAllTabs = "close_all_tabs"
}

/// Records VPN events that originate in the client rather than in VPNKit.
protocol VPNClientTelemetry {
    /// `countryCode` is the selected location, or `VPNServerManager.recommendedCountryCode`.
    func recordConnectionSucceeded(source: VPNConnectionStartSource, countryCode: String, isUsingFallback: Bool)
    func recordConnectionFailed(source: VPNConnectionStartSource, countryCode: String, error: VPNConnectionFailureReason)
    func recordConnectionStopped(source: VPNConnectionStopSource)
    func recordVPNSettingChanged(isEnabled: Bool)
    /// `isUsingFallback` is only known when the VPN was connected and reconnected successfully.
    func recordLocationSelected(countryCode: String, isVPNConnected: Bool, isUsingFallback: Bool?)
    func recordAlertOptionSelected(_ option: VPNAlertOption, alertType: VPNAlertType)
    func recordOnboardingShown()
    func recordOnboardingCancelled()
    func recordOnboardingCTATapped()
    func recordOnboardingLearnMoreLinkTapped()
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

    func recordConnectionSucceeded(source: VPNConnectionStartSource, countryCode: String, isUsingFallback: Bool) {
        let extras = GleanMetrics.Vpn.ConnectionStartedExtra(
            countryCode: countryCode,
            isUsingFallback: isUsingFallback,
            source: source.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Vpn.connectionStarted, extras: extras)
    }

    func recordConnectionFailed(source: VPNConnectionStartSource, countryCode: String, error: VPNConnectionFailureReason) {
        let extras = GleanMetrics.Vpn.ConnectionStartedExtra(
            countryCode: countryCode,
            error: error.rawValue,
            source: source.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Vpn.connectionStarted, extras: extras)
    }

    func recordConnectionStopped(source: VPNConnectionStopSource) {
        let extras = GleanMetrics.Vpn.ConnectionStoppedExtra(source: source.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.Vpn.connectionStopped, extras: extras)
    }

    func recordVPNSettingChanged(isEnabled: Bool) {
        SettingsTelemetry(gleanWrapper: gleanWrapper).changedSetting(
            PrefsKeys.Settings.vpnFeature,
            to: String(isEnabled),
            from: String(!isEnabled)
        )
    }

    func recordLocationSelected(countryCode: String, isVPNConnected: Bool, isUsingFallback: Bool?) {
        let extras = GleanMetrics.SettingsVpnLocationList.LocationSelectedExtra(
            countryCode: countryCode,
            isUsingFallback: isUsingFallback,
            isVpnConnected: isVPNConnected
        )
        gleanWrapper.recordEvent(for: GleanMetrics.SettingsVpnLocationList.locationSelected, extras: extras)
    }

    func recordAlertOptionSelected(_ option: VPNAlertOption, alertType: VPNAlertType) {
        let extras = GleanMetrics.VpnSessionErrorAlert.OptionSelectedExtra(
            errorType: alertType.rawValue,
            option: option.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.VpnSessionErrorAlert.optionSelected, extras: extras)
    }

    func recordOnboardingShown() {
        gleanWrapper.recordEvent(for: GleanMetrics.Vpn.onboardingShown)
    }

    func recordOnboardingCancelled() {
        gleanWrapper.recordEvent(for: GleanMetrics.Vpn.onboardingCancelled)
    }

    func recordOnboardingCTATapped() {
        gleanWrapper.recordEvent(for: GleanMetrics.Vpn.onboardingCtaTapped)
    }

    func recordOnboardingLearnMoreLinkTapped() {
        gleanWrapper.recordEvent(for: GleanMetrics.Vpn.onboardingLearnMoreLinkTapped)
    }
}
