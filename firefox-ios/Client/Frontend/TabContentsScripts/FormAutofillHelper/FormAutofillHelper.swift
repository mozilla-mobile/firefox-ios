// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebKit
import Common
import Storage

enum AutofillFieldValueType: String {
    case address
    case creditCard
}

struct AutofillFieldValuePayload {
    let fieldValue: AutofillFieldValueType
    let fieldData: Any?
}

class FormAutofillHelper: TabContentScript {
    // MARK: - Handler Names Enum
    enum HandlerName: String {
        case addressFormMessageHandler
        case creditCardFormMessageHandler
        case addressFormTelemetryMessageHandler
    }

    // MARK: - Properties

    private weak var tab: Tab?
    private var logger: Logger = DefaultLogger.shared
    private var frame: WKFrameInfo?

    // Closure to send the field values
    var foundFieldValues: ((AutofillFieldValuePayload,
                            FormAutofillPayloadType?,
                            WKFrameInfo?) -> Void)?

    // MARK: - Class Methods

    class func name() -> String {
        return "FormAutofillHelper"
    }

    // MARK: - Initialization

    required init(tab: Tab) {
        self.tab = tab
    }

    // MARK: - Script Message Handler

    func scriptMessageHandlerNames() -> [String]? {
        return [HandlerName.addressFormMessageHandler.rawValue,
                HandlerName.addressFormTelemetryMessageHandler.rawValue,
                HandlerName.creditCardFormMessageHandler.rawValue]
    }

    // MARK: - Deinitialization

    func prepareForDeinit() {
        foundFieldValues = nil
    }

    // MARK: - Retrieval

    /// Called when the user content controller receives a script message.
    ///
    /// - Parameters:
    ///   - userContentController: The user content controller.
    ///   - message: The script message received.
    func userContentController(_ userContentController: WKUserContentController,
                               didReceiveScriptMessage message: WKScriptMessage) {
        // Note: We require frame so that we can submit information
        // to an embedded iframe on a webpage for injecting card info
        frame = message.frameInfo

        guard let frame = frame else { return }
        let isSecureContext = frame.isFrameLoadedInSecureContext

        processMessage(name: message.name, body: message.body, isSecureContext: isSecureContext, frame: frame)
    }

    func processMessage(name: String, body: Any, isSecureContext: Bool, frame: WKFrameInfo?) {
        guard isSecureContext else {
            logger.log("Ignoring request as it came from an insecure context",
                       level: .info,
                       category: .webview)
            return
        }

        switch HandlerName(rawValue: name) {
        case .addressFormTelemetryMessageHandler:
            guard let addressValues = decode(body, as: AddressFormData.self) else { return }

            if addressValues.object == "address_form" {
                switch addressValues.method {
                case .detected:
                    TelemetryWrapper.recordEvent(category: .action, method: .detect, object: .addressForm)
                case .filled:
                    TelemetryWrapper.recordEvent(category: .action, method: .detect, object: .addressFormFilled)
                case .filledModified:
                    TelemetryWrapper.recordEvent(category: .action, method: .change, object: .addressFormFilledModified)
                case .none:
                    return
                }
            }

        case .addressFormMessageHandler:
            guard let fieldValues = decode(body, as: FillAddressAutofillForm.self) else {
                logger.log("Unable to find the payloadType for the address form JS input",
                           level: .warning,
                           category: .webview)
                return
            }

            foundFieldValues?(getFieldTypeValues(payload: fieldValues.payload), fieldValues.type, frame)

        case .creditCardFormMessageHandler:
            guard let fieldValues = decode(body, as: FillCreditCardForm.self),
                  let payloadType = FormAutofillPayloadType(rawValue: fieldValues.type) else {
                logger.log("Unable to find the payloadType for the credit card form JS input",
                           level: .warning,
                           category: .webview)
                return
            }

            let payloadData = fieldValues.creditCardPayload
            foundFieldValues?(getFieldTypeValues(payload: payloadData), payloadType, frame)

        case .none:
            break
        }
    }

    func getFieldTypeValues(payload: CreditCardPayload) -> AutofillFieldValuePayload {
        var ccPlainText = UnencryptedCreditCardFields()
        let creditCardValidator = CreditCardValidator()

        ccPlainText.ccName = payload.ccName
        ccPlainText.ccExpMonth = Int64(payload.ccExpMonth.filter { $0.isNumber }) ?? 0
        ccPlainText.ccExpYear = Int64(payload.ccExpYear.filter { $0.isNumber }) ?? 0
        ccPlainText.ccNumber = "\(payload.ccNumber.filter { $0.isNumber })"
        ccPlainText.ccNumberLast4 = ccPlainText.ccNumber.count > 4 ? String(ccPlainText.ccNumber.suffix(4)) : ""
        ccPlainText.ccType = creditCardValidator.cardTypeFor(ccPlainText.ccNumber)?.rawValue ?? ""
        return AutofillFieldValuePayload(fieldValue: .creditCard, fieldData: ccPlainText)
    }

    func getFieldTypeValues(payload: FillAddressAutofillForm.Payload) -> AutofillFieldValuePayload {
        let addressPlainText = UnencryptedAddressFields(
            addressLevel1: payload.addressLevel1 ?? "",
            organization: payload.organization ?? "",
            country: payload.country ?? "",
            addressLevel2: payload.addressLevel2 ?? "",
            addressLevel3: payload.addressLevel3 ?? "",
            email: payload.email ?? "",
            streetAddress: payload.streetAddress ?? "",
            name: payload.name ?? "",
            postalCode: payload.postalCode ?? "",
            tel: payload.tel ?? ""
        )

        return AutofillFieldValuePayload(fieldValue: .address, fieldData: addressPlainText)
    }

    // MARK: - Injection

    @MainActor
    static func injectAddressInfo(logger: Logger,
                                  address: UnencryptedAddressFields,
                                  tab: Tab,
                                  frame: WKFrameInfo? = nil,
                                  completion: @escaping (Error?) -> Void) {
        do {
            let jsonBuilder = FormAutofillHelper.injectionJSONBuilder(address: address)
            let jsonData = try JSONSerialization.data(withJSONObject: jsonBuilder)
            guard let jsonDataVal = String(data: jsonData, encoding: .utf8) else {
                completion(FormAutofillHelperError.injectionInvalidJSON)
                return
            }

            guard let webView = tab.webView else {
                completion(FormAutofillHelperError.injectionIssue)
                return
            }

            let fillAddressInfoCallback = "__firefox__.FormAutofillHelper.fillFormFields(\(jsonDataVal))"
            webView.evaluateJavascriptInDefaultContentWorld(fillAddressInfoCallback, frame) { _, error in
                if let error = error {
                    completion(error)
                    logger.log("Address script error \(error)", level: .debug, category: .autofill)
                } else {
                    completion(nil)
                }
            }
        } catch let error as NSError {
            logger.log("Address script error \(error)", level: .debug, category: .autofill)
        }
    }

    @MainActor
    static func injectCardInfo(logger: Logger,
                               card: UnencryptedCreditCardFields,
                               tab: Tab,
                               frame: WKFrameInfo? = nil,
                               completion: @escaping (Error?) -> Void) {
        guard !card.ccNumber.isEmpty,
              card.ccExpYear > 0,
              !card.ccName.isEmpty
        else {
            completion(FormAutofillHelperError.injectionInvalidFields)
            return
        }

        do {
            let jsonBuilder = FormAutofillHelper.injectionJSONBuilder(card: card)
            let jsonData = try JSONSerialization.data(withJSONObject: jsonBuilder)
            guard let jsonDataVal = String(data: jsonData, encoding: .utf8) else {
                completion(FormAutofillHelperError.injectionInvalidJSON)
                return
            }

            guard let webView = tab.webView else {
                completion(FormAutofillHelperError.injectionIssue)
                return
            }

            let fillCreditCardInfoCallback = "__firefox__.FormAutofillHelper.fillFormFields(\(jsonDataVal))"
            webView.evaluateJavascriptInDefaultContentWorld(fillCreditCardInfoCallback, frame) { _, error in
                if let error = error {
                    TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .creditCardAutofillFailed)
                    completion(error)
                    logger.log("Credit card script error \(error)", level: .debug, category: .webview)
                } else {
                    TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .creditCardAutofilled)
                    completion(nil)
                }
            }
        } catch let error as NSError {
            logger.log("Credit card script error \(error)", level: .debug, category: .webview)
        }
    }

    static func injectionJSONBuilder(address: UnencryptedAddressFields) -> [String: Any] {
        let sanitizedOrganization = address.organization.htmlEntityEncodedString
        let sanitizedStreetAddress = address.streetAddress.htmlEntityEncodedString
        let sanitizedName = address.name.htmlEntityEncodedString
        let sanitizedCountry = address.country.htmlEntityEncodedString
        let sanitizedAddressLevel1 = address.addressLevel1.htmlEntityEncodedString
        let sanitizedAddressLevel2 = address.addressLevel2.htmlEntityEncodedString
        let sanitizedAddressLevel3 = address.addressLevel3.htmlEntityEncodedString
        let sanitizedEmail = address.email.htmlEntityEncodedString
        let sanitizedPostalCode = address.postalCode.htmlEntityEncodedString
        let sanitizedTel = address.tel.htmlEntityEncodedString

        let injectionJSON: [String: Any] = [
            "organization": sanitizedOrganization,
            "street-address": sanitizedStreetAddress,
            "name": sanitizedName,
            "country": sanitizedCountry,
            "address-level1": sanitizedAddressLevel1,
            "address-level2": sanitizedAddressLevel2,
            "address-level3": sanitizedAddressLevel3,
            "email": sanitizedEmail,
            "postal-code": sanitizedPostalCode,
            "tel": sanitizedTel
        ]
        return injectionJSON
    }

    static func injectionJSONBuilder(card: UnencryptedCreditCardFields) -> [String: Any] {
        let sanitizedName = card.ccName.htmlEntityEncodedString
        let sanitizedNumber = card.ccNumber.htmlEntityEncodedString
        let injectionJSON: [String: Any] = [
            "cc-name": sanitizedName,
            "cc-number": sanitizedNumber,
            "cc-exp-month": card.ccExpMonth,
            "cc-exp-year": card.ccExpYear,
            "cc-exp": "\(card.ccExpMonth)/\(card.ccExpYear)",
        ]
        return injectionJSON
    }

    // MARK: - Focus Management

    @MainActor
    static func focusNextInputField(tabWebView: WKWebView, logger: Logger) {
        let fxWindowValExtras = "window.__firefox__.FormAutofillExtras"
        let fillCreditCardInfoCallback = "\(fxWindowValExtras).focusNextInputField()"

        tabWebView.evaluateJavascriptInDefaultContentWorld(fillCreditCardInfoCallback) { _, error in
            if let error = error {
                logger.log("Unable to go to the next field: \(error)", level: .debug, category: .webview)
            }
        }
    }

    @MainActor
    static func focusPreviousInputField(tabWebView: WKWebView, logger: Logger) {
        let fxWindowValExtras = "window.__firefox__.FormAutofillExtras"
        let fillCreditCardInfoCallback = "\(fxWindowValExtras).focusPreviousInputField()"

        tabWebView.evaluateJavascriptInDefaultContentWorld(fillCreditCardInfoCallback) { _, error in
            if let error = error {
                logger.log("Unable to go to the previous field: \(error)", level: .debug, category: .webview)
            }
        }
    }

    // Note: document.activeElement.blur() is used to remove the focus from the
    // currently focused element on a web page. When an element is focused,
    // it typically has a visual indication such as a highlighted border or change in appearance.
    // The reason we do it is because after pressing done the focus still remains in WKWebView
    @MainActor
    static func blurActiveElement(tabWebView: WKWebView, logger: Logger) {
        let fillCreditCardInfoCallback = "document.activeElement.blur()"
        tabWebView.evaluateJavascriptInDefaultContentWorld(fillCreditCardInfoCallback) { _, error in
            if let error = error {
                logger.log("Unable to remove focus from the current field: \(error)", level: .debug, category: .webview)
            }
        }
    }

    /// Helper method to decode message body into a Decodable type
    ///
    /// This replaces the need for WKScriptMessage.decodeBody extension by allowing
    /// us to decode message bodies without requiring a WKScriptMessage instance.
    /// This is essential for testing, as WKScriptMessage and WKFrameInfo cannot be
    /// safely mocked (they crash on deallocation).
    /// - Parameters:
    ///   - body: The message body to decode (typically a dictionary or string)
    ///   - type: The Decodable type to decode into
    /// - Returns: The decoded object, or nil if decoding fails
    private func decode<T: Decodable>(_ body: Any, as type: T.Type) -> T? {
        if let dict = body as? [String: Any], let data = try? JSONSerialization.data(withJSONObject: dict, options: []) {
            return try? JSONDecoder().decode(type, from: data)
        } else if let bodyString = body as? String, let data = bodyString.data(using: .utf8) {
            return try? JSONDecoder().decode(type, from: data)
        } else {
            return nil
        }
    }
}
