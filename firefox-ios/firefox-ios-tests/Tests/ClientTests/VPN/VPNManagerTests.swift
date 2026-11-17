// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Network
import Shared
import TestKit
import VPNKit
import XCTest
@testable import Client

@available(iOS 17.0, *)
@MainActor
final class VPNManagerTests: XCTestCase {
    private var mockLogger: MockLogger!
    private var mockProfile: MockProfile!
    private var mockTabManager: MockTabManager!
    private var mockWindowManager: MockWindowManager!
    private var mockGuardian: MockVPNGuardian!
    private var mockServerManager: MockVPNServerManager!
    private var mockProxyConfigurator: MockProxyConfigurator!
    private var mockAuthCreator: MockVPNAuthCreator!

    override func setUp() async throws {
        try await super.setUp()
        mockLogger = MockLogger()
        mockProfile = makeProfile()
        mockTabManager = MockTabManager()
        mockWindowManager = MockWindowManager(
            wrappedManager: WindowManagerImplementation(),
            tabManager: mockTabManager
        )
        mockWindowManager.overrideWindows = true
        mockGuardian = MockVPNGuardian()
        mockServerManager = MockVPNServerManager()
        mockProxyConfigurator = MockProxyConfigurator()
        mockAuthCreator = MockVPNAuthCreator()
        DependencyHelperMock().bootstrapDependencies(
            injectedProfile: mockProfile,
            injectedWindowManager: mockWindowManager
        )
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        mockLogger = nil
        mockProfile = nil
        mockTabManager = nil
        mockWindowManager = nil
        mockGuardian = nil
        mockServerManager = nil
        mockProxyConfigurator = nil
        mockAuthCreator = nil
        try await super.tearDown()
    }

    // MARK: - start

    func testStart_setsIsRunning() async throws {
        let subject = createSubject()

        try await subject.start(countryCode: nil)

        XCTAssertTrue(subject.isRunning)
    }

    func testStart_startsPassRotation() async throws {
        let rotationStarted = expectation(description: "Pass rotation started")
        mockGuardian.onPassRotation = { rotationStarted.fulfill() }
        let subject = createSubject()

        try await subject.start(countryCode: nil)
        await fulfillment(of: [rotationStarted], timeout: 1)

        XCTAssertEqual(mockGuardian.passRotationInitialPasses.map(\.bearerToken), ["initial-token"])
    }

    func testStart_whenPassRotates_appliesProxyWithoutSessionReset() async throws {
        let subject = createSubject()
        try await subject.start(countryCode: nil)
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

        try await subject.start(countryCode: nil)

        XCTAssertEqual(mockTabManager.tearDownWebViewsForProxyChangeCalled, 1)
        XCTAssertEqual(mockTabManager.restoreSelectedTabForProxyChangeCalled, 1)
        XCTAssertEqual(mockProxyConfigurator.params.count, 1)
        let params = try XCTUnwrap(mockProxyConfigurator.params.first)
        XCTAssertEqual(params.configs.count, 1)
        XCTAssertTrue(params.forcingSessionReset)
    }

    func testStart_whenGetPassFails_throwsAndDoesNotApplyProxy() async {
        mockGuardian.passResult = .failure(URLError(.notConnectedToInternet))
        let subject = createSubject()

        await assertStartThrows(subject)

        XCTAssertEqual(mockServerManager.selectServerCalled, 0)
        XCTAssertTrue(mockProxyConfigurator.params.isEmpty)
        XCTAssertEqual(mockTabManager.tearDownWebViewsForProxyChangeCalled, 0)
        XCTAssertTrue(mockGuardian.passRotationInitialPasses.isEmpty)
        XCTAssertFalse(subject.isRunning)
    }

    func testStart_whenNoServerFound_throwsAndDoesNotApplyProxy() async {
        mockServerManager.server = nil
        let subject = createSubject()

        await assertStartThrows(subject)

        XCTAssertEqual(mockServerManager.selectServerCalled, 1)
        XCTAssertTrue(mockProxyConfigurator.params.isEmpty)
        XCTAssertEqual(mockTabManager.tearDownWebViewsForProxyChangeCalled, 0)
        XCTAssertTrue(mockGuardian.passRotationInitialPasses.isEmpty)
        XCTAssertFalse(subject.isRunning)
    }

    func testStart_whenTokenProviderUnavailable_throwsAndDoesNotApplyProxy() async {
        let subject = createSubject(injectGuardian: false)

        await assertStartThrows(subject)

        XCTAssertEqual(mockAuthCreator.makeTokenProviderCalled, 1)
        XCTAssertEqual(mockServerManager.selectServerCalled, 0)
        XCTAssertTrue(mockProxyConfigurator.params.isEmpty)
        XCTAssertEqual(mockTabManager.tearDownWebViewsForProxyChangeCalled, 0)
        XCTAssertFalse(subject.isRunning)
    }

    func testStart_selectsServerFromServerManager() async throws {
        mockProfile.prefs.setString(VPNEnvironment.prod.rawValue, forKey: PrefsKeys.VPNSettings.endpointEnvironment)
        let subject = createSubject()

        try await subject.start(countryCode: nil)

        XCTAssertEqual(mockServerManager.selectServerCalled, 1)
        XCTAssertEqual(mockProxyConfigurator.params.count, 1)
    }

    func testStart_selectsServerForCountryCode() async throws {
        let subject = createSubject()

        try await subject.start(countryCode: "DE")

        XCTAssertEqual(mockServerManager.selectServerCountryCodes, ["DE"])
    }

    // MARK: - start while running

    func testStart_whenRunning_appliesServerForNewCountryCode() async throws {
        let subject = createSubject()
        try await subject.start(countryCode: nil)

        try await subject.start(countryCode: "DE")

        XCTAssertEqual(mockServerManager.selectServerCountryCodes, [nil, "DE"])
        XCTAssertEqual(mockProxyConfigurator.params.count, 2)
        let params = try XCTUnwrap(mockProxyConfigurator.params.last)
        XCTAssertEqual(params.configs.count, 1)
        XCTAssertTrue(params.forcingSessionReset)
        XCTAssertEqual(mockTabManager.tearDownWebViewsForProxyChangeCalled, 2)
        XCTAssertEqual(mockTabManager.restoreSelectedTabForProxyChangeCalled, 2)
        XCTAssertTrue(subject.isRunning)
    }

    func testStart_whenRunning_restartsPassRotationWithNewPass() async throws {
        let rotationStarted = expectation(description: "Pass rotation started")
        rotationStarted.expectedFulfillmentCount = 2
        mockGuardian.onPassRotation = { rotationStarted.fulfill() }
        let subject = createSubject()
        try await subject.start(countryCode: nil)
        mockGuardian.passResult = .success(makePass(token: "new-token"))

        try await subject.start(countryCode: "DE")
        await fulfillment(of: [rotationStarted], timeout: 1)

        XCTAssertEqual(mockGuardian.passRotationInitialPasses.map(\.bearerToken), ["initial-token", "new-token"])
    }

    func testStart_whenRunningAndGetPassFails_throwsAndKeepsCurrentProxy() async throws {
        let subject = createSubject()
        try await subject.start(countryCode: nil)
        mockGuardian.passResult = .failure(URLError(.notConnectedToInternet))

        do {
            try await subject.start(countryCode: "DE")
            XCTFail("Expected start to throw")
        } catch {}

        XCTAssertEqual(mockServerManager.selectServerCalled, 1)
        XCTAssertEqual(mockProxyConfigurator.params.count, 1)
        XCTAssertEqual(mockTabManager.tearDownWebViewsForProxyChangeCalled, 1)
        XCTAssertTrue(subject.isRunning)
    }

    func testStart_whenRunningAndNoServerFound_throwsAndKeepsCurrentProxy() async throws {
        let subject = createSubject()
        try await subject.start(countryCode: nil)
        mockServerManager.server = nil

        do {
            try await subject.start(countryCode: "DE")
            XCTFail("Expected start to throw")
        } catch {}

        XCTAssertEqual(mockProxyConfigurator.params.count, 1)
        XCTAssertEqual(mockTabManager.tearDownWebViewsForProxyChangeCalled, 1)
        XCTAssertTrue(subject.isRunning)
    }

    // MARK: - events

    func testStart_emitsPassUpdated() async throws {
        let subject = createSubject()
        var iterator = subject.events.makeAsyncIterator()

        try await subject.start(countryCode: nil)

        let event = await iterator.next()
        guard case .passUpdated(let pass) = event else {
            return XCTFail("Expected passUpdated, got \(String(describing: event))")
        }
        XCTAssertEqual(pass.bearerToken, "initial-token")
    }

    func testPassRotation_emitsPassUpdated() async throws {
        let subject = createSubject()
        var iterator = subject.events.makeAsyncIterator()
        try await subject.start(countryCode: nil)
        _ = await iterator.next()

        mockGuardian.rotation.continuation.yield(makePass(token: "rotated-token"))

        let event = await iterator.next()
        guard case .passUpdated(let pass) = event else {
            return XCTFail("Expected passUpdated, got \(String(describing: event))")
        }
        XCTAssertEqual(pass.bearerToken, "rotated-token")
    }

    func testPassRotationFailure_emitsRotationFailed() async throws {
        let subject = createSubject()
        var iterator = subject.events.makeAsyncIterator()
        try await subject.start(countryCode: nil)
        _ = await iterator.next()

        mockGuardian.rotation.continuation.finish(throwing: URLError(.notConnectedToInternet))

        let event = await iterator.next()
        XCTAssertEqual(event, .rotationFailed)
    }

    // MARK: - stop

    func testStop_clearsProxyAndStopsRunning() async throws {
        let subject = createSubject()
        try await subject.start(countryCode: nil)

        await subject.stop()

        XCTAssertFalse(subject.isRunning)
        XCTAssertEqual(mockTabManager.tearDownWebViewsForProxyChangeCalled, 2)
        XCTAssertEqual(mockTabManager.restoreSelectedTabForProxyChangeCalled, 2)
        let stopCall = try XCTUnwrap(mockProxyConfigurator.params.last)
        XCTAssertTrue(stopCall.configs.isEmpty)
        XCTAssertTrue(stopCall.forcingSessionReset)
    }

    // MARK: - Helpers

    private func createSubject(injectGuardian: Bool = true) -> VPNManager {
        let subject = VPNManager(
            logger: mockLogger,
            profile: mockProfile,
            windowManager: mockWindowManager,
            guardian: injectGuardian ? mockGuardian : nil,
            authCreator: mockAuthCreator,
            serverManager: mockServerManager,
            proxyApplier: mockProxyConfigurator
        )
        trackForMemoryLeaks(subject)
        return subject
    }

    private func assertStartThrows(_ subject: VPNManager,
                                   file: StaticString = #filePath,
                                   line: UInt = #line) async {
        do {
            try await subject.start(countryCode: nil)
            XCTFail("Expected start to throw", file: file, line: line)
        } catch {}
    }

    private func makePass(token: String) -> VPNProxyPass {
        return VPNProxyPass(
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

private final class MockVPNAuthCreator: VPNAuthCreating {
    var tokenProvider: VPNTokenProviding?
    var makeTokenProviderCalled = 0

    func makeTokenProvider(using prefs: Prefs) -> VPNTokenProviding? {
        makeTokenProviderCalled += 1
        return tokenProvider
    }

    func makeAuthService(using prefs: Prefs) -> VPNAuthenticating? {
        return nil
    }

    func makeProxyTokenService(using prefs: Prefs) -> VPNProxyTokenFetching? {
        return nil
    }
}
