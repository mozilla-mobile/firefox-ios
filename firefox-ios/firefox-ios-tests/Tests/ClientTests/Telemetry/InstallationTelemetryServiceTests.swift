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
        mockFeatureFlags = MockNimbusFeatureFlags()
        mockFeatureFlags.enabledFlags = [.checkForReinstalls]
        mockDateProvider = MockDateProvider(fixedDate: Date(timeIntervalSince1970: 1_760_000_000))
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

    func testOnForeground_whenTermsAreNotAccepted_waitsForAcceptance() async throws {
        profilePrefs.setBool(false, forKey: PrefsKeys.TermsOfUseAccepted)
        let subject = createSubject()
        try await subject.onForeground()
        XCTAssertEqual(mockHistoryStore.loadCalled, 0)
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 0)

        profilePrefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        try await subject.onForeground()
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
    }

    func testOnForeground_checksFeatureFlagBeforeAndAfterAcquisition() async throws {
        mockFeatureFlags.enabledFlags = []
        let subject = createSubject()
        XCTAssertNil(installationPrefs.boolForKey(PrefsKeys.installationProcessedKey))
        try await subject.onForeground()
        XCTAssertEqual(mockHistoryStore.loadCalled, 0)

        mockFeatureFlags.enabledFlags = [.checkForReinstalls]
        mockAcquisitionProvider.onFetch = { self.mockFeatureFlags.enabledFlags = [] }
        try await subject.onForeground()
        XCTAssertEqual(mockHistoryStore.saveCalled, 0)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)

        mockAcquisitionProvider.onFetch = nil
        mockFeatureFlags.enabledFlags = [.checkForReinstalls]
        try await subject.onForeground()
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
    }

    func testOnForeground_onFreshInstall_recordsMetricsOnce() async throws {
        let subject = createSubject()
        mockAcquisitionProvider.result = .available(
            AppAcquisition(originalPurchaseDate: mockDateProvider.fixedDate, originalAppVersion: "12345")
        )

        try await subject.onForeground()
        try await subject.onForeground()
        try await createSubject().onForeground()

        XCTAssertEqual(mockHistoryStore.value,
                       InstallationHistory(installCounter: 1, lastSeenDate: mockDateProvider.fixedDate))
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
        XCTAssertEqual(mockGleanWrapper.savedValues as? [String], ["2025-10-09", "12345"])
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 1)
    }

    func testOnForeground_onReinstall_recordsPreviousDateAndUpdatesHistory() async throws {
        mockHistoryStore.value = InstallationHistory(installCounter: 3, lastSeenDate: Date(timeIntervalSince1970: 0))

        try await createSubject().onForeground()

        XCTAssertEqual(mockHistoryStore.value,
                       InstallationHistory(installCounter: 4, lastSeenDate: mockDateProvider.fixedDate))
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [4])
        XCTAssertEqual(mockGleanWrapper.savedValues as? [String], ["1970-01-01"])
    }

    func testOnForeground_onExistingInstallation_initializesHistoryWithoutMetrics() async throws {
        try await createSubject(hasSeenIntro: true).onForeground()

        XCTAssertEqual(mockHistoryStore.value?.installCounter, 1)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 0)
    }

    func testOnForeground_onExistingInstallation_preservesCounter() async throws {
        mockHistoryStore.value = InstallationHistory(installCounter: 5, lastSeenDate: .distantPast)

        try await createSubject(hasSeenIntro: true).onForeground()

        XCTAssertEqual(mockHistoryStore.value,
                       InstallationHistory(installCounter: 5, lastSeenDate: mockDateProvider.fixedDate))
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
    }

    func testOnForeground_whenConsentIsPending_preservesStateAcrossServiceRecreation() async throws {
        profilePrefs.setBool(false, forKey: AppConstants.prefSendUsageData)
        let subject = createSubject()
        try await subject.onForeground()
        XCTAssertEqual(mockHistoryStore.loadCalled, 0)
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 0)

        let recreated = createSubject(hasSeenIntro: true)
        profilePrefs.setBool(true, forKey: AppConstants.prefSendUsageData)
        try await recreated.onForeground()

        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
    }

    func testOnForeground_whenAlreadyProcessed_doesNotRepeatWithUnfinishedOnboarding() async throws {
        try await createSubject().onForeground()
        try await createSubject(hasSeenIntro: false).onForeground()

        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 1)
    }

    func testOnForeground_whenConsentIsReenabled_updatesDateWithoutRepeatingMetrics() async throws {
        let subject = createSubject()
        try await subject.onForeground()
        profilePrefs.setBool(false, forKey: AppConstants.prefSendUsageData)
        mockDateProvider.fixedDate = mockDateProvider.fixedDate.addingTimeInterval(86_400)
        try await subject.onForeground()
        XCTAssertNotEqual(mockHistoryStore.value?.lastSeenDate, mockDateProvider.fixedDate)

        profilePrefs.setBool(true, forKey: AppConstants.prefSendUsageData)
        try await subject.onForeground()

        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
        XCTAssertEqual(mockHistoryStore.value?.lastSeenDate, mockDateProvider.fixedDate)
    }

    func testOnForeground_whenCallsOverlap_preservesPreviousDate() async throws {
        mockHistoryStore.value = InstallationHistory(installCounter: 2, lastSeenDate: Date(timeIntervalSince1970: 0))
        let subject = createSubject()
        mockAcquisitionProvider.onFetch = {
            try? await subject.onForeground()
            XCTAssertEqual(self.mockHistoryStore.saveCalled, 0)
        }

        try await subject.onForeground()

        XCTAssertEqual(mockHistoryStore.saveCalled, 1)
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 1)
        XCTAssertEqual(mockGleanWrapper.savedValues as? [String], ["1970-01-01"])
    }

    func testOnForeground_whenConsentIsRevokedDuringAcquisition_leavesProcessingPending() async throws {
        let previous = InstallationHistory(installCounter: 2, lastSeenDate: .distantPast)
        mockHistoryStore.value = previous
        let subject = createSubject()
        mockAcquisitionProvider.onFetch = { self.profilePrefs.setBool(false, forKey: AppConstants.prefSendUsageData) }
        try await subject.onForeground()
        XCTAssertEqual(mockHistoryStore.value, previous)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)

        mockAcquisitionProvider.onFetch = nil
        profilePrefs.setBool(true, forKey: AppConstants.prefSendUsageData)
        try await createSubject(hasSeenIntro: true).onForeground()
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [3])
    }

    func testOnForeground_whenSaveFails_leavesProcessingPendingAcrossLaunches() async throws {
        mockHistoryStore.saveError = InstallationHistoryError.keychain(-1)
        do {
            try await createSubject().onForeground()
            XCTFail("Expected the storage failure")
        } catch InstallationHistoryError.keychain(-1) {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)

        mockHistoryStore.saveError = nil
        try await createSubject(hasSeenIntro: true).onForeground()
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
    }

    func testOnForeground_whenLoadFails_doesNotProcessInstallation() async throws {
        mockHistoryStore.loadError = InstallationHistoryError.keychain(-1)
        do {
            try await createSubject().onForeground()
            XCTFail("Expected the storage failure")
        } catch InstallationHistoryError.keychain(-1) {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(mockHistoryStore.saveCalled, 0)
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 0)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
    }

    func testOnForeground_whenAcquisitionIsUnavailable_recordsDeviceHistoryOnly() async throws {
        for failure in [AcquisitionFailure.unsupportedOS, .unverified, .storeKitFailure] {
            installationPrefs.clearAll()
            mockHistoryStore.value = nil
            mockAcquisitionProvider.result = .unavailable(failure)
            let subject = createSubject()
            try await subject.onForeground()
            try await subject.onForeground()
        }
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1, 1, 1])
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 3)
        XCTAssertEqual(mockGleanWrapper.recordStringCalled, 0)
    }

    func testOnForeground_whenHistoryIsCorrupt_recordsAcquisitionWithoutOverwritingHistory() async throws {
        mockHistoryStore.isCorrupt = true
        mockAcquisitionProvider.result = .available(
            AppAcquisition(originalPurchaseDate: mockDateProvider.fixedDate, originalAppVersion: "42")
        )

        let subject = createSubject()
        try await subject.onForeground()
        try await subject.onForeground()
        try await createSubject(hasSeenIntro: true).onForeground()

        XCTAssertEqual(mockHistoryStore.saveCalled, 0)
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 1)
        XCTAssertEqual(mockGleanWrapper.recordQuantityCalled, 0)
        XCTAssertEqual(mockGleanWrapper.savedValues as? [String], ["2025-10-09", "42"])
        XCTAssertEqual(installationPrefs.boolForKey(PrefsKeys.installationProcessedKey), true)
    }

    func testOnForeground_whenHistoryIsCorruptAndAcquisitionIsUnavailable_recordsNoMetrics() async throws {
        mockHistoryStore.isCorrupt = true

        try await createSubject().onForeground()

        XCTAssertEqual(mockHistoryStore.saveCalled, 0)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
        XCTAssertEqual(installationPrefs.boolForKey(PrefsKeys.installationProcessedKey), true)
    }

    func testOnForeground_whenCounterCanReachMaximum_recordsMaximumCounter() async throws {
        mockHistoryStore.value = InstallationHistory(installCounter: Int64.max - 1, lastSeenDate: mockDateProvider.fixedDate)

        try await createSubject().onForeground()

        XCTAssertEqual(mockHistoryStore.value?.installCounter, Int64.max)
        XCTAssertEqual(mockHistoryStore.saveCalled, 1)
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [Int64.max])
    }

    func testOnForeground_whenCounterIsAtMaximum_skipsProcessing() async throws {
        let previous = InstallationHistory(installCounter: .max, lastSeenDate: mockDateProvider.fixedDate)
        mockHistoryStore.value = previous

        try await createSubject().onForeground()

        XCTAssertEqual(mockHistoryStore.value, previous)
        XCTAssertEqual(mockHistoryStore.saveCalled, 0)
        XCTAssertEqual(mockAcquisitionProvider.fetchCalled, 0)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
        XCTAssertEqual(mockGleanWrapper.recordQuantityCalled, 0)
        XCTAssertEqual(installationPrefs.boolForKey(PrefsKeys.installationProcessedKey), false)
    }

    func testOnForeground_whenProfilePreferencesAreCleared_doesNotRepeatProcessing() async throws {
        try await createSubject().onForeground()
        profilePrefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        profilePrefs.clearAll()
        profilePrefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)

        try await createSubject(hasSeenIntro: false).onForeground()

        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
    }

    func testOnForeground_whenAcquisitionIsCancelled_leavesProcessingPending() async throws {
        let subject = createSubject()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await subject.onForeground()
        }
        do {
            try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {} catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertEqual(mockHistoryStore.saveCalled, 0)
        XCTAssertTrue(mockGleanWrapper.savedEvents.isEmpty)
        try await createSubject(hasSeenIntro: true).onForeground()
        XCTAssertEqual(mockGleanWrapper.savedQuantities, [1])
    }

    func testOnForeground_afterBaselineSubmission_doesNotRecordInstallationMetricsAgain() async throws {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let configuration = Configuration(dataPath: path.path, httpClient: MockInstallationPingUploader())
        Glean.shared.enableTestingMode()
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
        mockHistoryStore.value = InstallationHistory(installCounter: 1, lastSeenDate: Date(timeIntervalSince1970: 0))
        mockAcquisitionProvider.result = .available(
            AppAcquisition(originalPurchaseDate: mockDateProvider.fixedDate, originalAppVersion: "42")
        )
        let subject = InstallationTelemetryService(profilePrefs: profilePrefs,
                                                   installationPrefs: installationPrefs,
                                                   history: mockHistoryStore,
                                                   acquisition: mockAcquisitionProvider,
                                                   gleanWrapper: DefaultGleanWrapper(),
                                                   featureFlagsProvider: mockFeatureFlags,
                                                   dateProvider: mockDateProvider)
        try await subject.onForeground()
        XCTAssertEqual(GleanMetrics.Installation.installCounter.testGetValue("baseline"), 2)
        XCTAssertEqual(GleanMetrics.Installation.lastSeenDate.testGetValue("baseline"), "1970-01-01")
        XCTAssertEqual(GleanMetrics.Installation.originalPurchaseDate.testGetValue("baseline"), "2025-10-09")
        XCTAssertEqual(GleanMetrics.Installation.originalAppVersion.testGetValue("baseline"), "42")

        XCTAssertTrue(gleanSubmitPingByNameSync("baseline", nil))
        XCTAssertNil(GleanMetrics.Installation.installCounter.testGetValue("baseline"))
        XCTAssertNil(GleanMetrics.Installation.lastSeenDate.testGetValue("baseline"))
        XCTAssertNil(GleanMetrics.Installation.originalPurchaseDate.testGetValue("baseline"))
        XCTAssertNil(GleanMetrics.Installation.originalAppVersion.testGetValue("baseline"))
        try await subject.onForeground()
        XCTAssertTrue(gleanSubmitPingByNameSync("baseline", nil))

        let pings = gleanGetStoredSubmittedPingsByName("baseline")
        XCTAssertEqual(pings.count, 2)
        XCTAssertEqual(pings.filter { $0.payload?.contains("installation.install_counter") == true }.count, 1)
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
                                            gleanWrapper: mockGleanWrapper,
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
