// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import TestKit
import MLPAKit
import Shared

@testable import LLMKit

final class LiteLLMCreatorTests: XCTestCase {
    private var mockKeyStore: MockAppAttestKeyIDStore!
    private var mockPrefs: MockProfilePrefs!

    override func setUp() {
        super.setUp()
        mockKeyStore = MockAppAttestKeyIDStore()
        mockPrefs = MockProfilePrefs()
    }

    override func tearDown() {
        mockKeyStore = nil
        mockPrefs = nil
        super.tearDown()
    }

    // MARK: - Successful Creation Tests

    func testCreateAppAttestLiteLLM_withProdEnvironment_returnsClient() {
        mockPrefs.setString(MLPAEnvironment.prod.rawValue, forKey: PrefsKeys.MLPASettings.mlpaEndpointEnvironment)

        let subject = createSubject()
        let result = subject.createAppAttestLiteLLM(
            using: mockPrefs,
            serviceType: .quickAnswers
        )

        XCTAssertNotNil(result, "Should create LiteLLM client with prod environment")
        XCTAssertEqual(
            mockPrefs.stringForKey(PrefsKeys.MLPASettings.lastUsedEnvironment),
            MLPAEnvironment.prod.rawValue,
            "Should store the last used environment"
        )
    }

    func testCreateAppAttestLiteLLM_withDevEnvironment_returnsClient() {
        mockPrefs.setString(MLPAEnvironment.dev.rawValue, forKey: PrefsKeys.MLPASettings.mlpaEndpointEnvironment)

        let subject = createSubject()
        let result = subject.createAppAttestLiteLLM(
            using: mockPrefs,
            serviceType: .quickAnswers
        )

        XCTAssertNotNil(result, "Should create LiteLLM client with dev environment")
        XCTAssertEqual(
            mockPrefs.stringForKey(PrefsKeys.MLPASettings.lastUsedEnvironment),
            MLPAEnvironment.dev.rawValue,
            "Should store the last used environment"
        )
    }

    func testCreateAppAttestLiteLLM_withStageEnvironment_returnsClient() {
        mockPrefs.setString(MLPAEnvironment.stage.rawValue, forKey: PrefsKeys.MLPASettings.mlpaEndpointEnvironment)

        let subject = createSubject()
        let result = subject.createAppAttestLiteLLM(
            using: mockPrefs,
            serviceType: .quickAnswers
        )

        XCTAssertNotNil(result, "Should create LiteLLM client with stage environment")
        XCTAssertEqual(
            mockPrefs.stringForKey(PrefsKeys.MLPASettings.lastUsedEnvironment),
            MLPAEnvironment.stage.rawValue,
            "Should store the last used environment"
        )
    }

    func testCreateAppAttestLiteLLM_withNoEnvironmentSet_defaultsToProdAndReturnsClient() {
        let subject = createSubject()
        let result = subject.createAppAttestLiteLLM(
            using: mockPrefs,
            serviceType: .quickAnswers
        )

        XCTAssertNotNil(result, "Should create LiteLLM client with default prod environment")
        XCTAssertEqual(
            mockPrefs.stringForKey(PrefsKeys.MLPASettings.lastUsedEnvironment),
            MLPAEnvironment.prod.rawValue,
            "Should default to prod environment and store it"
        )
    }

    func testCreateAppAttestLiteLLM_withInvalidEnvironment_defaultsToProdAndReturnsClient() {
        mockPrefs.setString("invalid-environment", forKey: PrefsKeys.MLPASettings.mlpaEndpointEnvironment)

        let subject = createSubject()
        let result = subject.createAppAttestLiteLLM(
            using: mockPrefs,
            serviceType: .quickAnswers
        )

        XCTAssertNotNil(result, "Should create LiteLLM client with default prod environment")
        XCTAssertEqual(
            mockPrefs.stringForKey(PrefsKeys.MLPASettings.lastUsedEnvironment),
            MLPAEnvironment.prod.rawValue,
            "Should default to prod environment when invalid value is provided"
        )
    }

    func testCreateAppAttestLiteLLM_withS2SServiceType_returnsClient() {
        mockPrefs.setString(MLPAEnvironment.prod.rawValue, forKey: PrefsKeys.MLPASettings.mlpaEndpointEnvironment)

        let subject = createSubject()
        let result = subject.createAppAttestLiteLLM(
            using: mockPrefs,
            serviceType: .s2s
        )

        XCTAssertNotNil(result, "Should create LiteLLM client with s2s service type")
    }

    // MARK: - Environment Change Tests

    func testCreateAppAttestLiteLLM_whenEnvironmentChanges_clearsKey() throws {
        mockPrefs.setString(MLPAEnvironment.prod.rawValue, forKey: PrefsKeys.MLPASettings.mlpaEndpointEnvironment)
        mockPrefs.setString(MLPAEnvironment.dev.rawValue, forKey: PrefsKeys.MLPASettings.lastUsedEnvironment)
        try mockKeyStore.saveKeyID("existing-key-id")

        let subject = createSubject()
        _ = subject.createAppAttestLiteLLM(
            using: mockPrefs,
            serviceType: .quickAnswers
        )

        XCTAssertNil(mockKeyStore.loadKeyID(), "Should clear key when environment changes")
        XCTAssertEqual(
            mockPrefs.stringForKey(PrefsKeys.MLPASettings.lastUsedEnvironment),
            MLPAEnvironment.prod.rawValue,
            "Should update last used environment"
        )
    }

    func testCreateAppAttestLiteLLM_whenEnvironmentChangesProdToStage_clearsKey() throws {
        mockPrefs.setString(MLPAEnvironment.stage.rawValue, forKey: PrefsKeys.MLPASettings.mlpaEndpointEnvironment)
        mockPrefs.setString(MLPAEnvironment.prod.rawValue, forKey: PrefsKeys.MLPASettings.lastUsedEnvironment)
        try mockKeyStore.saveKeyID("existing-key-id")

        let subject = createSubject()
        _ = subject.createAppAttestLiteLLM(
            using: mockPrefs,
            serviceType: .quickAnswers
        )

        XCTAssertNil(mockKeyStore.loadKeyID(), "Should clear key when environment changes from prod to stage")
        XCTAssertEqual(
            mockPrefs.stringForKey(PrefsKeys.MLPASettings.lastUsedEnvironment),
            MLPAEnvironment.stage.rawValue,
            "Should update last used environment"
        )
    }

    func testCreateAppAttestLiteLLM_whenEnvironmentSameAsPrevious_doesNotClearKey() throws {
        mockPrefs.setString(MLPAEnvironment.prod.rawValue, forKey: PrefsKeys.MLPASettings.mlpaEndpointEnvironment)
        mockPrefs.setString(MLPAEnvironment.prod.rawValue, forKey: PrefsKeys.MLPASettings.lastUsedEnvironment)
        let existingKeyID = "existing-key-id"
        try mockKeyStore.saveKeyID(existingKeyID)

        let subject = createSubject()
        _ = subject.createAppAttestLiteLLM(
            using: mockPrefs,
            serviceType: .quickAnswers
        )

        XCTAssertEqual(
            mockKeyStore.loadKeyID(),
            existingKeyID,
            "Should not clear key when environment remains the same"
        )
        XCTAssertEqual(
            mockPrefs.stringForKey(PrefsKeys.MLPASettings.lastUsedEnvironment),
            MLPAEnvironment.prod.rawValue,
            "Should keep last used environment"
        )
    }

    func testCreateAppAttestLiteLLM_whenNoLastUsedEnvironment_doesNotClearKey() throws {
        mockPrefs.setString(MLPAEnvironment.prod.rawValue, forKey: PrefsKeys.MLPASettings.mlpaEndpointEnvironment)
        let existingKeyID = "existing-key-id"
        try mockKeyStore.saveKeyID(existingKeyID)

        let subject = createSubject()
        _ = subject.createAppAttestLiteLLM(
            using: mockPrefs,
            serviceType: .quickAnswers
        )

        XCTAssertEqual(
            mockKeyStore.loadKeyID(),
            existingKeyID,
            "Should not clear key when no last used environment exists"
        )
        XCTAssertEqual(
            mockPrefs.stringForKey(PrefsKeys.MLPASettings.lastUsedEnvironment),
            MLPAEnvironment.prod.rawValue,
            "Should set last used environment"
        )
    }

    // MARK: - Edge Cases

    func testCreateAppAttestLiteLLM_multipleCallsSameEnvironment_doesNotClearKeyMultipleTimes() throws {
        mockPrefs.setString(MLPAEnvironment.prod.rawValue, forKey: PrefsKeys.MLPASettings.mlpaEndpointEnvironment)
        let existingKeyID = "existing-key-id"
        try mockKeyStore.saveKeyID(existingKeyID)

        let subject = createSubject()
        _ = subject.createAppAttestLiteLLM(
            using: mockPrefs,
            serviceType: .quickAnswers
        )
        _ = subject.createAppAttestLiteLLM(
            using: mockPrefs,
            serviceType: .quickAnswers
        )
        _ = subject.createAppAttestLiteLLM(
            using: mockPrefs,
            serviceType: .quickAnswers
        )

        XCTAssertEqual(
            mockKeyStore.loadKeyID(),
            existingKeyID,
            "Should not clear key on multiple calls with same environment"
        )
    }

    func testCreateAppAttestLiteLLM_multipleCallsDifferentEnvironments_clearsKeyEachTime() throws {
        let existingKeyID = "existing-key-id"
        let subject = createSubject()

        mockPrefs.setString(MLPAEnvironment.prod.rawValue, forKey: PrefsKeys.MLPASettings.mlpaEndpointEnvironment)
        _ = subject.createAppAttestLiteLLM(
            using: mockPrefs,
            serviceType: .quickAnswers
        )
        try mockKeyStore.saveKeyID(existingKeyID)

        mockPrefs.setString(MLPAEnvironment.dev.rawValue, forKey: PrefsKeys.MLPASettings.mlpaEndpointEnvironment)
        _ = subject.createAppAttestLiteLLM(
            using: mockPrefs,
            serviceType: .quickAnswers
        )
        XCTAssertNil(mockKeyStore.loadKeyID(), "Should clear key when switching from prod to dev")
        try mockKeyStore.saveKeyID(existingKeyID)

        mockPrefs.setString(MLPAEnvironment.stage.rawValue, forKey: PrefsKeys.MLPASettings.mlpaEndpointEnvironment)
        _ = subject.createAppAttestLiteLLM(
            using: mockPrefs,
            serviceType: .quickAnswers
        )
        XCTAssertNil(mockKeyStore.loadKeyID(), "Should clear key when switching from dev to stage")
    }

    private func createSubject() -> LiteLLMCreator {
        return LiteLLMCreator(
            keyStore: mockKeyStore,
            appAttestService: MockAppAttestService(
                isSupported: true
            ),
            bundleIdentifier: "testBundleId"
        )
    }
}
