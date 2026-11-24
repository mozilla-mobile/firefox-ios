// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Glean
import Shared
import XCTest

@testable import Client

@MainActor
final class InstallationTelemetryServiceTests: XCTestCase {
    private var installationPrefs: MockProfilePrefs!
    private var mockHistoryStore: MockInstallationHistoryStore!
    private var mockGleanWrapper: MockGleanWrapper!
    private var profilePrefs: MockProfilePrefs!
    private var mockFeatureFlags: MockNimbusFeatureFlags!
    private var mockDateProvider: MockDateProvider!

    override func setUp() async throws {
        try await super.setUp()
        installationPrefs = MockProfilePrefs()
        mockHistoryStore = MockInstallationHistoryStore()
        mockGleanWrapper = MockGleanWrapper()
        profilePrefs = MockProfilePrefs()
        profilePrefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        profilePrefs.setBool(true, forKey: AppConstants.prefSendUsageData)
        mockFeatureFlags = MockNimbusFeatureFlags()
        mockFeatureFlags.enabledFlags = [.checkForReinstalls]
        mockDateProvider = MockDateProvider(fixedDate: Date(timeIntervalSince1970: 1_760_000_000))
    }

    override func tearDown() async throws {
        profilePrefs = nil
        mockFeatureFlags = nil
        installationPrefs = nil
        mockHistoryStore = nil
        mockGleanWrapper = nil
        mockDateProvider = nil
        try await super.tearDown()
    }

    func testUpdate_duringUnitTests_doesNotCollectTelemetry() {
        createSubject().update()

        XCTAssertEqual(mockHistoryStore.loadCalled, 0)
        XCTAssertEqual(mockHistoryStore.saveCalled, 0)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 0)
    }

    func testUpdateInstallationHistory_whenUsagePreferenceIsMissing_waitsForConsent() throws {
        profilePrefs.removeObjectForKey(AppConstants.prefSendUsageData)
        let subject = createSubject()

        try subject.updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.loadCalled, 0)
        XCTAssertEqual(mockHistoryStore.saveCalled, 0)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
        XCTAssertTrue(mockGleanWrapper.savedQuantities.isEmpty)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 0)

        profilePrefs.setBool(true, forKey: AppConstants.prefSendUsageData)
        try subject.updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.value?.installCounter, 1)
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 1)
    }

    func testUpdateInstallationHistory_whenTermsPreferenceIsMissing_waitsForAcceptance() throws {
        profilePrefs.removeObjectForKey(PrefsKeys.TermsOfUseAccepted)
        let subject = createSubject()

        try subject.updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.loadCalled, 0)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 0)

        profilePrefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        try subject.updateInstallationHistory()
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
    }

    func testUpdateInstallationHistory_whenTermsAreNotAccepted_waitsForAcceptance() throws {
        profilePrefs.setBool(false, forKey: PrefsKeys.TermsOfUseAccepted)
        let subject = createSubject()
        try subject.updateInstallationHistory()
        XCTAssertEqual(mockHistoryStore.loadCalled, 0)

        profilePrefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        try subject.updateInstallationHistory()
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
    }

    func testUpdateInstallationHistory_whenFeatureIsDisabled_waitsForEnablement() throws {
        mockFeatureFlags.enabledFlags = []
        let subject = createSubject()
        XCTAssertNil(installationPrefs.boolForKey(PrefsKeys.installationProcessedKey))

        try subject.updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.loadCalled, 0)
        XCTAssertEqual(mockHistoryStore.saveCalled, 0)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 0)

        mockFeatureFlags.enabledFlags = [.checkForReinstalls]
        try subject.updateInstallationHistory()

        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 1)
    }

    func testUpdateInstallationHistory_onFreshInstall_recordsMetricsOnce() throws {
        let subject = createSubject()

        try subject.updateInstallationHistory()
        try subject.updateInstallationHistory()
        try createSubject().updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.value,
                       InstallationHistory(installCounter: 1, lastSeenDate: mockDateProvider.fixedDate))
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
        XCTAssertEqual(mockGleanWrapper.recordDatetimeCalled, 0)
        XCTAssertEqual(mockGleanWrapper.recordStringCalled, 0)
        XCTAssertTrue(mockGleanWrapper.savedValues.isEmpty)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 1)
        XCTAssertTrue(mockGleanWrapper.savedPing as? Ping<NoReasonCodes> === GleanMetrics.Pings.shared.installation)
    }

    func testUpdateInstallationHistory_onReinstall_recordsPreviousDateAndUpdatesHistory() throws {
        mockHistoryStore.value = InstallationHistory(installCounter: 3, lastSeenDate: Date(timeIntervalSince1970: 0))

        try createSubject().updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.loadCalled, 1)
        XCTAssertEqual(mockHistoryStore.saveCalled, 1)
        XCTAssertEqual(mockHistoryStore.value,
                       InstallationHistory(installCounter: 4, lastSeenDate: mockDateProvider.fixedDate))
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [4])
        XCTAssertEqual(mockGleanWrapper.savedValues.first as? Date, Date(timeIntervalSince1970: 0))
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 1)
    }

    func testUpdateInstallationHistory_onExistingInstallation_initializesHistoryWithoutMetrics() throws {
        try createSubject(hasSeenIntro: true).updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.value?.installCounter, 1)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 0)
    }

    func testUpdateInstallationHistory_onExistingInstallation_preservesCounter() throws {
        mockHistoryStore.value = InstallationHistory(installCounter: 5, lastSeenDate: .distantPast)

        try createSubject(hasSeenIntro: true).updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.loadCalled, 1)
        XCTAssertEqual(mockHistoryStore.saveCalled, 1)
        XCTAssertEqual(mockHistoryStore.value,
                       InstallationHistory(installCounter: 5, lastSeenDate: mockDateProvider.fixedDate))
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
    }

    func testUpdateInstallationHistory_whenConsentIsPending_preservesStateAcrossServiceRecreation() throws {
        profilePrefs.setBool(false, forKey: AppConstants.prefSendUsageData)
        let subject = createSubject()
        try subject.updateInstallationHistory()
        XCTAssertEqual(mockHistoryStore.loadCalled, 0)

        let recreated = createSubject(hasSeenIntro: true)
        profilePrefs.setBool(true, forKey: AppConstants.prefSendUsageData)
        try recreated.updateInstallationHistory()

        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
    }

    func testUpdateInstallationHistory_whenAlreadyProcessed_doesNotRepeatWithUnfinishedOnboarding() throws {
        try createSubject().updateInstallationHistory()
        try createSubject(hasSeenIntro: false).updateInstallationHistory()

        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
    }

    func testUpdateInstallationHistory_whenConsentIsReenabled_updatesDateWithoutRepeatingMetrics() throws {
        let subject = createSubject()
        try subject.updateInstallationHistory()
        profilePrefs.setBool(false, forKey: AppConstants.prefSendUsageData)
        mockDateProvider.fixedDate = mockDateProvider.fixedDate.addingTimeInterval(86_400)
        try subject.updateInstallationHistory()
        XCTAssertNotEqual(mockHistoryStore.value?.lastSeenDate, mockDateProvider.fixedDate)

        profilePrefs.setBool(true, forKey: AppConstants.prefSendUsageData)
        try subject.updateInstallationHistory()

        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
        XCTAssertEqual(mockHistoryStore.value?.lastSeenDate, mockDateProvider.fixedDate)
    }

    func testUpdateInstallationHistory_whenSaveFails_leavesProcessingPendingAcrossLaunches() throws {
        mockHistoryStore.saveError = InstallationHistoryError.keychain(-1)
        do {
            try createSubject().updateInstallationHistory()
            XCTFail("Expected the storage failure")
        } catch InstallationHistoryError.keychain(-1) {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertNil(mockHistoryStore.value)
        XCTAssertEqual(installationPrefs.boolForKey(PrefsKeys.installationProcessedKey), false)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 0)

        mockHistoryStore.saveError = nil
        try createSubject(hasSeenIntro: true).updateInstallationHistory()
        XCTAssertEqual(mockHistoryStore.value?.installCounter, 1)
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1, 1])
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 1)
    }

    func testUpdateInstallationHistory_whenLoadFails_doesNotProcessInstallation() throws {
        mockHistoryStore.loadError = InstallationHistoryError.keychain(-1)
        do {
            try createSubject().updateInstallationHistory()
            XCTFail("Expected the storage failure")
        } catch InstallationHistoryError.keychain(-1) {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(mockHistoryStore.saveCalled, 0)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
    }

    func testUpdateInstallationHistory_whenHistoryIsCorrupt_replacesHistory() throws {
        mockHistoryStore.isCorrupt = true
        let subject = createSubject()

        try subject.updateInstallationHistory()
        try subject.updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.value,
                       InstallationHistory(installCounter: 1, lastSeenDate: mockDateProvider.fixedDate))
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
        XCTAssertEqual(mockGleanWrapper.recordDatetimeCalled, 0)
        XCTAssertTrue(mockGleanWrapper.savedValues.isEmpty)
        XCTAssertEqual(installationPrefs.boolForKey(PrefsKeys.installationProcessedKey), true)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 1)
    }

    func testUpdateInstallationHistory_whenProcessedHistoryIsCorrupt_resetsHistoryWithoutMetrics() throws {
        mockHistoryStore.isCorrupt = true

        try createSubject(hasSeenIntro: true).updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.value,
                       InstallationHistory(installCounter: 1, lastSeenDate: mockDateProvider.fixedDate))
        XCTAssertEqual(mockHistoryStore.saveCalled, 1)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 0)
    }

    func testUpdateInstallationHistory_whenLastSeenRefreshFails_doesNotRepeatMetrics() throws {
        let subject = createSubject(hasSeenIntro: true)
        mockHistoryStore.saveError = InstallationHistoryError.keychain(-1)

        do {
            try subject.updateInstallationHistory()
            XCTFail("Expected the storage failure")
        } catch InstallationHistoryError.keychain(-1) {} catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 0)
        XCTAssertEqual(installationPrefs.boolForKey(PrefsKeys.installationProcessedKey), true)
    }

    func testUpdateInstallationHistory_whenCounterCanReachMaximum_recordsMaximumCounter() throws {
        mockHistoryStore.value = InstallationHistory(installCounter: Int64.max - 1, lastSeenDate: mockDateProvider.fixedDate)

        try createSubject().updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.value?.installCounter, Int64.max)
        XCTAssertEqual(mockHistoryStore.saveCalled, 1)
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [Int64.max])
    }

    func testUpdateInstallationHistory_whenCounterIsAtMaximum_preservesMaximumCounter() throws {
        mockHistoryStore.value = InstallationHistory(installCounter: .max, lastSeenDate: .distantPast)

        try createSubject().updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.value,
                       InstallationHistory(installCounter: .max, lastSeenDate: mockDateProvider.fixedDate))
        XCTAssertEqual(mockHistoryStore.saveCalled, 1)
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [Int64.max])
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 1)
        XCTAssertEqual(installationPrefs.boolForKey(PrefsKeys.installationProcessedKey), true)
    }

    func testUpdateInstallationHistory_whenProfilePreferencesAreCleared_doesNotRepeatProcessing() throws {
        try createSubject().updateInstallationHistory()
        profilePrefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        profilePrefs.clearAll()
        profilePrefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        profilePrefs.setBool(true, forKey: AppConstants.prefSendUsageData)

        try createSubject(hasSeenIntro: false).updateInstallationHistory()

        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
    }

    func testUpdateInstallationHistory_submitsInstallationPingOnce() async throws {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let configuration = Configuration(dataPath: path.path, httpClient: MockInstallationPingUploader())
        Glean.shared.enableTestingMode()
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.initialize(uploadEnabled: true,
                                configuration: configuration,
                                buildInfo: GleanMetrics.GleanBuild.info)
        Glean.shared.resetGlean(configuration: configuration, clearStores: true)
        gleanSetStoreSubmittedPingsEnabled(true)
        gleanClearStoredSubmittedPings()
        defer {
            gleanSetStoreSubmittedPingsEnabled(false)
            Glean.shared.resetGlean(clearStores: true, uploadEnabled: false)
            try? FileManager.default.removeItem(at: path)
        }
        let previousDate = Date(timeIntervalSince1970: 45_296)
        mockHistoryStore.value = InstallationHistory(installCounter: 1, lastSeenDate: previousDate)
        let subject = InstallationTelemetryService(profilePrefs: profilePrefs,
                                                   installationPrefs: installationPrefs,
                                                   history: mockHistoryStore,
                                                   featureFlagsProvider: mockFeatureFlags,
                                                   dateProvider: mockDateProvider)
        let pingSubmitted = expectation(description: "The installation ping was sent")
        GleanMetrics.Pings.shared.installation.testBeforeNextSubmit { _ in
            XCTAssertEqual(self.mockHistoryStore.value,
                           InstallationHistory(installCounter: 2, lastSeenDate: self.mockDateProvider.fixedDate))
            XCTAssertEqual(self.installationPrefs.boolForKey(PrefsKeys.installationProcessedKey), false)
            XCTAssertEqual(GleanMetrics.Installation.lastSeenDate.testGetValue("installation"),
                           previousDate)
            pingSubmitted.fulfill()
        }

        try subject.updateInstallationHistory()
        await fulfillment(of: [pingSubmitted], timeout: 5.0)
        XCTAssertNil(GleanMetrics.Installation.installCounter.testGetValue("installation"))
        XCTAssertNil(GleanMetrics.Installation.lastSeenDate.testGetValue("installation"))
        XCTAssertNil(GleanMetrics.Installation.originalAppVersion.testGetValue("installation"))

        let pings = gleanGetStoredSubmittedPingsByName("installation")
        XCTAssertEqual(pings.count, 1)
        let payload = try XCTUnwrap(pings.first?.payload)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [String: Any])
        let metrics = try XCTUnwrap(json["metrics"] as? [String: Any])
        let quantities = try XCTUnwrap(metrics["quantity"] as? [String: Any])
        XCTAssertEqual(quantities["installation.install_counter"] as? Int, 2)
        XCTAssertNil((metrics["string"] as? [String: Any])?["installation.original_app_version"])
        let datetimes = try XCTUnwrap(metrics["datetime"] as? [String: Any])
        let lastSeenDate = try XCTUnwrap(datetimes["installation.last_seen_date"] as? String)
        XCTAssertEqual(ISO8601DateFormatter().date(from: lastSeenDate), previousDate)
        XCTAssertNil(datetimes["installation.original_purchase_date"])

        try subject.updateInstallationHistory()
        XCTAssertFalse(gleanSubmitPingByNameSync("installation", nil))
        XCTAssertEqual(gleanGetStoredSubmittedPingsByName("installation").count, 1)
        XCTAssertTrue(gleanSubmitPingByNameSync("baseline", nil))
        let baselinePings = gleanGetStoredSubmittedPingsByName("baseline")
        XCTAssertFalse(baselinePings.contains { $0.payload?.contains("installation.install_counter") == true })
    }

    private func createSubject(hasSeenIntro: Bool = false) -> InstallationTelemetryService {
        if hasSeenIntro {
            profilePrefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        } else {
            profilePrefs.removeObjectForKey(PrefsKeys.IntroSeen)
        }
        return InstallationTelemetryService(profilePrefs: profilePrefs,
                                            installationPrefs: installationPrefs,
                                            history: mockHistoryStore,
                                            telemetry: InstallationTelemetry(gleanWrapper: mockGleanWrapper),
                                            featureFlagsProvider: mockFeatureFlags,
                                            dateProvider: mockDateProvider)
    }
}

@MainActor
private final class MockInstallationHistoryStore: InstallationHistoryStoring {
    var value: InstallationHistory?
    var loadError: Error?
    var isCorrupt = false
    var saveError: Error?
    var loadCalled = 0
    var saveCalled = 0

    func load() throws -> InstallationHistoryState {
        loadCalled += 1
        if let loadError { throw loadError }
        if isCorrupt { return .corrupt }
        if let value { return .valid(value) }
        return .missing
    }

    func save(_ history: InstallationHistory) throws {
        if let saveError { throw saveError }
        saveCalled += 1
        value = history
        isCorrupt = false
    }

    func resetForTesting() throws {
        value = nil
    }
}

private struct MockInstallationPingUploader: PingUploader {
    func upload(request: CapablePingUploadRequest, callback: @escaping @Sendable (UploadResult) -> Void) {
        callback(.httpStatus(code: 200))
    }
}
