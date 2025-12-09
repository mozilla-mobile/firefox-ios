// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
@testable import Client

@MainActor
final class TranslationsServiceTests: XCTestCase {
    private var mockProfile: MockProfile!
    private var mockWindowManager: MockWindowManager!
    private var mockTabManager: MockTabManager!
    private var mockLanguageDetector: MockLanguageDetector!
    private var mockModelsFetcher: MockTranslationModelsFetcher!
    private var mockLogger: MockLogger!

    override func setUp() async throws {
        try await super.setUp()

        mockProfile = MockProfile()
        mockLogger = MockLogger()
        mockTabManager = MockTabManager()
        mockWindowManager = MockWindowManager(
            wrappedManager: WindowManagerImplementation(),
            tabManager: mockTabManager
        )

        DependencyHelperMock().bootstrapDependencies(
            injectedWindowManager: mockWindowManager,
            injectedTabManager: mockTabManager
        )
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
    }

    override func tearDown() async throws {
        mockProfile = nil
        mockWindowManager = nil
        mockTabManager = nil
        mockLanguageDetector = nil
        mockModelsFetcher = nil
        mockLogger = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func test_shouldOfferTranslation_returnsTrue_whenLanguagesDiffer_andModelExists() async throws {
        let deviceLanguage = Locale.current.languageCode ?? "en"
        let pageLanguage = (deviceLanguage == "en") ? "es" : "en"

        let subject = createSubject(
            detectedLanguage: pageLanguage,
            languageDetectorError: nil,
            modelsAvailable: true
        )

        setupWebViewForTabManager()

        let result = try await subject.shouldOfferTranslation(for: .XCTestDefaultUUID)
        XCTAssertTrue(
            result,
            "Expected shouldOfferTranslation to be true when languages differ and models are available."
        )
    }

    func test_shouldOfferTranslation_returnsFalse_whenNoModelsAvailable() async throws {
        let deviceLanguage = Locale.current.languageCode ?? "en"
        let pageLanguage = (deviceLanguage == "en") ? "es" : "en"

        let subject = createSubject(
            detectedLanguage: pageLanguage,
            languageDetectorError: nil,
            modelsAvailable: false
        )

        setupWebViewForTabManager()

        let result = try await subject.shouldOfferTranslation(for: .XCTestDefaultUUID)
        XCTAssertFalse(
            result,
            "Expected shouldOfferTranslation to be false when no models are available."
        )
    }

    func test_shouldOfferTranslation_propagatesLanguageDetectorError() async {
        enum TestError: Error, Equatable { case example }

        let subject = createSubject(
            detectedLanguage: "es",
            languageDetectorError: TestError.example,
            modelsAvailable: true
        )

        setupWebViewForTabManager()

        do {
            try await subject.translateCurrentPage(for: .XCTestDefaultUUID, onLanguageIdentified: nil)
            XCTFail("Expected shouldOfferTranslation to throw when language detector fails, but no error was thrown.")
        } catch let error as TranslationsServiceError {
            guard case .unknown = error else {
                XCTFail("Expected TranslationsServiceError.unknown, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected TestError from language detector, but got different error: \(error)")
        }
    }

    func test_translateCurrentPage_throwsMissingWebView_whenNoWebView() async {
        let subject = createSubject(
            detectedLanguage: "es",
            languageDetectorError: nil,
            modelsAvailable: true,
            attachWebView: false
        )

        do {
            try await subject.translateCurrentPage(for: .XCTestDefaultUUID, onLanguageIdentified: nil)
            XCTFail("Expected missingWebView error")
        } catch let error as TranslationsServiceError {
            XCTAssertEqual(error, .missingWebView)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_translateCurrentPage_propagatesLanguageDetectorError() async {
        enum TestError: Error, Equatable { case example }

        let subject = createSubject(
            detectedLanguage: "es",
            languageDetectorError: TestError.example,
            modelsAvailable: true
        )

        setupWebViewForTabManager()

        do {
            try await subject.translateCurrentPage(for: .XCTestDefaultUUID, onLanguageIdentified: nil)
            XCTFail("Expected translateCurrentPage to throw when language detector fails, but no error was thrown.")
        } catch let error as TranslationsServiceError {
            guard case .unknown = error else {
                XCTFail("Expected TranslationsServiceError.unknown, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected TestError from language detector, but got different error: \(error)")
        }
    }

    private func createSubject(
        detectedLanguage: String?,
        languageDetectorError: Error?,
        modelsAvailable: Bool,
        attachWebView: Bool = true
    ) -> TranslationsService {
        mockLanguageDetector = MockLanguageDetector()
        mockLanguageDetector.detectedLanguage = detectedLanguage ?? "en"
        mockLanguageDetector.mockError = languageDetectorError

        mockModelsFetcher = MockTranslationModelsFetcher()
        mockModelsFetcher.modelsResult = modelsAvailable ? Data() : nil

        if attachWebView {
            setupWebViewForTabManager()
        }

        let translationsEngine = TranslationsEngine()

        return TranslationsService(
            windowManager: mockWindowManager,
            languageDetector: mockLanguageDetector,
            modelsFetcher: mockModelsFetcher,
            translationsEngine: translationsEngine,
            logger: mockLogger
        )
    }

    private func setupWebViewForTabManager() {
        let tab = MockTab(
            profile: mockProfile,
            windowUUID: .XCTestDefaultUUID
        )
        tab.webView = MockTabWebView(tab: tab)
        mockTabManager.selectedTab = tab
    }
}
