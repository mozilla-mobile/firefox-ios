// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Sentry
import XCTest
@testable import Common

final class CrashManagerTests: XCTestCase {
    private static let bundleIdentifier = "org.mozilla.ios.Firefox"
    private static let appVersion = "158.0"
    private var sentryWrapper: MockSentryWrapper!

    override func setUp() {
        super.setUp()
        sentryWrapper = MockSentryWrapper()
    }

    override func tearDown() {
        super.tearDown()
        sentryWrapper = nil
        setupAppInformation(buildChannel: .other)
    }

    // MARK: - Setup

    func testSetup_isSimulator_notSetup() {
        sentryWrapper.dsn = "12345"
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: true,
                                          skipReleaseNameCheck: true,
                                          bundleIdentifier: { Self.bundleIdentifier },
                                          appVersion: { Self.appVersion })
        subject.setup(sendCrashReports: true)

        XCTAssertEqual(sentryWrapper.startWithConfigureOptionsCalled, 0)
        XCTAssertEqual(sentryWrapper.configureScopeCalled, 0)
    }

    func testSetup_sendNoUsageData_notSetup() {
        sentryWrapper.dsn = "12345"
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true,
                                          bundleIdentifier: { Self.bundleIdentifier },
                                          appVersion: { Self.appVersion })
        subject.setup(sendCrashReports: false)

        XCTAssertEqual(sentryWrapper.startWithConfigureOptionsCalled, 0)
        XCTAssertEqual(sentryWrapper.configureScopeCalled, 0)
    }

    func testSetup_noDSN_notSetup() {
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true,
                                          bundleIdentifier: { Self.bundleIdentifier },
                                          appVersion: { Self.appVersion })
        subject.setup(sendCrashReports: true)

        XCTAssertEqual(sentryWrapper.startWithConfigureOptionsCalled, 0)
        XCTAssertEqual(sentryWrapper.configureScopeCalled, 0)
    }

    func testSetup_isSetup() {
        sentryWrapper.dsn = "12345"
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true,
                                          bundleIdentifier: { Self.bundleIdentifier },
                                          appVersion: { Self.appVersion })
        subject.setup(sendCrashReports: true)

        XCTAssertEqual(sentryWrapper.startWithConfigureOptionsCalled, 1)
        XCTAssertEqual(sentryWrapper.configureScopeCalled, 1)
    }

    func testSetup_isSetupTwice_notCalledTwice() {
        sentryWrapper.dsn = "12345"
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true,
                                          bundleIdentifier: { Self.bundleIdentifier },
                                          appVersion: { Self.appVersion })
        subject.setup(sendCrashReports: true)
        subject.setup(sendCrashReports: true)

        XCTAssertEqual(sentryWrapper.startWithConfigureOptionsCalled, 1)
        XCTAssertEqual(sentryWrapper.configureScopeCalled, 1)
    }

    // MARK: - crashedLastLaunch

    func testCrashedLastLaunch_false() {
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true,
                                          bundleIdentifier: { Self.bundleIdentifier },
                                          appVersion: { Self.appVersion })
        XCTAssertFalse(subject.crashedLastLaunch)
    }

    func testCrashedLastLaunch_true() {
        sentryWrapper.mockCrashedInLastRun = true
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true,
                                          bundleIdentifier: { Self.bundleIdentifier },
                                          appVersion: { Self.appVersion })
        XCTAssertTrue(subject.crashedLastLaunch)
    }

    // MARK: - Send message

    func testSendMessage_notEnabled_doesNothing() {
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true,
                                          bundleIdentifier: { Self.bundleIdentifier },
                                          appVersion: { Self.appVersion })
        subject.send(message: "A message",
                     category: .setup,
                     level: .debug,
                     extraEvents: nil)

        XCTAssertNil(sentryWrapper.savedMessage)
        XCTAssertNil(sentryWrapper.savedBreadcrumb)
    }

    func testSendMessageFatal_enabledDebug_sendBreadcrumb() {
        sentryWrapper.dsn = "12345"
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true,
                                          bundleIdentifier: { Self.bundleIdentifier },
                                          appVersion: { Self.appVersion })
        subject.setup(sendCrashReports: true)

        subject.send(message: "A message",
                     category: .setup,
                     level: .fatal,
                     extraEvents: nil)

        XCTAssertNil(sentryWrapper.savedMessage)
        XCTAssertNotNil(sentryWrapper.savedBreadcrumb)
        XCTAssertEqual(sentryWrapper.savedBreadcrumb?.message, "A message")
    }

    func testSendMessageFatal_enabledBeta_sendMessage() {
        sentryWrapper.dsn = "12345"
        setupAppInformation(buildChannel: .beta)
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true,
                                          bundleIdentifier: { Self.bundleIdentifier },
                                          appVersion: { Self.appVersion })
        subject.setup(sendCrashReports: true)

        subject.send(message: "A message",
                     category: .setup,
                     level: .fatal,
                     extraEvents: nil)

        XCTAssertNotNil(sentryWrapper.savedMessage)
        XCTAssertEqual(sentryWrapper.savedMessage, "A message")
        XCTAssertNil(sentryWrapper.savedBreadcrumb)
    }

    func testSendMessageInfo_enabledBeta_sendBreadcrumb() {
        sentryWrapper.dsn = "12345"
        setupAppInformation(buildChannel: .beta)
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true,
                                          bundleIdentifier: { Self.bundleIdentifier },
                                          appVersion: { Self.appVersion })
        subject.setup(sendCrashReports: true)

        subject.send(message: "A message",
                     category: .setup,
                     level: .info,
                     extraEvents: nil)

        XCTAssertNil(sentryWrapper.savedMessage)
        XCTAssertNotNil(sentryWrapper.savedBreadcrumb)
        XCTAssertEqual(sentryWrapper.savedBreadcrumb?.message, "A message")
    }

    func testSendMessageFatal_enabledRelease_sendMessage() {
        sentryWrapper.dsn = "12345"
        setupAppInformation(buildChannel: .release)
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true,
                                          bundleIdentifier: { Self.bundleIdentifier },
                                          appVersion: { Self.appVersion })
        subject.setup(sendCrashReports: true)

        subject.send(message: "A message",
                     category: .setup,
                     level: .fatal,
                     extraEvents: nil)

        XCTAssertNotNil(sentryWrapper.savedMessage)
        XCTAssertEqual(sentryWrapper.savedMessage, "A message")
        XCTAssertNil(sentryWrapper.savedBreadcrumb)
    }

    func testSendMessageInfo_enabledRelease_sendBreadcrumb() {
        sentryWrapper.dsn = "12345"
        setupAppInformation(buildChannel: .release)
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true,
                                          bundleIdentifier: { Self.bundleIdentifier },
                                          appVersion: { Self.appVersion })
        subject.setup(sendCrashReports: true)

        subject.send(message: "A message",
                     category: .setup,
                     level: .info,
                     extraEvents: nil)

        XCTAssertNil(sentryWrapper.savedMessage)
        XCTAssertNotNil(sentryWrapper.savedBreadcrumb)
        XCTAssertEqual(sentryWrapper.savedBreadcrumb?.message, "A message")
    }

    func testSendMessageWarning_enabledRelease_sendBreadcrumbWithCategoryAndErrorLevel() {
        setUpSubject(buildChannel: .release).send(message: "A message",
                                                  category: .setup,
                                                  level: .warning,
                                                  extraEvents: nil)

        XCTAssertEqual(sentryWrapper.savedBreadcrumb?.category, LoggerCategory.setup.rawValue)
        XCTAssertEqual(sentryWrapper.savedBreadcrumb?.level, .error)
    }

    func testSendMessageFatal_enabledRelease_appliesExtraEventsToScope() {
        setUpSubject(buildChannel: .release).send(message: "A message",
                                                  category: .setup,
                                                  level: .fatal,
                                                  extraEvents: ["key": "value"])

        let scope = Scope()
        sentryWrapper.savedScopeBlock?(scope)
        XCTAssertEqual(scope.serialize()["extra"] as? [String: String], ["key": "value"])
    }

    // MARK: - Capture error

    func testCaptureError_release_capturesError() {
        let subject = setUpSubject(buildChannel: .release)

        subject.captureError(error: MockCustomCrashReport())

        XCTAssertNotNil(sentryWrapper.savedError)
    }

    func testCaptureError_beta_capturesError() {
        let subject = setUpSubject(buildChannel: .beta)

        subject.captureError(error: MockCustomCrashReport())

        XCTAssertNotNil(sentryWrapper.savedError)
    }

    func testCaptureError_other_doesNotCaptureError() {
        let subject = setUpSubject(buildChannel: .other)

        subject.captureError(error: MockCustomCrashReport())

        XCTAssertNil(sentryWrapper.savedError)
    }

    // MARK: - Options

    func testSetup_configuresDSNAndReleaseName() {
        setUpSubject(buildChannel: .release)

        XCTAssertEqual(sentryWrapper.savedOptions?.dsn, validDSN)
        XCTAssertEqual(sentryWrapper.savedOptions?.releaseName, "org.mozilla.ios.Firefox@158.0")
    }

    func testSetup_firefoxBetaBundle_isSetup() {
        sentryWrapper.dsn = validDSN
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          bundleIdentifier: { "org.mozilla.ios.FirefoxBeta" },
                                          appVersion: { Self.appVersion })

        subject.setup(sendCrashReports: true)

        XCTAssertEqual(sentryWrapper.startWithConfigureOptionsCalled, 1)
    }

    func testSetup_otherBundle_notSetup() {
        sentryWrapper.dsn = validDSN
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          bundleIdentifier: { "org.mozilla.ios.Fennec" },
                                          appVersion: { Self.appVersion })

        subject.setup(sendCrashReports: true)

        XCTAssertEqual(sentryWrapper.startWithConfigureOptionsCalled, 0)
    }

    func testSetup_release_usesProductionEnvironment() {
        setUpSubject(buildChannel: .release)

        XCTAssertEqual(sentryWrapper.savedOptions?.environment, "Production")
    }

    func testSetup_betaOnNightlyVersion_usesNightlyEnvironment() {
        setUpSubject(buildChannel: .beta, nightlyAppVersion: Self.appVersion)

        XCTAssertEqual(sentryWrapper.savedOptions?.environment, "Nightly")
    }

    func testSetup_betaOnOtherVersion_usesProductionEnvironment() {
        setUpSubject(buildChannel: .beta)

        XCTAssertEqual(sentryWrapper.savedOptions?.environment, "Production")
    }

    func testSetup_beta_enablesTracingAppHangsAndMetricKit() {
        setUpSubject(buildChannel: .beta)

        let options = sentryWrapper.savedOptions
        XCTAssertEqual(options?.tracesSampleRate, 0.2)
        XCTAssertNotNil(options?.configureProfiling)
        XCTAssertEqual(options?.enableAppHangTracking, true)
        XCTAssertEqual(options?.enableMetricKit, true)
    }

    func testSetup_release_disablesTracingAppHangsAndMetricKit() {
        setUpSubject(buildChannel: .release)

        let options = sentryWrapper.savedOptions
        XCTAssertNil(options?.tracesSampleRate)
        XCTAssertNil(options?.configureProfiling)
        XCTAssertEqual(options?.enableAppHangTracking, false)
        XCTAssertEqual(options?.enableMetricKit, false)
    }

    func testSetup_disablesAutomaticInstrumentation() {
        setUpSubject(buildChannel: .release)

        let options = sentryWrapper.savedOptions
        XCTAssertEqual(options?.enableFileIOTracing, false)
        XCTAssertEqual(options?.enableNetworkTracking, false)
        XCTAssertEqual(options?.enableCaptureFailedRequests, false)
        XCTAssertEqual(options?.enableNetworkBreadcrumbs, false)
        XCTAssertEqual(options?.enableSwizzling, false)
        XCTAssertEqual(options?.enableAutoBreadcrumbTracking, false)
    }

    func testBeforeBreadcrumb_dropsHTTPBreadcrumbs() {
        setUpSubject(buildChannel: .release)
        let httpType = Breadcrumb(level: .info, category: "navigation")
        httpType.type = "http"
        let httpCategory = Breadcrumb(level: .info, category: "http")

        XCTAssertNil(sentryWrapper.savedOptions?.beforeBreadcrumb?(httpType))
        XCTAssertNil(sentryWrapper.savedOptions?.beforeBreadcrumb?(httpCategory))
    }

    func testBeforeBreadcrumb_keepsOtherBreadcrumbs() {
        setUpSubject(buildChannel: .release)
        let crumb = Breadcrumb(level: .info, category: "setup")

        XCTAssertIdentical(sentryWrapper.savedOptions?.beforeBreadcrumb?(crumb), crumb)
    }

    func testBeforeSend_customCrashReport_usesReportForFingerprintAndException() {
        setUpSubject(buildChannel: .release)
        let crash = MockCustomCrashReport()
        let event = Event(error: crash as NSError)
        event.exceptions = [Exception(value: "original value", type: "original type")]

        let result = sentryWrapper.savedOptions?.beforeSend?(event)

        XCTAssertEqual(result?.fingerprint, [crash.typeName])
        XCTAssertEqual(result?.exceptions?.first?.type, crash.typeName)
        XCTAssertEqual(result?.exceptions?.first?.value, crash.message)
    }

    func testBeforeSend_otherError_leavesEventUnchanged() {
        setUpSubject(buildChannel: .release)
        let event = Event(error: NSError(domain: "test", code: 1))
        event.exceptions = [Exception(value: "original value", type: "original type")]

        let result = sentryWrapper.savedOptions?.beforeSend?(event)

        XCTAssertNil(result?.fingerprint)
        XCTAssertEqual(result?.exceptions?.first?.type, "original type")
        XCTAssertEqual(result?.exceptions?.first?.value, "original value")
    }

    // MARK: - Helpers

    // Options.dsn discards values it can't parse, so options tests need a well formed DSN
    private let validDSN = "https://public@o0.ingest.sentry.io/0"

    @discardableResult
    private func setUpSubject(buildChannel: AppBuildChannel, nightlyAppVersion: String = "") -> DefaultCrashManager {
        BrowserKitInformation.shared.configure(buildChannel: buildChannel,
                                               nightlyAppVersion: nightlyAppVersion,
                                               sharedContainerIdentifier: "")
        sentryWrapper.dsn = validDSN
        let subject = DefaultCrashManager(sentryWrapper: sentryWrapper,
                                          isSimulator: false,
                                          skipReleaseNameCheck: true,
                                          bundleIdentifier: { Self.bundleIdentifier },
                                          appVersion: { Self.appVersion })
        subject.setup(sendCrashReports: true)
        return subject
    }
}

private struct MockCustomCrashReport: Error, CustomCrashReport {
    let typeName = "RustPanic"
    let message = "Rust panicked"
}

// MARK: - Feature flags
extension CrashManagerTests {
    func testFeatureFlagsContext_empty_returnsNil() {
        XCTAssertNil(DefaultCrashManager.featureFlagsContext(from: [:]))
    }

    func testFeatureFlagsContext_encodesFeatureAndBranchSortedWithTrueResult() {
        let context = DefaultCrashManager.featureFlagsContext(from: ["tab-tray": "treatment-a",
                                                                     "homepage": "control"])
        let values = context?["values"] as? [[String: Any]]

        XCTAssertEqual(values?.compactMap { $0["flag"] as? String }, ["homepage:control", "tab-tray:treatment-a"])
        XCTAssertEqual(values?.compactMap { $0["result"] as? Bool }, [true, true])
    }

    func testFeatureFlagsContext_capsAtMaxFeatureFlags() {
        let featureBranches = Dictionary(uniqueKeysWithValues: (0..<150).map { ("feature-\($0)", "branch") })

        let values = DefaultCrashManager.featureFlagsContext(from: featureBranches)?["values"] as? [[String: Any]]

        XCTAssertEqual(values?.count, DefaultCrashManager.maxFeatureFlags)
    }

    func testSetFeatureFlags_beforeSetup_doesNotConfigureScope() {
        let subject = createSubject()

        subject.setFeatureFlags(["homepage": "control"])

        XCTAssertEqual(sentryWrapper.configureScopeCalled, 0)
        XCTAssertNil(featureFlags(in: sentryWrapper.scope))
    }

    func testSetFeatureFlags_beforeSetup_appliedOnSetup() {
        let subject = createSubject()

        subject.setFeatureFlags(["homepage": "control"])
        subject.setup(sendCrashReports: true)

        XCTAssertEqual(featureFlags(in: sentryWrapper.scope), ["homepage:control"])
    }

    func testSetFeatureFlags_setupNotAllowed_doesNotConfigureScope() {
        let subject = createSubject()

        subject.setup(sendCrashReports: false)
        subject.setFeatureFlags(["homepage": "control"])

        XCTAssertEqual(sentryWrapper.configureScopeCalled, 0)
    }

    func testSetFeatureFlags_afterSetup_updatesScope() {
        let subject = createSubject()
        subject.setup(sendCrashReports: true)

        subject.setFeatureFlags(["homepage": "control"])

        XCTAssertEqual(featureFlags(in: sentryWrapper.scope), ["homepage:control"])
    }

    func testSetFeatureFlags_replacesPreviousFlags() {
        let subject = createSubject()
        subject.setup(sendCrashReports: true)

        subject.setFeatureFlags(["homepage": "control", "tab-tray": "treatment-a"])
        subject.setFeatureFlags(["tab-tray": "treatment-b"])

        XCTAssertEqual(featureFlags(in: sentryWrapper.scope), ["tab-tray:treatment-b"])
    }

    func testSetFeatureFlags_empty_removesFlagsContext() {
        let subject = createSubject()
        subject.setup(sendCrashReports: true)
        subject.setFeatureFlags(["homepage": "control"])

        subject.setFeatureFlags([:])

        XCTAssertNil(featureFlags(in: sentryWrapper.scope))
    }

    func testSetup_keepsAppContextAlongsideFeatureFlags() {
        let subject = createSubject()
        subject.setFeatureFlags(["homepage": "control"])

        subject.setup(sendCrashReports: true)

        let context = sentryWrapper.scope.serialize()["context"] as? [String: Any]
        XCTAssertNotNil(context?["appContext"])
        XCTAssertNotNil(context?[DefaultCrashManager.featureFlagsContextKey])
    }
}

// MARK: - Helpers
extension CrashManagerTests {
    private func createSubject() -> DefaultCrashManager {
        sentryWrapper.dsn = "12345"
        return DefaultCrashManager(sentryWrapper: sentryWrapper,
                                   isSimulator: false,
                                   skipReleaseNameCheck: true)
    }

    private func setupAppInformation(buildChannel: AppBuildChannel) {
        BrowserKitInformation.shared.configure(buildChannel: buildChannel,
                                               nightlyAppVersion: "",
                                               sharedContainerIdentifier: "")
    }
}

/// Returns the feature flag names recorded in the scope's Sentry `flags` context
func featureFlags(in scope: Scope) -> [String]? {
    let context = scope.serialize()["context"] as? [String: Any]
    let flags = context?[DefaultCrashManager.featureFlagsContextKey] as? [String: Any]
    let values = flags?["values"] as? [[String: Any]]
    return values?.compactMap { $0["flag"] as? String }
}

// MARK: - MockSentryWrapper
final class MockSentryWrapper: SentryWrapper, @unchecked Sendable {
    var mockCrashedInLastRun = false
    var crashedInLastRun: Bool {
        return mockCrashedInLastRun
    }

    var dsn: String?

    var startWithConfigureOptionsCalled = 0
    var savedOptions: Options?
    func startWithConfigureOptions(configure options: @escaping (Options) -> Void) {
        startWithConfigureOptionsCalled += 1
        let configuredOptions = Options()
        options(configuredOptions)
        savedOptions = configuredOptions
    }

    var savedMessage: String?
    var savedScopeBlock: ((Scope) -> Void)?
    func captureMessage(message: String, with scopeBlock: @escaping (Scope) -> Void) {
        savedMessage = message
        savedScopeBlock = scopeBlock
    }

    var savedError: Error?
    func captureError(error: Error) {
        savedError = error
    }

    var savedBreadcrumb: Breadcrumb?
    func addBreadcrumb(crumb: Breadcrumb) {
        savedBreadcrumb = crumb
    }

    let scope = Scope()
    var configureScopeCalled = 0
    func configureScope(scope: @escaping (Scope) -> Void) {
        configureScopeCalled += 1
        scope(self.scope)
    }
}
