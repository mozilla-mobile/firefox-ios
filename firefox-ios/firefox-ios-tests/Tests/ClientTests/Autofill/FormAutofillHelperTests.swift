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

class FormAutofillHelperTests: XCTestCase {
    var formAutofillHelper: FormAutofillHelper!
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
        formAutofillHelper = FormAutofillHelper(tab: tab)
        guard let jsonData = validMockPayloadJson.data(using: .utf8),
              let dictionary = try? JSONSerialization.jsonObject(
                with: jsonData,
                options: []) as? [String: Any] else {
            fatalError("Unable to convert JSON to dictionary")
        }
        validMockWKMessage = MockWKScriptMessage(
            name: "creditCardFormMessageHandler",
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
        formAutofillHelper = nil
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
        let json = FormAutofillHelper.injectionJSONBuilder(card: card)
        XCTAssertEqual(json["cc-name"] as? String, "John Doe")
        XCTAssertEqual(json["cc-number"] as? String, "1234567812345678")
        XCTAssertEqual(json["cc-exp-month"] as? Int64, 12)
        XCTAssertEqual(json["cc-exp-year"] as? Int64, 2023)
        XCTAssertEqual(json["cc-exp"] as? String, "12/2023")
    }

    func testInjectionJsonBuilder_withSpecialCharacters() {
        let card = UnencryptedCreditCardFields(ccName: "<John Doe>",
                                               ccNumber: "1234567812345678",
                                               ccNumberLast4: "5678",
                                               ccExpMonth: 12,
                                               ccExpYear: 2023,
                                               ccType: "VISA")
        let json = FormAutofillHelper.injectionJSONBuilder(card: card)
        XCTAssertEqual(json["cc-name"] as? String, "&lt;John Doe&gt;")
        XCTAssertEqual(json["cc-number"] as? String, "1234567812345678")
        XCTAssertEqual(json["cc-exp-month"] as? Int64, 12)
        XCTAssertEqual(json["cc-exp-year"] as? Int64, 2023)
        XCTAssertEqual(json["cc-exp"] as? String, "12/2023")
    }

    func testInjectionJsonBuilder_withXssPayload() {
        let card = UnencryptedCreditCardFields(ccName: "<script>alert('XSS')</script>",
                                               ccNumber: "1234567812345678",
                                               ccNumberLast4: "5678",
                                               ccExpMonth: 12,
                                               ccExpYear: 2023,
                                               ccType: "VISA")
        let json = FormAutofillHelper.injectionJSONBuilder(card: card)
        XCTAssertEqual(json["cc-name"] as? String, "&lt;script&gt;alert(&#39;XSS&#39;)&lt;/script&gt;")
        XCTAssertEqual(json["cc-number"] as? String, "1234567812345678")
        XCTAssertEqual(json["cc-exp-month"] as? Int64, 12)
        XCTAssertEqual(json["cc-exp-year"] as? Int64, 2023)
        XCTAssertEqual(json["cc-exp"] as? String, "12/2023")
    }

    func testInjectionJsonBuilder_withHtmlEntities() {
        let card = UnencryptedCreditCardFields(ccName: "&quot;John Doe&quot;",
                                               ccNumber: "1234567812345678",
                                               ccNumberLast4: "5678",
                                               ccExpMonth: 12,
                                               ccExpYear: 2023,
                                               ccType: "VISA")
        let json = FormAutofillHelper.injectionJSONBuilder(card: card)
        XCTAssertEqual(json["cc-name"] as? String, "&amp;quot;John Doe&amp;quot;")
        XCTAssertEqual(json["cc-number"] as? String, "1234567812345678")
        XCTAssertEqual(json["cc-exp-month"] as? Int64, 12)
        XCTAssertEqual(json["cc-exp-year"] as? Int64, 2023)
        XCTAssertEqual(json["cc-exp"] as? String, "12/2023")
    }

    func test_getValidPayloadData() {
        XCTAssertNotNil(formAutofillHelper.getValidPayloadData(from: validMockWKMessage))
        XCTAssertNotNil(formAutofillHelper.getValidPayloadData(from: validPayloadCaptureMockWKMessage))
    }

    func test_parseFieldType_valid() {
        let messageBodyDict = formAutofillHelper.getValidPayloadData(from: validMockWKMessage)
        let messageFields: FillCreditCardForm? = formAutofillHelper.parseFieldType(messageBody: messageBodyDict!,
                                                                                   formType: FillCreditCardForm.self)
        XCTAssertNotNil(messageFields)
        XCTAssertEqual(messageFields!.type, FormAutofillPayloadType.formInput.rawValue)
        XCTAssertEqual(messageFields!.creditCardPayload.ccExpMonth, "03")
        XCTAssertEqual(messageFields!.creditCardPayload.ccExpYear, "2999")
        XCTAssertEqual(messageFields!.creditCardPayload.ccName, "Josh Moustache")
        XCTAssertEqual(messageFields!.creditCardPayload.ccNumber, "4520 2991 2039 6788")
    }

    func test_parseFieldCaptureJsonType_valid() {
        let messageBodyDict = formAutofillHelper.getValidPayloadData(from: validPayloadCaptureMockWKMessage)
        let messageFields: FillCreditCardForm? = formAutofillHelper.parseFieldType(messageBody: messageBodyDict!,
                                                                                   formType: FillCreditCardForm.self)
        XCTAssertNotNil(messageFields)
        XCTAssertEqual(messageFields!.type, FormAutofillPayloadType.formSubmit.rawValue)
        XCTAssertEqual(messageFields!.creditCardPayload.ccExpMonth, "03")
        XCTAssertEqual(messageFields!.creditCardPayload.ccExpYear, "2999")
        XCTAssertEqual(messageFields!.creditCardPayload.ccName, "Josh Moustache")
        XCTAssertEqual(messageFields!.creditCardPayload.ccNumber, "4520 2991 2039 6788")
    }

    // MARK: Retrieval

    func test_getFieldTypeValues() {
        let messageBodyDict = formAutofillHelper.getValidPayloadData(from: validMockWKMessage)
        let messageFields: FillCreditCardForm? = formAutofillHelper.parseFieldType(messageBody: messageBodyDict!,
                                                                                   formType: FillCreditCardForm.self)

        XCTAssertNotNil(messageFields)
        if let fieldValues = formAutofillHelper.getFieldTypeValues(
            payload: messageFields!.creditCardPayload).fieldData as? UnencryptedCreditCardFields {
            XCTAssertEqual(fieldValues.ccExpMonth, 3)
            XCTAssertEqual(fieldValues.ccExpYear, 2999)
            XCTAssertEqual(fieldValues.ccName, "Josh Moustache")
            XCTAssertEqual(fieldValues.ccNumberLast4, "6788")
            XCTAssertEqual(fieldValues.ccType, "VISA")
        }
    }

    // MARK: Leaks

    func testFormAutofillHelperBasicCreationDoesntLeak() {
        let subject = FormAutofillHelper(tab: tab)
        trackForMemoryLeaks(subject)
    }

    func test_formAutofillHelper_foundFieldValuesClosure_doesntLeak() {
        let tab = Tab(profile: profile, configuration: WKWebViewConfiguration())
        let subject = FormAutofillHelper(tab: tab)
        trackForMemoryLeaks(subject)
        tab.createWebview()
        tab.addContentScript(subject, name: FormAutofillHelper.name())

        subject.foundFieldValues = { fieldValues, type, frame in
            guard let tabWebView = tab.webView else { return }
            tabWebView.accessoryView.savedCardsClosure = {}
        }

        tab.close()
    }

    func testScriptMessageHandlerNames() {
        let formAutofillHelper = FormAutofillHelper(tab: tab)
        let handlerNames = formAutofillHelper.scriptMessageHandlerNames()

        // Assert that the handler names are not nil and contain expected values
        XCTAssertNotNil(handlerNames)
        XCTAssertEqual(handlerNames?.count, 2) // Assuming you have two handler names

        XCTAssertTrue(handlerNames!.contains(FormAutofillHelper.HandlerName.addressFormMessageHandler.rawValue))
        XCTAssertTrue(handlerNames!.contains(FormAutofillHelper.HandlerName.creditCardFormMessageHandler.rawValue))
    }

    func testUserContentControllerDidReceiveScriptMessage_withAddressHandler() {
        let formAutofillHelper = FormAutofillHelper(tab: tab)

        // Create a mock WKScriptMessage with handler name "addressFormMessageHandler"
        let mockBody: [String: Any] = ["type": "fill-address-form",
                                       "payload": ["address-level1": "123 Main St",
                                                   "address-level2": "Apt 101",
                                                   "email": "mozilla@mozzilla.com",
                                                   "street-address": "123 mozilla",
                                                   "name": "John",
                                                   "organization": "Mozilla",
                                                   "postal-code": "12345",
                                                   "country": "USA"]]
        let mockAddressScriptMessage = MockWKScriptMessage(
            name: FormAutofillHelper.HandlerName.addressFormMessageHandler.rawValue,
            body: mockBody)

        // Create an expectation for the closure to be called
        let expectation = XCTestExpectation(description: "foundFieldValues closure should be called")

        // Set up the closure to fulfill the expectation
        formAutofillHelper.foundFieldValues = { payload, _, _ in
            XCTAssertEqual(payload.fieldValue, .address)
            expectation.fulfill()
        }

        // Test user content controller's didReceiveScriptMessage method with the mock message
        formAutofillHelper.userContentController(
            WKUserContentController(),
            didReceiveScriptMessage: mockAddressScriptMessage)

        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 2.0)
    }

    func testUserContentControllerDidReceiveScriptMessage_withCreditCardHandler() {
        let formAutofillHelper = FormAutofillHelper(tab: tab)

        // Create a mock WKScriptMessage with handler name "creditCardFormMessageHandler"
        let mockBody: [String: Any] = ["type": "fill-credit-card-form",
                                       "payload": ["cc-number": "1234567812345678",
                                                   "cc-name": "John Doe",
                                                   "cc-exp-month": "12",
                                                   "cc-exp": "12",
                                                   "cc-exp-year": "2023"]]
        let mockCreditCardScriptMessage = MockWKScriptMessage(
            name: FormAutofillHelper.HandlerName.creditCardFormMessageHandler.rawValue,
            body: mockBody)

        // Create an expectation for the closure to be called
        let expectation = XCTestExpectation(description: "foundFieldValues closure should be called")

        // Set up the closure to fulfill the expectation
        formAutofillHelper.foundFieldValues = { payload, _, _ in
            XCTAssertEqual(payload.fieldValue, .creditCard)
            expectation.fulfill()
        }

        // Test user content controller's didReceiveScriptMessage method with the mock message
        formAutofillHelper.userContentController(
            WKUserContentController(),
            didReceiveScriptMessage: mockCreditCardScriptMessage)

        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
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
