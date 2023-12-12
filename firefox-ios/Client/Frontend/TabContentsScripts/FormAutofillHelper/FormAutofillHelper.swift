// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebKit
import Common
import Storage

class FormAutofillHelper: TabContentScript {
    // MARK: - Properties

    private weak var tab: Tab?
    private var logger: Logger = DefaultLogger.shared
    private var frame: WKFrameInfo?

    // Closure to send the field values
    var foundFieldValues: ((UnencryptedCreditCardFields,
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
        return ["addressFormMessageHandler", "creditCardFormMessageHandler"]
    }

    // MARK: - Deinitialization

    func prepareForDeinit() {
        foundFieldValues = nil
    }

    // MARK: - Retrieval

    func userContentController(_ userContentController: WKUserContentController,
                               didReceiveScriptMessage message: WKScriptMessage) {
        // Note: We require frame so that we can submit information
        // to an embedded iframe on a webpage for injecting card info
        frame = message.frameInfo

        guard let data = getValidPayloadData(from: message),
              let fieldValues = parseFieldType(messageBody: data),
              let payloadType = FormAutofillPayloadType(rawValue: fieldValues.type)
        else {
            logger.log("Unable to find the payloadType for the credit card JS input",
                       level: .warning,
                       category: .webview)
            return
        }

        let payloadData = fieldValues.creditCardPayload
        foundFieldValues?(getFieldTypeValues(payload: payloadData), payloadType, frame)
    }

    // MARK: - Payload Data Handling

    func getValidPayloadData(from message: WKScriptMessage) -> [String: Any]? {
        return message.body as? [String: Any]
    }

    func parseFieldType(messageBody: [String: Any]) -> FillCreditCardForm? {
        let decoder = JSONDecoder()

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messageBody, options: .prettyPrinted)
            let fillCreditCardForm = try decoder.decode(FillCreditCardForm.self, from: jsonData)
            return fillCreditCardForm
        } catch let error {
            logger.log("Unable to parse field type for the credit card, \(error)",
                       level: .warning,
                       category: .webview)
        }

        return nil
    }

    func getFieldTypeValues(payload: CreditCardPayload) -> UnencryptedCreditCardFields {
        var ccPlainText = UnencryptedCreditCardFields()
        let creditCardValidator = CreditCardValidator()

        ccPlainText.ccName = payload.ccName
        ccPlainText.ccExpMonth = Int64(payload.ccExpMonth.filter { $0.isNumber }) ?? 0
        ccPlainText.ccExpYear = Int64(payload.ccExpYear.filter { $0.isNumber }) ?? 0
        ccPlainText.ccNumber = "\(payload.ccNumber.filter { $0.isNumber })"
        ccPlainText.ccNumberLast4 = ccPlainText.ccNumber.count > 4 ? String(ccPlainText.ccNumber.suffix(4)) : ""
        ccPlainText.ccType = creditCardValidator.cardTypeFor(ccPlainText.ccNumber)?.rawValue ?? ""
        return ccPlainText
    }

    // MARK: - Injection

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

    static func injectionJSONBuilder(card: UnencryptedCreditCardFields) -> [String: Any] {
        let sanitizedName = card.ccName.htmlEntityEncodedString
        let sanitizedNumber = card.ccNumber.htmlEntityEncodedString
        let injectionJSON: [String: Any] = [
                "cc-name": sanitizedName,
                "cc-number": sanitizedNumber,
                "cc-exp-month": "\(card.ccExpMonth)",
                "cc-exp-year": "\(card.ccExpYear)",
                "cc-exp": "\(card.ccExpMonth)/\(card.ccExpYear)",
        ]
        return injectionJSON
    }

    // MARK: - Focus Management

    static func focusNextInputField(tabWebView: WKWebView, logger: Logger) {
        let fxWindowValExtras = "window.__firefox__.FormAutofillExtras"
        let fillCreditCardInfoCallback = "\(fxWindowValExtras).focusNextInputField()"

        tabWebView.evaluateJavascriptInDefaultContentWorld(fillCreditCardInfoCallback) { _, error in
            if let error = error {
                logger.log("Unable to go to the next field: \(error)", level: .debug, category: .webview)
            }
        }
    }

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
    static func blurActiveElement(tabWebView: WKWebView, logger: Logger) {
        let fillCreditCardInfoCallback = "document.activeElement.blur()"
        tabWebView.evaluateJavascriptInDefaultContentWorld(fillCreditCardInfoCallback) { _, error in
            if let error = error {
                logger.log("Unable to remove focus from the current field: \(error)", level: .debug, category: .webview)
            }
        }
    }
}
