// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

@MainActor
final class MockVPNManager: VPNRunnable {
    var isRunning = false
    var isConnecting = false
    var usedDataInGB: Double = 0
    var dataLimitInGB: Double = 0
    var usageFraction: Double = 0
    var isLimitReached = false
    var isUsageResetDue = false
    var selectedCountryCode = VPNServerManager.recommendedCountryCode
    var isUsingFallback = false
    var startCalled = 0
    var stopCalled = 0
    var onStop: (() -> Void)?
    var onStart: (() -> Void)?
    var startError: Error?
    var startCountryCodes: [String?] = []
    var refreshUsageCalled = 0
    var refreshUsageError: Error?
    var onRefreshUsage: (() -> Void)?
    var countryCodeChangeCalledWith: [String] = []
    var pauseRotationCalled = 0
    var resumeRotationCalled = 0
    let eventsStream = AsyncStream<VPNEvent>.makeStream()

    var events: AsyncStream<VPNEvent> {
        eventsStream.stream
    }

    func start(countryCode: String?) async throws {
        startCalled += 1
        startCountryCodes.append(countryCode)
        onStart?()
        if let startError { throw startError }
        isRunning = true
    }

    func stop() async {
        stopCalled += 1
        isRunning = false
        onStop?()
    }

    func listCountries() async -> [VPNServerManager.Country] {
        return []
    }

    func refreshUsage() async throws {
        refreshUsageCalled += 1
        onRefreshUsage?()
        if let refreshUsageError { throw refreshUsageError }
    }

    func selectedCountryCodeDidChange(countryCode: String) {
        countryCodeChangeCalledWith.append(countryCode)
    }

    func pauseRotation() {
        pauseRotationCalled += 1
    }

    func resumeRotation() {
        resumeRotationCalled += 1
    }
}
