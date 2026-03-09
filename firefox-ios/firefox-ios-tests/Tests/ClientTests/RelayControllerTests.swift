// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import MozillaAppServices
import Account
import Shared
import Common
@testable import Client

@MainActor
class RelayControllerTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    // MARK: - RelayControllerProtocol Tests

    func test_relayController_doesNotShowPromptOrSettings_withoutAccount() {
        let subject = createSubject()

        XCTAssertFalse(subject.shouldDisplayRelaySettings())
    }

    func test_relayController_showsSettings_ifAccountAvailable() {
        let subject = createSubject(accountStatus: .available)

        XCTAssertTrue(subject.shouldDisplayRelaySettings())
    }

    func test_relayShouldDisplayPrompt_forValidAllowListURL() {
        let subject = createSubject(accountStatus: .available)

        XCTAssertTrue(subject.emailFocusShouldDisplayRelayPrompt(url: URL(string: "https://goodwebsite.com")!))
    }

    func test_relayShouldNotDisplayPrompt_forBlockListURL() {
        let subject = createSubject(accountStatus: .available)

        XCTAssertFalse(subject.emailFocusShouldDisplayRelayPrompt(url: URL(string: "https://badwebsite.com")!))
    }

    func test_relayPopulateField_generatesMaskAndCallsCompletionBlock() {
        let subject = createSubject(accountStatus: .available)

        let mockTab = MockTab(profile: AppContainer.shared.resolve(), windowUUID: .XCTestDefaultUUID)
        mockTab.webView = MockTabWebView(tab: mockTab)

        let expectation = expectation(description: "Completion called")

        subject.populateEmailFieldWithRelayMask(for: mockTab) { result in
            XCTAssertEqual(result, .newMaskGenerated)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func test_relayPopulateField_succeedsIfFocusedOnCorrectTab() {
        let subject = createSubject(accountStatus: .available)

        let mockTab1 = MockTab(profile: AppContainer.shared.resolve(), windowUUID: .XCTestDefaultUUID)
        mockTab1.webView = MockTabWebView(tab: mockTab1)

        let mockTab2 = MockTab(profile: AppContainer.shared.resolve(), windowUUID: .XCTestDefaultUUID)
        mockTab2.webView = MockTabWebView(tab: mockTab2)

        subject.emailFieldFocused(in: mockTab1)

        let expectation = expectation(description: "Completion called")

        subject.populateEmailFieldWithRelayMask(for: mockTab1) { result in
            XCTAssertEqual(result, .newMaskGenerated)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func test_relayPopulateField_isAbortedIfFocusedOnWrongTab() {
        let subject = createSubject(accountStatus: .available)

        let mockTab1 = MockTab(profile: AppContainer.shared.resolve(), windowUUID: .XCTestDefaultUUID)
        mockTab1.webView = MockTabWebView(tab: mockTab1)

        let mockTab2 = MockTab(profile: AppContainer.shared.resolve(), windowUUID: .XCTestDefaultUUID)
        mockTab2.webView = MockTabWebView(tab: mockTab2)

        subject.emailFieldFocused(in: mockTab2)

        let expectation = expectation(description: "Completion not called")
        expectation.isInverted = true

        subject.populateEmailFieldWithRelayMask(for: mockTab1) { result in
            // Note: we do _not_ expect the completion to run in this scenario
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    // MARK: - Subject

    func createSubject(accountStatus: RelayAccountStatus = .unknown) -> RelayController {
        let subject =  RelayController(logger: MockLogger(),
                                       profile: AppContainer.shared.resolve(),
                                       relayClient: MockRelayClient(),
                                       relayRSClient: MockRelayRemoteSettingsClient(),
                                       relayAccountStatusProvider: MockRelayAccountStatusProvider(mockValue: accountStatus),
                                       gleanWrapper: MockGleanWrapper(),
                                       config: .prod,
                                       notificationCenter: MockNotificationCenter())
        trackForMemoryLeaks(subject)
        return subject
    }
}

struct MockRelayAddress {
    static let mockAddress1 = RelayAddress(
        maskType: "",
        enabled: true,
        description: "description",
        generatedFor: "etsy.com",
        blockListEmails: false,
        usedOn: nil,
        id: 1234,
        address: "",
        domain: 0,
        fullAddress: "test@mock.com",
        createdAt: "",
        lastModifiedAt: "",
        lastUsedAt: nil,
        numForwarded: 0,
        numBlocked: 0,
        numLevelOneTrackersBlocked: 0,
        numReplied: 0,
        numSpam: 0
    )
}

final class MockRelayRemoteSettingsClient: RelayRemoteSettingsClientProtocol {
    let mockShouldShowValue = true

    func shouldShowRelay(host: String, domain: String, isRelayUser: Bool) -> Bool {
        return domain == "goodwebsite.com"
    }
}

final class MockRelayClient: RelayClientProtocol {
    func acceptTerms() throws { }

    func createAddress(description: String, generatedFor: String, usedOn: String) throws -> MozillaAppServices.RelayAddress {
        return MockRelayAddress.mockAddress1
    }

    func fetchAddresses() throws -> [MozillaAppServices.RelayAddress] {
        return [MockRelayAddress.mockAddress1]
    }

    func fetchProfile() throws -> MozillaAppServices.RelayProfile {
        fatalError() // Currently unused in unit tests.
    }
}

final class MockRelayAccountStatusProvider: RelayAccountStatusProvider {
    let mockValue: RelayAccountStatus
    var wrappedValue: RelayAccountStatus = .unknown

    init(mockValue: RelayAccountStatus) {
        self.mockValue = mockValue
    }

    var accountStatus: RelayAccountStatus {
        get { return mockValue }
        set { wrappedValue = newValue }
    }
}
