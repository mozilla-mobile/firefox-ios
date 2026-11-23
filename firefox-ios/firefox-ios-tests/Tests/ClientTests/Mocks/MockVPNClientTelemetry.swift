// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

final class MockVPNClientTelemetry: VPNClientTelemetry {
    struct Success {
        let source: VPNConnectionStartSource
        let countryCode: String
        let isUsingFallback: Bool
    }

    struct Failure {
        let source: VPNConnectionStartSource
        let countryCode: String
        let error: VPNConnectionFailureReason
    }

    var successes: [Success] = []
    var failures: [Failure] = []
    var stops: [VPNConnectionStopSource] = []
    var onboardingShownCount = 0
    var onboardingCancelledCount = 0
    var onboardingCTATappedCount = 0
    var onboardingLearnMoreLinkTappedCount = 0
    var onRecord: (() -> Void)?

    func recordConnectionSucceeded(source: VPNConnectionStartSource, countryCode: String, isUsingFallback: Bool) {
        successes.append(Success(source: source, countryCode: countryCode, isUsingFallback: isUsingFallback))
        onRecord?()
    }

    func recordConnectionFailed(source: VPNConnectionStartSource, countryCode: String, error: VPNConnectionFailureReason) {
        failures.append(Failure(source: source, countryCode: countryCode, error: error))
        onRecord?()
    }

    func recordConnectionStopped(source: VPNConnectionStopSource) {
        stops.append(source)
        onRecord?()
    }

    func recordVPNSettingChanged(isEnabled: Bool) {}

    func recordLocationSelected(countryCode: String, isVPNConnected: Bool, isUsingFallback: Bool?) {}

    func recordAlertOptionSelected(_ option: VPNAlertOption, alertType: VPNAlertType) {}

    func recordOnboardingShown() {
        onboardingShownCount += 1
    }

    func recordOnboardingCancelled() {
        onboardingCancelledCount += 1
    }

    func recordOnboardingCTATapped() {
        onboardingCTATappedCount += 1
    }

    func recordOnboardingLearnMoreLinkTapped() {
        onboardingLearnMoreLinkTappedCount += 1
    }
}
