// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Foundation
import XCTest
import WebKit
import Shared
import Common
import Storage

class CreditCardHelperTests: XCTestCase {
    var creditCardHelper: CreditCardHelper!
    var tab: Tab!
    var profile: MockProfile!
    var validMockWKMessage: MockWKScriptMessage!
    let validMockPayloadJson = """
        {
          "type" : "fill-credit-card-form",
          "payload" : {
            "cc-number" : "4520 2991 2039 6788",
            "cc-name" : "Josh Moustache",
            "cc-exp-month" : "03",
            "cc-exp" : "02",
            "cc-exp-year" : "2999"
          }
        }
    """
    var validPayloadCaptureMockWKMessage: MockWKScriptMessage!
    // We need the `capture-credit-card-form`
    // to know when form submission happend
    let validMockPayloadCaptureJson = """
        {
          "type" : "capture-credit-card-form",
          "payload" : {
            "cc-number" : "4520 2991 2039 6788",
            "cc-name" : "Josh Moustache",
            "cc-exp-month" : "03",
            "cc-exp" : "02",
            "cc-exp-year" : "2999"
          }
        }
    """

    override func setUp() {
        super.setUp()
        profile = MockProfile()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        tab = Tab(profile: profile, configuration: WKWebViewConfiguration())
        creditCardHelper = CreditCardHelper(tab: tab)
        guard let jsonData = validMockPayloadJson.data(using: .utf8),
              let dictionary = try? JSONSerialization.jsonObject(
                with: jsonData,
                options: []) as? [String: Any] else {
            fatalError("Unable to convert JSON to dictionary")
        }
        validMockWKMessage = MockWKScriptMessage(
            name: "validMockWKMessage",
            body: dictionary)
        guard let jsonDataCapture = validMockPayloadCaptureJson.data(using: .utf8),
              let dictionaryCapture = try? JSONSerialization.jsonObject(
                with: jsonDataCapture,
                options: []) as? [String: Any] else {
            fatalError("Unable to convert JSON to dictionary")
        }
        validPayloadCaptureMockWKMessage =  MockWKScriptMessage(
            name: "validPayloadCaptureMockWKMessage",
            body: dictionaryCapture)
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
        DependencyHelperMock().reset()
        tab = nil
        creditCardHelper = nil
        validMockWKMessage = nil
        validPayloadCaptureMockWKMessage = nil
    }

    // MARK: Parsing

    func testInjectionJsonBuilder_noSpecialCharacters() {
        let card = UnencryptedCreditCardFields(ccName: "John Doe",
                                               ccNumber: "1234567812345678",
                                               ccNumberLast4: "5678",
                                               ccExpMonth: 12,
                                               ccExpYear: 2023,
                                               ccType: "VISA")
        let json = CreditCardHelper.injectionJSONBuilder(card: card)
        XCTAssertEqual(json["cc-name"] as? String, "John Doe")
        XCTAssertEqual(json["cc-number"] as? String, "1234567812345678")
        XCTAssertEqual(json["cc-exp-month"] as? String, "12")
        XCTAssertEqual(json["cc-exp-year"] as? String, "2023")
        XCTAssertEqual(json["cc-exp"] as? String, "12/2023")
    }

    func testInjectionJsonBuilder_withSpecialCharacters() {
        let card = UnencryptedCreditCardFields(ccName: "<John Doe>",
                                               ccNumber: "1234567812345678",
                                               ccNumberLast4: "5678",
                                               ccExpMonth: 12,
                                               ccExpYear: 2023,
                                               ccType: "VISA")
        let json = CreditCardHelper.injectionJSONBuilder(card: card)
        XCTAssertEqual(json["cc-name"] as? String, "&lt;John Doe&gt;")
        XCTAssertEqual(json["cc-number"] as? String, "1234567812345678")
        XCTAssertEqual(json["cc-exp-month"] as? String, "12")
        XCTAssertEqual(json["cc-exp-year"] as? String, "2023")
        XCTAssertEqual(json["cc-exp"] as? String, "12/2023")
    }

    func testInjectionJsonBuilder_withXssPayload() {
        let card = UnencryptedCreditCardFields(ccName: "<script>alert('XSS')</script>",
                                               ccNumber: "1234567812345678",
                                               ccNumberLast4: "5678",
                                               ccExpMonth: 12,
                                               ccExpYear: 2023,
                                               ccType: "VISA")
        let json = CreditCardHelper.injectionJSONBuilder(card: card)
        XCTAssertEqual(json["cc-name"] as? String, "&lt;script&gt;alert(&#39;XSS&#39;)&lt;/script&gt;")
        XCTAssertEqual(json["cc-number"] as? String, "1234567812345678")
        XCTAssertEqual(json["cc-exp-month"] as? String, "12")
        XCTAssertEqual(json["cc-exp-year"] as? String, "2023")
        XCTAssertEqual(json["cc-exp"] as? String, "12/2023")
    }

    func testInjectionJsonBuilder_withHtmlEntities() {
        let card = UnencryptedCreditCardFields(ccName: "&quot;John Doe&quot;",
                                               ccNumber: "1234567812345678",
                                               ccNumberLast4: "5678",
                                               ccExpMonth: 12,
                                               ccExpYear: 2023,
                                               ccType: "VISA")
        let json = CreditCardHelper.injectionJSONBuilder(card: card)
        XCTAssertEqual(json["cc-name"] as? String, "&amp;quot;John Doe&amp;quot;")
        XCTAssertEqual(json["cc-number"] as? String, "1234567812345678")
        XCTAssertEqual(json["cc-exp-month"] as? String, "12")
        XCTAssertEqual(json["cc-exp-year"] as? String, "2023")
        XCTAssertEqual(json["cc-exp"] as? String, "12/2023")
    }

    func test_getValidPayloadData() {
        XCTAssertNotNil(creditCardHelper.getValidPayloadData(from: validMockWKMessage))
        XCTAssertNotNil(creditCardHelper.getValidPayloadData(from: validPayloadCaptureMockWKMessage))
    }

    func test_parseFieldType_valid() {
        let messageBodyDict = creditCardHelper.getValidPayloadData(from: validMockWKMessage)
        let messageFields = creditCardHelper.parseFieldType(messageBody: messageBodyDict!)
        XCTAssertNotNil(messageFields)
        XCTAssertEqual(messageFields!.type, CreditCardPayloadType.formInput.rawValue)
        XCTAssertEqual(messageFields!.creditCardPayload.ccExpMonth, "03")
        XCTAssertEqual(messageFields!.creditCardPayload.ccExpYear, "2999")
        XCTAssertEqual(messageFields!.creditCardPayload.ccName, "Josh Moustache")
        XCTAssertEqual(messageFields!.creditCardPayload.ccNumber, "4520 2991 2039 6788")
    }

    func test_parseFieldCaptureJsonType_valid() {
        let messageBodyDict = creditCardHelper.getValidPayloadData(from: validPayloadCaptureMockWKMessage)
        let messageFields = creditCardHelper.parseFieldType(messageBody: messageBodyDict!)
        XCTAssertNotNil(messageFields)
        XCTAssertEqual(messageFields!.type, CreditCardPayloadType.formSubmit.rawValue)
        XCTAssertEqual(messageFields!.creditCardPayload.ccExpMonth, "03")
        XCTAssertEqual(messageFields!.creditCardPayload.ccExpYear, "2999")
        XCTAssertEqual(messageFields!.creditCardPayload.ccName, "Josh Moustache")
        XCTAssertEqual(messageFields!.creditCardPayload.ccNumber, "4520 2991 2039 6788")
    }

    // MARK: Retrieval

    func test_getFieldTypeValues() {
        let messageBodyDict = creditCardHelper.getValidPayloadData(from: validMockWKMessage)
        let messageFields = creditCardHelper.parseFieldType(messageBody: messageBodyDict!)
        XCTAssertNotNil(messageFields)
        let fieldValues = creditCardHelper.getFieldTypeValues(payload: messageFields!.creditCardPayload)
        XCTAssertEqual(fieldValues.ccExpMonth, 3)
        XCTAssertEqual(fieldValues.ccExpYear, 2999)
        XCTAssertEqual(fieldValues.ccName, "Josh Moustache")
        XCTAssertEqual(fieldValues.ccNumberLast4, "6788")
        XCTAssertEqual(fieldValues.ccType, "VISA")
    }

    // MARK: Leaks

    func test_creditCardHelper_basicCreation_doesntLeak() {
        let subject = CreditCardHelper(tab: tab)
        trackForMemoryLeaks(subject)
    }

    func test_creditCardHelper_foundFieldValuesClosure_doesntLeak() {
        let tab = Tab(profile: profile, configuration: WKWebViewConfiguration())
        let subject = CreditCardHelper(tab: tab)
        trackForMemoryLeaks(subject)
        tab.createWebview()
        tab.addContentScript(subject, name: CreditCardHelper.name())

        subject.foundFieldValues = { fieldValues, type, frame in
            guard let tabWebView = tab.webView else { return }
            tabWebView.accessoryView.savedCardsClosure = {}
        }

        tab.close()
    }
}

// MARK: - MockWKScriptMessage
class MockWKScriptMessage: WKScriptMessage {
    var mockBody: Any
    var mockName: String

    init(name: String, body: Any) {
        mockName = name
        mockBody = body
    }

    override var body: Any {
        return mockBody
    }

    override var name: String {
        return mockName
    }
}
