// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Common
import Shared

@testable import Client

class OpenMobileConfigHelperTests: XCTestCase {
    var mockPresenter: MockPresenter!
    var mockLogger: MockLogger!
    var helper: OpenMobileConfigHelper!

    override func setUp() {
        super.setUp()
        mockPresenter = MockPresenter()
        mockLogger = MockLogger()
        helper = OpenMobileConfigHelper(presenter: mockPresenter, logger: mockLogger)
    }

    override func tearDown() {
        helper = nil
        mockLogger = nil
        mockPresenter = nil
        super.tearDown()
    }

    // MARK: - Static Method Tests

    func testShouldOpenWithMobileConfig_ValidMimeType_ReturnsTrue() {
        let result = OpenMobileConfigHelper.shouldOpenWithMobileConfig(mimeType: "application/x-apple-aspen-config")
        XCTAssertTrue(result, "Should return true for valid mobile config MIME type")
    }

    func testShouldOpenWithMobileConfig_InvalidMimeType_ReturnsFalse() {
        let result = OpenMobileConfigHelper.shouldOpenWithMobileConfig(mimeType: "text/plain")
        XCTAssertFalse(result, "Should return false for invalid MIME type")
    }

    func testShouldOpenWithMobileConfig_ForceDownloadTrue_ReturnsCorrectValue() {
        let result = OpenMobileConfigHelper.shouldOpenWithMobileConfig(
            mimeType: "application/x-apple-aspen-config",
            forceDownload: true
        )
        XCTAssertTrue(result, "Should handle forceDownload parameter correctly")
    }

    // MARK: - Data Opening Tests

    func testOpenWithData_ValidData_CallsCompletion() {
        let expectation = XCTestExpectation(description: "Completion called")
        let testData = "test mobile config data".data(using: .utf8)!

        helper.open(data: testData) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testOpenWithData_InvalidData_PresentsErrorAlert() {
        let expectation = XCTestExpectation(description: "Error alert presented")
        let invalidData = Data()

        mockPresenter.onPresentCalled = {
            expectation.fulfill()
        }

        helper.open(data: invalidData) {
            // Completion should still be called even on error
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(mockPresenter.presentCalled, "Should present error alert for invalid data")
    }

    // MARK: - URL Response Opening Tests

    func testOpenWithResponse_ValidResponse_CallsCompletion() {
        let expectation = XCTestExpectation(description: "Completion called")
        let url = URL(string: "https://example.com/config.mobileconfig")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let mockCookieStore = MockWKHTTPCookieStore()

        helper.open(response: response, cookieStore: mockCookieStore) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testOpenWithResponse_InvalidURL_PresentsErrorAlert() {
        let expectation = XCTestExpectation(description: "Error alert presented")
        let response = HTTPURLResponse(url: URL(string: "invalid://url")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let mockCookieStore = MockWKHTTPCookieStore()

        mockPresenter.onPresentCalled = {
            expectation.fulfill()
        }

        helper.open(response: response, cookieStore: mockCookieStore) {
            // Completion should still be called even on error
        }

        wait(for: [expectation], timeout: 10.0)
        XCTAssertTrue(mockPresenter.presentCalled, "Should present error alert for invalid URL")
    }

    // MARK: - Error Handling Tests

    func testErrorAlert_HasCorrectTitle() {
        let expectation = XCTestExpectation(description: "Error alert presented")
        let invalidData = Data()

        mockPresenter.onPresentCalled = {
            if let alertController = self.mockPresenter.presentedViewController as? UIAlertController {
                XCTAssertEqual(alertController.title, .UnableToOpenConfigErrorTitle, "Alert should have correct title")
                XCTAssertEqual(alertController.message, .UnableToOpenConfigErrorMessage, "Alert should have correct message")
                expectation.fulfill()
            }
        }

        helper.open(data: invalidData) {}

        wait(for: [expectation], timeout: 5.0)
    }

    func testErrorAlert_HasDismissAction() {
        let expectation = XCTestExpectation(description: "Error alert presented")
        let invalidData = Data()

        mockPresenter.onPresentCalled = {
            if let alertController = self.mockPresenter.presentedViewController as? UIAlertController {
                XCTAssertEqual(alertController.actions.count, 1, "Alert should have one action")
                XCTAssertEqual(alertController.actions.first?.title, .UnableToOpenConfigErrorDismiss, "Action should have correct title")
                XCTAssertEqual(alertController.actions.first?.style, .cancel, "Action should be cancel style")
                expectation.fulfill()
            }
        }

        helper.open(data: invalidData) {}

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Logging Tests

    func testLogging_ErrorsAreLogged() {
        let expectation = XCTestExpectation(description: "Error logged")
        let invalidData = Data()

        mockLogger.onLogCalled = { message, level, category, description in
            XCTAssertEqual(level, .warning, "Should log at warning level")
            XCTAssertEqual(category, .webview, "Should log in webview category")
            XCTAssertTrue(message.contains("mobile configuration profile"), "Should mention mobile configuration profile")
            expectation.fulfill()
        }

        helper.open(data: invalidData) {}

        wait(for: [expectation], timeout: 5.0)
    }
}

// MARK: - Mock Classes

class MockPresenter: Presenter {
    var presentCalled = false
    var presentedViewController: UIViewController?
    var onPresentCalled: (() -> Void)?

    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        presentCalled = true
        presentedViewController = viewControllerToPresent
        onPresentCalled?()
        completion?()
    }
}

class MockLogger: Logger {
    var onLogCalled: ((String, Logger.LogLevel, Logger.LogCategory, String?) -> Void)?

    func log(_ message: String,
             level: Logger.LogLevel,
             category: Logger.LogCategory,
             description: String?,
             extra: [String: Any]?) {
        onLogCalled?(message, level, category, description)
    }
}

class MockWKHTTPCookieStore: WKHTTPCookieStore {
    override func getAllCookies(_ completionHandler: @escaping ([HTTPCookie]) -> Void) {
        // Return empty cookies for testing
        completionHandler([])
    }
}

