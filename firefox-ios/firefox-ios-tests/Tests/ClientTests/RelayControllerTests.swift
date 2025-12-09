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
        return mockShouldShowValue
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

@MainActor
class RelayControllerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    // MARK: - Tests

    func testRelayControllerByDefaultDoesNotShowPromptOrSettings() {
        let subject = createSubject()

        XCTAssertFalse(subject.shouldDisplayRelaySettings())
        XCTAssertFalse(subject.shouldDisplayRelaySettings())
    }

    // MARK: - Subject

    func createSubject() -> RelayController {
        return RelayController(logger: MockLogger(),
                               profile: AppContainer.shared.resolve(),
                               gleanWrapper: MockGleanWrapper(),
                               config: .prod,
                               notificationCenter: MockNotificationCenter())
    }
}
