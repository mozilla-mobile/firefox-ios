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
    private var mockAcquisitionProvider: MockAppAcquisitionProvider!
    private var mockGleanWrapper: MockGleanWrapper!
    private var profilePrefs: MockProfilePrefs!
    private var mockFeatureFlags: MockNimbusFeatureFlags!
    private var mockDateProvider: MockDateProvider!

    override func setUp() async throws {
        try await super.setUp()
        installationPrefs = MockProfilePrefs()
        mockHistoryStore = MockInstallationHistoryStore()
        mockAcquisitionProvider = MockAppAcquisitionProvider()
        mockGleanWrapper = MockGleanWrapper()
        profilePrefs = MockProfilePrefs()
        profilePrefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        profilePrefs.setBool(true, forKey: AppConstants.prefSendUsageData)
        mockFeatureFlags = MockNimbusFeatureFlags()
        mockFeatureFlags.enabledFlags = [.checkForReinstalls]
        mockDateProvider = MockDateProvider(fixedDate: Date(timeIntervalSince1970: 1_760_000_000))
        mockAcquisitionProvider.result = .available(
            AppAcquisition(originalPurchaseDate: mockDateProvider.fixedDate, originalAppVersion: "42")
        )
    }

    override func tearDown() async throws {
        profilePrefs = nil
        mockFeatureFlags = nil
        installationPrefs = nil
        mockHistoryStore = nil
        mockAcquisitionProvider = nil
        mockGleanWrapper = nil
        mockDateProvider = nil
        try await super.tearDown()
    }

    func testUpdateInstallationHistory_whenUsagePreferenceIsMissing_waitsForConsent() async throws {
        profilePrefs.removeObjectForKey(AppConstants.prefSendUsageData)
        let subject = createSubject()

        try await subject.updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.loadCalled, 0)
        XCTAssertEqual(mockHistoryStore.saveCalled, 0)
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 0)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
        XCTAssertTrue(mockGleanWrapper.savedQuantities.isEmpty)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 0)

        profilePrefs.setBool(true, forKey: AppConstants.prefSendUsageData)
        try await subject.updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.value?.installCounter, 1)
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 1)
    }

    func testUpdateInstallationHistory_whenTermsPreferenceIsMissing_waitsForAcceptance() async throws {
        profilePrefs.removeObjectForKey(PrefsKeys.TermsOfUseAccepted)
        let subject = createSubject()

        try await subject.updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.loadCalled, 0)
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 0)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 0)

        profilePrefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        try await subject.updateInstallationHistory()
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
    }

    func testUpdateInstallationHistory_whenTermsAreNotAccepted_waitsForAcceptance() async throws {
        profilePrefs.setBool(false, forKey: PrefsKeys.TermsOfUseAccepted)
        let subject = createSubject()
        try await subject.updateInstallationHistory()
        XCTAssertEqual(mockHistoryStore.loadCalled, 0)
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 0)

        profilePrefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        try await subject.updateInstallationHistory()
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
    }

    func testUpdateInstallationHistory_checksFeatureFlagBeforeAndAfterAcquisition() async throws {
        mockFeatureFlags.enabledFlags = []
        let subject = createSubject()
        XCTAssertNil(installationPrefs.boolForKey(PrefsKeys.installationProcessedKey))
        try await subject.updateInstallationHistory()
        XCTAssertEqual(mockHistoryStore.loadCalled, 0)

        mockFeatureFlags.enabledFlags = [.checkForReinstalls]
        mockAcquisitionProvider.onFetch = { self.mockFeatureFlags.enabledFlags = [] }
        try await subject.updateInstallationHistory()
        XCTAssertEqual(mockHistoryStore.saveCalled, 0)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)

        mockAcquisitionProvider.onFetch = nil
        mockFeatureFlags.enabledFlags = [.checkForReinstalls]
        try await subject.updateInstallationHistory()
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
    }

    func testUpdateInstallationHistory_onFreshInstall_recordsMetricsOnce() async throws {
        let subject = createSubject()
        mockAcquisitionProvider.result = .available(
            AppAcquisition(originalPurchaseDate: mockDateProvider.fixedDate, originalAppVersion: "12345")
        )

        try await subject.updateInstallationHistory()
        try await subject.updateInstallationHistory()
        try await createSubject().updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.value,
                       InstallationHistory(installCounter: 1, lastSeenDate: mockDateProvider.fixedDate))
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
        let savedDate = try XCTUnwrap(mockGleanWrapper.savedValues.first as? Date)
        let savedDateMetric = try XCTUnwrap(mockGleanWrapper.savedEvents[1] as? DatetimeMetricType)
        XCTAssertEqual(mockGleanWrapper.recordDatetimeCalled, 1)
        XCTAssertEqual(savedDate, mockDateProvider.fixedDate)
        XCTAssertEqual(mockGleanWrapper.savedValues.last as? String, "12345")
        XCTAssert(savedDateMetric === GleanMetrics.Installation.originalPurchaseDate)
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 1)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 1)
        XCTAssertTrue(mockGleanWrapper.savedPing as? Ping<NoReasonCodes> === GleanMetrics.Pings.shared.installation)
    }

    func testUpdateInstallationHistory_onReinstall_recordsPreviousDateAndUpdatesHistory() async throws {
        mockHistoryStore.value = InstallationHistory(installCounter: 3, lastSeenDate: Date(timeIntervalSince1970: 0))

        try await createSubject().updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.loadCalled, 1)
        XCTAssertEqual(mockHistoryStore.saveCalled, 1)
        XCTAssertEqual(mockHistoryStore.value,
                       InstallationHistory(installCounter: 4, lastSeenDate: mockDateProvider.fixedDate))
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [4])
        XCTAssertEqual(mockGleanWrapper.savedValues.first as? Date, Date(timeIntervalSince1970: 0))
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 1)
    }

    func testUpdateInstallationHistory_onExistingInstallation_initializesHistoryWithoutMetrics() async throws {
        try await createSubject(hasSeenIntro: true).updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.value?.installCounter, 1)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 0)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 0)
    }

    func testUpdateInstallationHistory_onExistingInstallation_preservesCounter() async throws {
        mockHistoryStore.value = InstallationHistory(installCounter: 5, lastSeenDate: .distantPast)

        try await createSubject(hasSeenIntro: true).updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.loadCalled, 1)
        XCTAssertEqual(mockHistoryStore.saveCalled, 1)
        XCTAssertEqual(mockHistoryStore.value,
                       InstallationHistory(installCounter: 5, lastSeenDate: mockDateProvider.fixedDate))
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
    }

    func testUpdateInstallationHistory_whenConsentIsPending_preservesStateAcrossServiceRecreation() async throws {
        profilePrefs.setBool(false, forKey: AppConstants.prefSendUsageData)
        let subject = createSubject()
        try await subject.updateInstallationHistory()
        XCTAssertEqual(mockHistoryStore.loadCalled, 0)
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 0)

        let recreated = createSubject(hasSeenIntro: true)
        profilePrefs.setBool(true, forKey: AppConstants.prefSendUsageData)
        try await recreated.updateInstallationHistory()

        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
    }

    func testUpdateInstallationHistory_whenAlreadyProcessed_doesNotRepeatWithUnfinishedOnboarding() async throws {
        try await createSubject().updateInstallationHistory()
        try await createSubject(hasSeenIntro: false).updateInstallationHistory()

        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 1)
    }

    func testUpdateInstallationHistory_whenConsentIsReenabled_updatesDateWithoutRepeatingMetrics() async throws {
        let subject = createSubject()
        try await subject.updateInstallationHistory()
        profilePrefs.setBool(false, forKey: AppConstants.prefSendUsageData)
        mockDateProvider.fixedDate = mockDateProvider.fixedDate.addingTimeInterval(86_400)
        try await subject.updateInstallationHistory()
        XCTAssertNotEqual(mockHistoryStore.value?.lastSeenDate, mockDateProvider.fixedDate)

        profilePrefs.setBool(true, forKey: AppConstants.prefSendUsageData)
        try await subject.updateInstallationHistory()

        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
        XCTAssertEqual(mockHistoryStore.value?.lastSeenDate, mockDateProvider.fixedDate)
    }

    func testUpdateInstallationHistory_whenCallsOverlap_preservesPreviousDate() async throws {
        mockHistoryStore.value = InstallationHistory(installCounter: 2, lastSeenDate: Date(timeIntervalSince1970: 0))
        let subject = createSubject()
        mockAcquisitionProvider.onFetch = {
            try? await subject.updateInstallationHistory()
            XCTAssertEqual(self.mockHistoryStore.saveCalled, 0)
        }

        try await subject.updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.saveCalled, 1)
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 1)
        XCTAssertEqual(mockGleanWrapper.savedValues.first as? Date, Date(timeIntervalSince1970: 0))
    }

    func testUpdateInstallationHistory_whenConsentIsRevokedDuringAcquisition_leavesProcessingPending() async throws {
        let previous = InstallationHistory(installCounter: 2, lastSeenDate: .distantPast)
        mockHistoryStore.value = previous
        let subject = createSubject()
        mockAcquisitionProvider.onFetch = { self.profilePrefs.setBool(false, forKey: AppConstants.prefSendUsageData) }
        try await subject.updateInstallationHistory()
        XCTAssertEqual(mockHistoryStore.value, previous)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 0)

        mockAcquisitionProvider.onFetch = nil
        profilePrefs.setBool(true, forKey: AppConstants.prefSendUsageData)
        try await createSubject(hasSeenIntro: true).updateInstallationHistory()
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [3])
    }

    func testUpdateInstallationHistory_whenSaveFails_leavesProcessingPendingAcrossLaunches() async throws {
        mockHistoryStore.saveError = InstallationHistoryError.keychain(-1)
        do {
            try await createSubject().updateInstallationHistory()
            XCTFail("Expected the storage failure")
        } catch InstallationHistoryError.keychain(-1) {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertNil(mockHistoryStore.value)
        XCTAssertEqual(installationPrefs.boolForKey(PrefsKeys.installationProcessedKey), false)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 0)

        mockHistoryStore.saveError = nil
        try await createSubject(hasSeenIntro: true).updateInstallationHistory()
        XCTAssertEqual(mockHistoryStore.value?.installCounter, 1)
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1, 1])
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 1)
    }

    func testUpdateInstallationHistory_whenLoadFails_doesNotProcessInstallation() async throws {
        mockHistoryStore.loadError = InstallationHistoryError.keychain(-1)
        do {
            try await createSubject().updateInstallationHistory()
            XCTFail("Expected the storage failure")
        } catch InstallationHistoryError.keychain(-1) {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(mockHistoryStore.saveCalled, 0)
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 0)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
    }

    func testUpdateInstallationHistory_whenAcquisitionIsUnavailable_preservesHistoryAndRetriesOnce() async throws {
        let previous = InstallationHistory(installCounter: 3, lastSeenDate: .distantPast)
        for failure in [AcquisitionFailure.unsupportedOS, .unverified, .storeKitFailure] {
            installationPrefs.clearAll()
            mockHistoryStore.value = previous
            mockAcquisitionProvider.result = .unavailable(failure)
            let subject = createSubject()
            do {
                try await subject.updateInstallationHistory()
                XCTFail("Expected the acquisition failure")
            } catch is AcquisitionFailure {} catch {
                XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(mockHistoryStore.value, previous)
            XCTAssertEqual(installationPrefs.boolForKey(PrefsKeys.installationProcessedKey), false)
        }
        XCTAssertEqual(mockHistoryStore.saveCalled, 0)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 0)

        mockAcquisitionProvider.result = .available(
            AppAcquisition(originalPurchaseDate: mockDateProvider.fixedDate, originalAppVersion: "42")
        )
        let subject = createSubject()
        try await subject.updateInstallationHistory()
        try await subject.updateInstallationHistory()
        XCTAssertEqual(mockHistoryStore.value?.installCounter, 4)
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [4])
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 1)
    }

    func testUpdateInstallationHistory_whenHistoryIsCorrupt_replacesHistoryAfterAcquisition() async throws {
        mockHistoryStore.isCorrupt = true
        let subject = createSubject()

        try await subject.updateInstallationHistory()
        try await subject.updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.value,
                       InstallationHistory(installCounter: 1, lastSeenDate: mockDateProvider.fixedDate))
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 1)
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
        XCTAssertEqual(mockGleanWrapper.recordDatetimeCalled, 1)
        XCTAssertEqual(mockGleanWrapper.savedValues.first as? Date, mockDateProvider.fixedDate)
        XCTAssertEqual(mockGleanWrapper.savedValues.last as? String, "42")
        XCTAssertEqual(installationPrefs.boolForKey(PrefsKeys.installationProcessedKey), true)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 1)
    }

    func testUpdateInstallationHistory_whenHistoryIsCorruptAndAcquisitionFails_leavesProcessingPending() async throws {
        mockHistoryStore.isCorrupt = true
        mockAcquisitionProvider.result = .unavailable(.storeKitFailure)

        do {
            try await createSubject().updateInstallationHistory()
            XCTFail("Expected the acquisition failure")
        } catch is AcquisitionFailure {} catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(mockHistoryStore.saveCalled, 0)
        XCTAssertTrue(mockHistoryStore.isCorrupt)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
        XCTAssertEqual(installationPrefs.boolForKey(PrefsKeys.installationProcessedKey), false)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 0)
    }

    func testUpdateInstallationHistory_whenProcessedHistoryIsCorrupt_resetsHistoryWithoutMetrics() async throws {
        mockHistoryStore.isCorrupt = true

        try await createSubject(hasSeenIntro: true).updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.value,
                       InstallationHistory(installCounter: 1, lastSeenDate: mockDateProvider.fixedDate))
        XCTAssertEqual(mockHistoryStore.saveCalled, 1)
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 0)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 0)
    }

    func testUpdateInstallationHistory_whenLastSeenRefreshFails_doesNotRepeatMetrics() async throws {
        let subject = createSubject(hasSeenIntro: true)
        mockHistoryStore.saveError = InstallationHistoryError.keychain(-1)

        do {
            try await subject.updateInstallationHistory()
            XCTFail("Expected the storage failure")
        } catch InstallationHistoryError.keychain(-1) {} catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 0)
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 0)
        XCTAssertEqual(installationPrefs.boolForKey(PrefsKeys.installationProcessedKey), true)
    }

    func testUpdateInstallationHistory_whenCounterCanReachMaximum_recordsMaximumCounter() async throws {
        mockHistoryStore.value = InstallationHistory(installCounter: Int64.max - 1, lastSeenDate: mockDateProvider.fixedDate)

        try await createSubject().updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.value?.installCounter, Int64.max)
        XCTAssertEqual(mockHistoryStore.saveCalled, 1)
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [Int64.max])
    }

    func testUpdateInstallationHistory_whenCounterIsAtMaximum_preservesMaximumCounter() async throws {
        mockHistoryStore.value = InstallationHistory(installCounter: .max, lastSeenDate: .distantPast)

        try await createSubject().updateInstallationHistory()

        XCTAssertEqual(mockHistoryStore.value,
                       InstallationHistory(installCounter: .max, lastSeenDate: mockDateProvider.fixedDate))
        XCTAssertEqual(mockHistoryStore.saveCalled, 1)
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [Int64.max])
        XCTAssertEqual(mockGleanWrapper.submitPingCalled, 1)
        XCTAssertEqual(installationPrefs.boolForKey(PrefsKeys.installationProcessedKey), true)
    }

    func testUpdateInstallationHistory_whenProfilePreferencesAreCleared_doesNotRepeatProcessing() async throws {
        try await createSubject().updateInstallationHistory()
        profilePrefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        profilePrefs.clearAll()
        profilePrefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        profilePrefs.setBool(true, forKey: AppConstants.prefSendUsageData)

        try await createSubject(hasSeenIntro: false).updateInstallationHistory()

        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
    }

    func testUpdateInstallationHistory_whenAcquisitionIsCancelled_leavesProcessingPending() async throws {
        let subject = createSubject()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await subject.updateInstallationHistory()
        }
        do {
            try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {} catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertEqual(mockHistoryStore.saveCalled, 0)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
        try await createSubject(hasSeenIntro: true).updateInstallationHistory()
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
        mockAcquisitionProvider.result = .available(
            AppAcquisition(originalPurchaseDate: mockDateProvider.fixedDate, originalAppVersion: "42")
        )
        let subject = InstallationTelemetryService(profilePrefs: profilePrefs,
                                                   installationPrefs: installationPrefs,
                                                   history: mockHistoryStore,
                                                   acquisition: mockAcquisitionProvider,
                                                   featureFlagsProvider: mockFeatureFlags,
                                                   dateProvider: mockDateProvider)
        let pingSubmitted = expectation(description: "The installation ping was sent")
        let purchaseDate = mockDateProvider.fixedDate
        GleanMetrics.Pings.shared.installation.testBeforeNextSubmit { _ in
            XCTAssertEqual(self.mockHistoryStore.value,
                           InstallationHistory(installCounter: 2, lastSeenDate: self.mockDateProvider.fixedDate))
            XCTAssertEqual(self.installationPrefs.boolForKey(PrefsKeys.installationProcessedKey), false)
            XCTAssertEqual(GleanMetrics.Installation.originalPurchaseDate.testGetValue("installation"),
                           Calendar.current.startOfDay(for: purchaseDate))
            XCTAssertEqual(GleanMetrics.Installation.lastSeenDate.testGetValue("installation"),
                           previousDate)
            pingSubmitted.fulfill()
        }

        try await subject.updateInstallationHistory()
        await fulfillment(of: [pingSubmitted], timeout: 5.0)
        XCTAssertNil(GleanMetrics.Installation.installCounter.testGetValue("installation"))
        XCTAssertNil(GleanMetrics.Installation.lastSeenDate.testGetValue("installation"))
        XCTAssertNil(GleanMetrics.Installation.originalPurchaseDate.testGetValue("installation"))
        XCTAssertNil(GleanMetrics.Installation.originalAppVersion.testGetValue("installation"))

        let pings = gleanGetStoredSubmittedPingsByName("installation")
        XCTAssertEqual(pings.count, 1)
        let payload = try XCTUnwrap(pings.first?.payload)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [String: Any])
        let metrics = try XCTUnwrap(json["metrics"] as? [String: Any])
        let quantities = try XCTUnwrap(metrics["quantity"] as? [String: Any])
        XCTAssertEqual(quantities["installation.install_counter"] as? Int, 2)
        let strings = try XCTUnwrap(metrics["string"] as? [String: Any])
        XCTAssertEqual(strings["installation.original_app_version"] as? String, "42")
        XCTAssertNil(strings["installation.last_seen_date"])
        XCTAssertNil(strings["installation.original_purchase_date"])
        let datetimes = try XCTUnwrap(metrics["datetime"] as? [String: Any])
        let lastSeenDate = try XCTUnwrap(datetimes["installation.last_seen_date"] as? String)
        let originalPurchaseDate = try XCTUnwrap(datetimes["installation.original_purchase_date"] as? String)
        XCTAssertEqual(ISO8601DateFormatter().date(from: lastSeenDate), previousDate)
        XCTAssertFalse(originalPurchaseDate.contains("T"))

        try await subject.updateInstallationHistory()
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
                                            acquisition: mockAcquisitionProvider,
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

@MainActor
private final class MockAppAcquisitionProvider: AppAcquisitionProviding {
    var result: AcquisitionOutcome = .unavailable(.storeKitFailure)
    var onFetch: (() async -> Void)?
    var fetchCalled = 0

    func fetch() async -> AcquisitionOutcome {
        fetchCalled += 1
        await onFetch?()
        return result
    }
}

private struct MockInstallationPingUploader: PingUploader {
    func upload(request: CapablePingUploadRequest, callback: @escaping @Sendable (UploadResult) -> Void) {
        callback(.httpStatus(code: 200))
    }
}
