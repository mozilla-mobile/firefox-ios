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
    var validMockWKMessage: WKScriptMessageMock!
    var secureWebviewMock: WKWebViewMock!
    var secureFrameMock: WKFrameInfoMock!
    let windowUUID: WindowUUID = .XCTestDefaultUUID
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
    var validPayloadCaptureMockWKMessage: WKScriptMessageMock!
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
        tab = Tab(profile: profile, windowUUID: windowUUID)
        formAutofillHelper = FormAutofillHelper(tab: tab)
        secureWebviewMock = WKWebViewMock(URL(string: "https://foo.com")!)
        secureFrameMock = WKFrameInfoMock(webView: secureWebviewMock, frameURL: URL(string: "https://foo.com")!)
        guard let jsonData = validMockPayloadJson.data(using: .utf8),
              let dictionary = try? JSONSerialization.jsonObject(
                with: jsonData,
                options: []) as? [String: Any] else {
            fatalError("Unable to convert JSON to dictionary")
        }
        validMockWKMessage = WKScriptMessageMock(
            name: "creditCardFormMessageHandler",
            body: dictionary,
            frameInfo: secureFrameMock)
        guard let jsonDataCapture = validMockPayloadCaptureJson.data(using: .utf8),
              let dictionaryCapture = try? JSONSerialization.jsonObject(
                with: jsonDataCapture,
                options: []) as? [String: Any] else {
            fatalError("Unable to convert JSON to dictionary")
        }
        validPayloadCaptureMockWKMessage =  WKScriptMessageMock(
            name: "validPayloadCaptureMockWKMessage",
            body: dictionaryCapture,
            frameInfo: secureFrameMock)
    }

    override func tearDown() {
        profile = nil
        DependencyHelperMock().reset()
        tab = nil
        formAutofillHelper = nil
        validMockWKMessage = nil
        validPayloadCaptureMockWKMessage = nil
        secureFrameMock = nil
        secureWebviewMock = nil
        super.tearDown()
    }

    // MARK: Parsing

    func testInjectionJsonBuilder_addressNoSpecialCharacters() {
        // Arrange
        let address = UnencryptedAddressFields(addressLevel1: "123 Main St",
                                               organization: "Mozilla",
                                               country: "USA",
                                               addressLevel2: "Apt 101",
                                               addressLevel3: "Suburb",
                                               email: "mozilla@mozilla.com",
                                               streetAddress: "123 Mozilla",
                                               name: "John",
                                               postalCode: "12345",
                                               tel: "+16509030800")

        // Act
        let json = FormAutofillHelper.injectionJSONBuilder(address: address)

        // Assert
        XCTAssertEqual(json["organization"] as? String, "Mozilla")
        XCTAssertEqual(json["street-address"] as? String, "123 Mozilla")
        XCTAssertEqual(json["name"] as? String, "John")
        XCTAssertEqual(json["country"] as? String, "USA")
        XCTAssertEqual(json["address-level1"] as? String, "123 Main St")
        XCTAssertEqual(json["address-level2"] as? String, "Apt 101")
        XCTAssertEqual(json["address-level3"] as? String, "Suburb")
        XCTAssertEqual(json["email"] as? String, "mozilla@mozilla.com")
        XCTAssertEqual(json["postal-code"] as? String, "12345")
        XCTAssertEqual(json["tel"] as? String, "+16509030800")
    }

    func testUserContentControllerDidReceiveScriptMessage_withAddressHandler() {
        // Arrange
        let formAutofillHelper = FormAutofillHelper(tab: tab)

        // Create a mock WKScriptMessage with handler name "addressFormMessageHandler"
        let mockBody: [String: Any] = ["type": "fill-address-form",
                                       "payload": ["address-level1": "123 Main St",
                                                   "address-level2": "Apt 101",
                                                   "address-level3": "Suburb",
                                                   "email": "mozilla@mozilla.com",
                                                   "street-address": "123 Mozilla",
                                                   "name": "John",
                                                   "organization": "Mozilla",
                                                   "postal-code": "12345",
                                                   "tel": "+16509030800",
                                                   "country": "USA"]]
        let mockAddressScriptMessage = WKScriptMessageMock(
            name: FormAutofillHelper.HandlerName.addressFormMessageHandler.rawValue,
            body: mockBody,
            frameInfo: secureFrameMock)

        // Create an expectation for the closure to be called
        let expectation = XCTestExpectation(description: "foundFieldValues closure should be called")

        // Set up the closure to fulfill the expectation
        formAutofillHelper.foundFieldValues = { payload, _, _ in
            XCTAssertEqual(payload.fieldValue, .address)

            // Cast fieldData to the expected type directly in the test
            if let addressPayload = payload.fieldData as? UnencryptedAddressFields {
                XCTAssertEqual(addressPayload.addressLevel1, "123 Main St")
                XCTAssertEqual(addressPayload.addressLevel2, "Apt 101")
                XCTAssertEqual(addressPayload.addressLevel3, "Suburb")
                XCTAssertEqual(addressPayload.email, "mozilla@mozilla.com")
                XCTAssertEqual(addressPayload.streetAddress, "123 Mozilla")
                XCTAssertEqual(addressPayload.name, "John")
                XCTAssertEqual(addressPayload.organization, "Mozilla")
                XCTAssertEqual(addressPayload.postalCode, "12345")
                XCTAssertEqual(addressPayload.country, "USA")
                XCTAssertEqual(addressPayload.tel, "+16509030800")
            } else {
                XCTFail("Failed to cast fieldData to expected type")
            }

            expectation.fulfill()
        }

        // Act: Test user content controller's didReceiveScriptMessage method with the mock message
        formAutofillHelper.userContentController(
            WKUserContentController(),
            didReceiveScriptMessage: mockAddressScriptMessage)

        // Assert: Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
    }

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

    func test_parseFieldType_valid() {
        let messageFields = validMockWKMessage.decodeBody(as: FillCreditCardForm.self)
        XCTAssertNotNil(messageFields)
        XCTAssertEqual(messageFields!.type, FormAutofillPayloadType.formInput.rawValue)
        XCTAssertEqual(messageFields!.creditCardPayload.ccExpMonth, "03")
        XCTAssertEqual(messageFields!.creditCardPayload.ccExpYear, "2999")
        XCTAssertEqual(messageFields!.creditCardPayload.ccName, "Josh Moustache")
        XCTAssertEqual(messageFields!.creditCardPayload.ccNumber, "4520 2991 2039 6788")
    }

    func test_parseFieldCaptureJsonType_valid() {
        let messageFields = validPayloadCaptureMockWKMessage.decodeBody(as: FillCreditCardForm.self)

        XCTAssertNotNil(messageFields)
        XCTAssertEqual(messageFields!.type, FormAutofillPayloadType.formSubmit.rawValue)
        XCTAssertEqual(messageFields!.creditCardPayload.ccExpMonth, "03")
        XCTAssertEqual(messageFields!.creditCardPayload.ccExpYear, "2999")
        XCTAssertEqual(messageFields!.creditCardPayload.ccName, "Josh Moustache")
        XCTAssertEqual(messageFields!.creditCardPayload.ccNumber, "4520 2991 2039 6788")
    }

    // MARK: Retrieval

    func test_getFieldTypeValues() {
        let messageFields = validPayloadCaptureMockWKMessage.decodeBody(as: FillCreditCardForm.self)

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
        let tab = Tab(profile: profile, windowUUID: windowUUID)
        let subject = FormAutofillHelper(tab: tab)
        trackForMemoryLeaks(subject)
        tab.createWebview(configuration: .init())
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
        XCTAssertEqual(handlerNames?.count, 3) // Assuming you have three handler names

        XCTAssertTrue(handlerNames!.contains(FormAutofillHelper.HandlerName.addressFormMessageHandler.rawValue))
        XCTAssertTrue(handlerNames!.contains(FormAutofillHelper.HandlerName.creditCardFormMessageHandler.rawValue))
        XCTAssertTrue(handlerNames!.contains(FormAutofillHelper.HandlerName.addressFormTelemetryMessageHandler.rawValue))
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
        let mockCreditCardScriptMessage = WKScriptMessageMock(
            name: FormAutofillHelper.HandlerName.creditCardFormMessageHandler.rawValue,
            body: mockBody,
            frameInfo: secureFrameMock)

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
