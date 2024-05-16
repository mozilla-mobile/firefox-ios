// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest
import PDFKit

class FxAWebViewModelTests: XCTestCase {
    var viewModel: FxAWebViewModel!
    var deeplinkParams: FxALaunchParams!

    override func setUp() {
        super.setUp()
        deeplinkParams = FxALaunchParams(entrypoint: .browserMenu, query: ["test_key": "test_value"])
        viewModel = FxAWebViewModel(pageType: .settingsPage, profile: MockProfile(), deepLinkParams: deeplinkParams)
    }

    override func tearDown() {
        deeplinkParams = nil
        viewModel = nil
        super.tearDown()
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
            XCTAssertTrue(result, "Should return true for a valid blob URL and a webView URL with the host accounts.firefox.com.")
        }
    }

    func testIsMozillaAccountPDFWithValidBlobURLAndIncorrectHost() {
        if let blobURL = URL(string: "blob://some/blob/url"),
           let webViewURL = URL(string: "https://example.com") {
            let result = viewModel.isMozillaAccountPDF(blobURL: blobURL, webViewURL: webViewURL)
            XCTAssertFalse(result, "Should return false for a valid blob URL and a webView URL with a different host then accounts.firefox.com")
        }
    }

    func testIsMozillaAccountPDFWithInvalidBlobURLAndCorrectHost() {
        if let blobURL = URL(string: "https://example.com/blob"),
           let webViewURL = URL(string: "https://accounts.firefox.com") {
            let result = viewModel.isMozillaAccountPDF(blobURL: blobURL, webViewURL: webViewURL)
            XCTAssertFalse(result, "Should return false for a wrong blob URL and a webView URL with the host accounts.firefox.com.")
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
