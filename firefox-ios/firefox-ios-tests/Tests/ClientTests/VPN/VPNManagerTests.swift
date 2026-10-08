// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Network
import TestKit
import XCTest
@testable import Client

@available(iOS 17.0, *)
@MainActor
final class VPNManagerTests: XCTestCase {
    private var mockLogger: MockLogger!
    private var mockProfile: MockProfile!
    private var mockTabManager: MockTabManager!
    private var mockWindowManager: MockWindowManager!
    private var mockUserPreferences: MockUserFeaturePreferences!
    private var mockGuardian: MockVPNGuardian!
    private var mockServerManager: MockVPNServerManager!
    private var mockProxyConfigurator: MockProxyConfigurator!

    override func setUp() async throws {
        try await super.setUp()
        mockLogger = MockLogger()
        mockProfile = MockProfile()
        mockTabManager = MockTabManager()
        mockWindowManager = MockWindowManager(
            wrappedManager: WindowManagerImplementation(),
            tabManager: mockTabManager
        )
        mockWindowManager.overrideWindows = true
        mockUserPreferences = MockUserFeaturePreferences()
        mockGuardian = MockVPNGuardian()
        mockServerManager = MockVPNServerManager()
        mockProxyConfigurator = MockProxyConfigurator()
        DependencyHelperMock().bootstrapDependencies(
            injectedProfile: mockProfile,
            injectedWindowManager: mockWindowManager,
            injectedUserFeaturePreferences: mockUserPreferences
        )
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        mockLogger = nil
        mockProfile = nil
        mockTabManager = nil
        mockWindowManager = nil
        mockUserPreferences = nil
        mockGuardian = nil
        mockServerManager = nil
        mockProxyConfigurator = nil
        try await super.tearDown()
    }

    // MARK: - start

    func testStart_setsPreferenceForVPNToTrue() async {
        let subject = createSubject()

        await subject.start()

        XCTAssertEqual(mockUserPreferences.boolPreferences[.vpnFeature], true)
        XCTAssertTrue(subject.isRunning)
    }

    func testStart_startsPassRotation() async {
        let rotationStarted = expectation(description: "Pass rotation started")
        mockGuardian.onPassRotation = { rotationStarted.fulfill() }
        let subject = createSubject()

        await subject.start()
        await fulfillment(of: [rotationStarted], timeout: 1)

        XCTAssertEqual(mockGuardian.passRotationInitialPasses.map(\.bearerToken), ["initial-token"])
    }

    func testStart_whenPassRotates_appliesProxyWithoutSessionReset() async throws {
        let subject = createSubject()
        await subject.start()
        let rotationApplied = expectation(description: "Rotated pass applied")
        mockProxyConfigurator.onApply = { rotationApplied.fulfill() }

        mockGuardian.rotation.continuation.yield(makePass(token: "rotated-token"))
        await fulfillment(of: [rotationApplied], timeout: 1)

        XCTAssertEqual(mockProxyConfigurator.params.count, 2)
        let rotationCall = try XCTUnwrap(mockProxyConfigurator.params.last)
        XCTAssertEqual(rotationCall.configs.count, 1)
        XCTAssertFalse(rotationCall.forcingSessionReset)
        XCTAssertEqual(mockTabManager.tearDownWebViewsForProxyChangeCalled, 1)
        XCTAssertEqual(mockTabManager.restoreSelectedTabForProxyChangeCalled, 1)
    }

    func testStart_KicksOffWebViewReloadAndProxyApplication() async throws {
        let subject = createSubject()

        await subject.start()

        XCTAssertEqual(mockTabManager.tearDownWebViewsForProxyChangeCalled, 1)
        XCTAssertEqual(mockTabManager.restoreSelectedTabForProxyChangeCalled, 1)
        XCTAssertEqual(mockProxyConfigurator.params.count, 1)
        let params = try XCTUnwrap(mockProxyConfigurator.params.first)
        XCTAssertEqual(params.configs.count, 1)
        XCTAssertTrue(params.forcingSessionReset)
    }

    func testStart_whenGetPassFails_doesNotApplyProxyOrSetPreference() async {
        mockGuardian.passResult = .failure(URLError(.notConnectedToInternet))
        let subject = createSubject()

        await subject.start()

        XCTAssertEqual(mockServerManager.selectServerCalled, 0)
        XCTAssertTrue(mockProxyConfigurator.params.isEmpty)
        XCTAssertEqual(mockTabManager.tearDownWebViewsForProxyChangeCalled, 0)
        XCTAssertTrue(mockGuardian.passRotationInitialPasses.isEmpty)
        XCTAssertFalse(subject.isRunning)
    }

    func testStart_whenNoServerFound_doesNotApplyProxyOrSetPreference() async {
        mockServerManager.server = nil
        let subject = createSubject()

        await subject.start()

        XCTAssertEqual(mockServerManager.selectServerCalled, 1)
        XCTAssertTrue(mockProxyConfigurator.params.isEmpty)
        XCTAssertEqual(mockTabManager.tearDownWebViewsForProxyChangeCalled, 0)
        XCTAssertTrue(mockGuardian.passRotationInitialPasses.isEmpty)
        XCTAssertFalse(subject.isRunning)
    }

    // MARK: - stop

    func testStop_clearsProxyAndSetsPreferenceForVPNToFalse() async throws {
        let subject = createSubject()
        await subject.start()

        await subject.stop()

        XCTAssertEqual(mockUserPreferences.boolPreferences[.vpnFeature], false)
        XCTAssertFalse(subject.isRunning)
        XCTAssertEqual(mockTabManager.tearDownWebViewsForProxyChangeCalled, 2)
        XCTAssertEqual(mockTabManager.restoreSelectedTabForProxyChangeCalled, 2)
        let stopCall = try XCTUnwrap(mockProxyConfigurator.params.last)
        XCTAssertTrue(stopCall.configs.isEmpty)
        XCTAssertTrue(stopCall.forcingSessionReset)
    }

    // MARK: - Helpers

    private func createSubject() -> VPNManager {
        let subject = VPNManager(
            logger: mockLogger,
            clientConfig: .staging,
            profile: mockProfile,
            windowManager: mockWindowManager,
            guardian: mockGuardian,
            serverManager: mockServerManager,
            proxyApplier: mockProxyConfigurator
        )
        trackForMemoryLeaks(subject)
        return subject
    }

    private func makePass(token: String) -> VPNGuardian.ProxyPass {
        return VPNGuardian.ProxyPass(
            bearerToken: token,
            notBefore: Date(),
            expiresAt: Date().addingTimeInterval(3600),
            usage: nil
        )
    }
}

@available(iOS 17.0, *)
private final class MockProxyConfigurator: ProxyConfigurator {
    var params: [(configs: [ProxyConfiguration], forcingSessionReset: Bool)] = []
    var onApply: (() -> Void)?

    func applyProxyConfigurations(_ configs: [ProxyConfiguration], forcingSessionReset: Bool) {
        params.append((configs, forcingSessionReset))
        onApply?()
    }
}
