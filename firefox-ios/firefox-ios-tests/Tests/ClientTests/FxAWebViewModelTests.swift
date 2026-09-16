// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest
import PDFKit
import WebKit

import class Account.RustFirefoxAccounts

@MainActor
class FxAWebViewModelTests: XCTestCase {
    var viewModel: FxAWebViewModel!
    var deeplinkParams: FxALaunchParams!

    override func setUp() async throws {
        try await super.setUp()
        deeplinkParams = FxALaunchParams(entrypoint: .browserMenu, query: ["test_key": "test_value"])
        viewModel = FxAWebViewModel(pageType: .settingsPage,
                                    profile: MockProfile(),
                                    deepLinkParams: deeplinkParams,
                                    telemetry: FxAWebViewTelemetry(telemetryWrapper: MockTelemetryWrapper()))
    }

    override func tearDown() async throws {
        deeplinkParams = nil
        viewModel = nil
        try await super.tearDown()
    }

    func testCreateOutputURLWithValidFileNameAndExtension() {
        let fileName = "testFile"
        let fileExtension = "txt"
        let expectedURL = createExpectedURL(with: fileName, and: fileExtension)
        let resultURL = viewModel.createOutputURL(withFileName: fileName, withFileExtension: fileExtension)
        XCTAssertEqual(resultURL, expectedURL, "The created URL is not valid")
    }

    func testCreateOutputURLWithEmptyFileNameAndExtension() {
        let fileName = ""
        let fileExtension = ""
        let expectedURL = createExpectedURL(with: fileName, and: fileExtension)
        let resultURL = viewModel.createOutputURL(withFileName: fileName, withFileExtension: fileExtension)
        XCTAssertEqual(resultURL, expectedURL, "The created URL is not valid")
    }

    func testCreateOutputURLWithSpecialCharactersInFileName() {
        let fileName = "test@File#1"
        let fileExtension = "data"
        let expectedURL = createExpectedURL(with: fileName, and: fileExtension)
        let resultURL = viewModel.createOutputURL(withFileName: fileName, withFileExtension: fileExtension)
        XCTAssertEqual(resultURL, expectedURL, "The created URL is not valid")
    }

    func testIsMozillaAccountPDFWithValidBlobURLAndCorrectHost() {
        if let blobURL = URL(string: "blob://some/blob/url"),
           let webViewURL = URL(string: "https://accounts.firefox.com") {
            let result = viewModel.isMozillaAccountPDF(blobURL: blobURL, webViewURL: webViewURL)
            XCTAssertTrue(
                result,
                "Should return true for a valid blob URL and a webView URL with the host accounts.firefox.com."
            )
        }
    }

    func testIsMozillaAccountPDFWithValidBlobURLAndIncorrectHost() {
        if let blobURL = URL(string: "blob://some/blob/url"),
           let webViewURL = URL(string: "https://example.com") {
            let result = viewModel.isMozillaAccountPDF(blobURL: blobURL, webViewURL: webViewURL)
            XCTAssertFalse(
                result,
                "Should return false for a valid blob URL and a webView URL with a different host then accounts.firefox.com"
            )
        }
    }

    func testIsMozillaAccountPDFWithInvalidBlobURLAndCorrectHost() {
        if let blobURL = URL(string: "https://example.com/blob"),
           let webViewURL = URL(string: "https://accounts.firefox.com") {
            let result = viewModel.isMozillaAccountPDF(blobURL: blobURL, webViewURL: webViewURL)
            XCTAssertFalse(
                result,
                "Should return false for a wrong blob URL and a webView URL with the host accounts.firefox.com."
            )
        }
    }

    func testIsMozillaAccountPDFWithValidBlobURLAndNilWebViewURL() {
        if let blobURL = URL(string: "blob://some/blob/url") {
            let webViewURL: URL? = nil
            let result = viewModel.isMozillaAccountPDF(blobURL: blobURL, webViewURL: webViewURL)
            XCTAssertFalse(result, "Should return false for a valid blob URL and a nil webView URL.")
        }
    }

    func testIsMozillaAccountPDFWithInvalidBlobURLAndNilWebViewURL() {
        if let blobURL = URL(string: "https://example.com/blob") {
            let webViewURL: URL? = nil
            let result = viewModel.isMozillaAccountPDF(blobURL: blobURL, webViewURL: webViewURL)
            XCTAssertFalse(result, "Should return false for a wrong blob URL and a nil webView URL.")
        }
    }

    func testCreateURLForPDFWithValidSuccessResult() {
        let result: Result<Any?, Error> = .success(MockFxAWebViewModel().validPDFDataURL)
        if let outputURL = viewModel.createURLForPDF(result: result) {
            XCTAssertNotNil(outputURL, "Should return a valid URL.")
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path), "PDF File should exist.")
        }
    }

    func testCreateURLForPDFWithInvalidSuccessResult() {
        let invalidURLString = "invalidURL"
        let result: Result<Any?, Error> = .success(invalidURLString)
        let outputURL = viewModel.createURLForPDF(result: result)
        XCTAssertNil(outputURL, "Should return nil on .success but with an invalid URL")
    }

    func testCreateURLForPDFWithFailureResult() {
        let error = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        let result: Result<Any?, Error> = .failure(error)
        let outputURL = viewModel.createURLForPDF(result: result)
        XCTAssertNil(outputURL, "Should return nil for a .failure result")
    }

    func testCreateURLForPDFWithValidURLButInvalidPDFData() {
        let result: Result<Any?, Error> = .success(MockFxAWebViewModel().invalidPDFDataURL)
        let outputURL = viewModel.createURLForPDF(result: result)
        XCTAssertNil(outputURL, "Should return nil on .success with an URL but not a PDF one.")
    }

    func testAuthenticationStatusResponseAdvertisesPairingVersionTwo() throws {
        let capabilities = try authenticationStatusCapabilities()

        XCTAssertEqual(capabilities["pairingVersion"] as? Int, 2)
    }

    func testAuthenticationStatusResponseEnablesChooseWhatToSync() throws {
        let capabilities = try authenticationStatusCapabilities()

        XCTAssertEqual(capabilities["choose_what_to_sync"] as? Bool, true)
    }

    func testAuthenticationStatusResponseIncludesAddressesForASupportedRegion() throws {
        let capabilities = try authenticationStatusCapabilities(regionCode: "US")

        XCTAssertEqual(
            capabilities["engines"] as? [String],
            ["bookmarks", "history", "tabs", "passwords", "creditcards", "addresses"]
        )
    }

    func testAuthenticationStatusResponseOmitsAddressesForAnUnsupportedRegion() throws {
        let capabilities = try authenticationStatusCapabilities(regionCode: "XX")

        XCTAssertEqual(
            capabilities["engines"] as? [String],
            ["bookmarks", "history", "tabs", "passwords", "creditcards"]
        )
    }

    // MARK: - Message id parsing

    func testMessageIDAcceptsAnInt() {
        XCTAssertEqual(viewModel.messageID(from: 42), 42)
    }

    func testMessageIDAcceptsANumericString() {
        XCTAssertEqual(viewModel.messageID(from: "42"), 42)
    }

    func testMessageIDRejectsANonNumericString() {
        XCTAssertNil(viewModel.messageID(from: "abc"))
    }

    func testMessageIDRejectsAMissingValue() {
        XCTAssertNil(viewModel.messageID(from: nil))
    }

    // MARK: - Pair OAuth page-type gate

    func testOnlyThePairingV2PageMayStartAPairOAuthFlow() {
        let url = URL(string: "https://accounts.firefox.com/pair")!

        XCTAssertTrue(FxAPageType.pairingV2(url: url).allowsPairOAuthStart)
    }

    /// `qrCode` covers the in-app scanner and the debug setting, and both have already started an
    /// OAuth flow through `beginPairingAuthentication` before the page loads. Starting a second one
    /// would hand the page OAuth state belonging to a flow it did not begin.
    func testQRCodePageMayNotStartAPairOAuthFlow() {
        let url = URL(string: "https://accounts.firefox.com/pair")!

        XCTAssertFalse(FxAPageType.qrCode(url: url).allowsPairOAuthStart)
    }

    func testEmailAndSettingsPagesMayNotStartAPairOAuthFlow() {
        XCTAssertFalse(FxAPageType.emailLoginFlow.allowsPairOAuthStart)
        XCTAssertFalse(FxAPageType.settingsPage.allowsPairOAuthStart)
    }

    // MARK: - Pair OAuth reply

    func testPairOAuthReplyParametersSerializesTheParametersVerbatim() {
        let parameters = ["state": "st8", "code_challenge": "chal8"]

        XCTAssertEqual(
            PairOAuthReply.parameters(parameters).jsonObject as? [String: String],
            parameters
        )
    }

    func testPairOAuthReplyErrorNestsTheMessage() throws {
        let jsonObject = PairOAuthReply.error("boom").jsonObject
        let error = try XCTUnwrap(jsonObject["error"] as? [String: String])

        XCTAssertEqual(error, ["message": "boom"])
    }

    // MARK: - WebChannel reply envelope

    /// The page matches the reply against the id it sent, so the id must be a number, not a string.
    func testReplyScriptEmitsTheMessageIDUnquoted() {
        let script = FxAWebViewModel.webChannelReplyScript(
            typeId: "account_updates",
            messageId: 42,
            command: "fxaccounts:pair_oauth_start",
            data: "{}"
        )

        XCTAssertTrue(script.contains("messageId: 42"))
        XCTAssertFalse(script.contains("messageId: \"42\""))
    }

    func testReplyScriptCarriesTheChannelIDAndCommand() {
        let script = FxAWebViewModel.webChannelReplyScript(
            typeId: "account_updates",
            messageId: 1,
            command: "fxaccounts:fxa_status",
            data: "{}"
        )

        XCTAssertTrue(script.contains("id: \"account_updates\""))
        XCTAssertTrue(script.contains("command: \"fxaccounts:fxa_status\""))
    }

    func testReplyScriptEmbedsThePayloadVerbatimAndDispatchesTheEvent() {
        let payload = "{\"state\":\"st8\"}"
        let script = FxAWebViewModel.webChannelReplyScript(
            typeId: "account_updates",
            messageId: 7,
            command: "fxaccounts:pair_oauth_start",
            data: payload
        )

        XCTAssertTrue(script.contains(payload))
        XCTAssertTrue(script.contains("WebChannelMessageToContent"))
    }

    // MARK: - Redirect handling after login

    /// The app finishes login in native UI, so the web view must never follow the OAuth redirect.
    func testRedirectToTheOAuthRedirectURLIsCancelled() {
        let redirect = URL(string: RustFirefoxAccounts.redirectURL)

        XCTAssertEqual(viewModel.shouldAllowRedirectAfterLogIn(basedOn: redirect), .cancel)
    }

    func testNavigationToTheContentServerIsAllowed() {
        let url = URL(string: "https://accounts.firefox.com/settings")

        XCTAssertEqual(viewModel.shouldAllowRedirectAfterLogIn(basedOn: url), .allow)
    }

    func testMissingNavigationURLIsAllowed() {
        XCTAssertEqual(viewModel.shouldAllowRedirectAfterLogIn(basedOn: nil), .allow)
    }

    // MARK: - Title

    func testComposeTitleShowsALockForSecureContent() {
        let url = URL(string: "https://accounts.firefox.com/pair")

        XCTAssertEqual(viewModel.composeTitle(basedOn: url, hasOnlySecureContent: true), "🔒 accounts.firefox.com")
    }

    func testComposeTitleOmitsTheLockForInsecureContent() {
        let url = URL(string: "http://localhost:3030/pair")

        XCTAssertEqual(viewModel.composeTitle(basedOn: url, hasOnlySecureContent: false), "localhost")
    }

    func testComposeTitleIsEmptyWithoutAURL() {
        XCTAssertEqual(viewModel.composeTitle(basedOn: nil, hasOnlySecureContent: false), "")
    }

    // MARK: - User script

    func testSetupUserScriptAddsTheWebChannelScript() {
        let controller = WKUserContentController()

        viewModel.setupUserScript(for: controller)

        XCTAssertEqual(controller.userScripts.count, 1)
        XCTAssertEqual(controller.userScripts.first?.injectionTime, .atDocumentStart)
        XCTAssertTrue(controller.userScripts.first?.isForMainFrameOnly == true)
    }

    private func authenticationStatusCapabilities(
        regionCode: String = "US",
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [String: Any] {
        let provider = MockLocaleProvider(regionCode: regionCode)
        let json = try XCTUnwrap(FxAAuthenticationStatusResponse.json(localeProvider: provider), file: file, line: line)
        let data = try XCTUnwrap(json.data(using: .utf8), file: file, line: line)
        let response = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any],
            file: file,
            line: line
        )
        return try XCTUnwrap(response["capabilities"] as? [String: Any], file: file, line: line)
    }
}

extension FxAWebViewModelTests {
    private func createExpectedURL(with fileName: String, and fileExtension: String) -> URL? {
        try? FileManager.default.url(for: .documentDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: false)
        .appendingPathComponent(fileName)
        .appendingPathExtension(fileExtension)
    }
}
