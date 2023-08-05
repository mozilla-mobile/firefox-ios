// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebKit
import Common
import Storage

struct CreditCardPayload: Codable {
    let ccNumber: String
    let ccExpMonth: String
    let ccExpYear: String
    let ccName: String

    enum CodingKeys: String, CodingKey, CaseIterable {
        case ccNumber = "cc-number"
        case ccExpMonth = "cc-exp-month"
        case ccExpYear = "cc-exp-year"
        case ccName = "cc-name"
    }
}

struct FillCreditCardForm: Codable {
    let creditCardPayload: CreditCardPayload
    let type: String

    enum CodingKeys: String, CodingKey, CaseIterable {
        case creditCardPayload = "payload"
        case type = "type"
    }
}

enum CreditCardHelperError: Error {
    case injectionIssue
    case injectionInvalidFields
    case injectionInvalidJSON
}

enum CreditCardPayloadType: String {
    case formSubmit = "capture-credit-card-form"
    case formInput = "fill-credit-card-form"
}

class CreditCardHelper: TabContentScript {
    private weak var tab: Tab?
    private var logger: Logger = DefaultLogger.shared
    private var frame: WKFrameInfo?

    // Closure to send the field values
    var foundFieldValues: ((UnencryptedCreditCardFields,
                            CreditCardPayloadType?,
                            WKFrameInfo?) -> Void)?

    class func name() -> String {
        return "CreditCardHelper"
    }

    required init(tab: Tab) {
        self.tab = tab
    }

    func scriptMessageHandlerName() -> String? {
        return "creditCardMessageHandler"
    }

    func prepareForDeinit() {
        foundFieldValues = nil
    }

    // MARK: Retrieval

    func userContentController(_ userContentController: WKUserContentController,
                               didReceiveScriptMessage message: WKScriptMessage) {
        // Note: We require frame so that we can submit information
        // to embedded iframe on a webpage for injecting card info
        frame = message.frameInfo

        guard let data = getValidPayloadData(from: message),
              let fieldValues = parseFieldType(messageBody: data),
              let payloadType = CreditCardPayloadType(rawValue: fieldValues.type)
        else {
            logger.log("Unable to find the payloadType for credit card js input",
                       level: .warning,
                       category: .webview)
            return
        }
        let payloadData = fieldValues.creditCardPayload
        foundFieldValues?(getFieldTypeValues(payload: payloadData), payloadType, frame)
    }

    func getValidPayloadData(from message: WKScriptMessage) -> [String: Any]? {
        return message.body as? [String: Any]
    }

    func parseFieldType(messageBody: [String: Any]) -> FillCreditCardForm? {
        let decoder = JSONDecoder()

        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: messageBody, options: .prettyPrinted)
            let fillCreditCardForm = try decoder.decode(FillCreditCardForm.self,
                                                        from: jsonData)
            return fillCreditCardForm
        } catch let error {
            logger.log("Unable to parse field type for CC, \(error)",
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

    // MARK: Injection

    static func injectCardInfo(logger: Logger,
                               card: UnencryptedCreditCardFields,
                               tab: Tab,
                               frame: WKFrameInfo? = nil,
                               completion: @escaping (Error?) -> Void) {
        guard !card.ccNumber.isEmpty,
              card.ccExpYear > 0,
              !card.ccName.isEmpty
        else {
            completion(CreditCardHelperError.injectionInvalidFields)
            return
        }

        do {
            let jsonBuilder = CreditCardHelper.injectionJSONBuilder(card: card)
            let jsonData = try JSONSerialization.data(withJSONObject: jsonBuilder)
            guard let jsonDataVal = String(data: jsonData, encoding: .utf8) else {
                completion(CreditCardHelperError.injectionInvalidJSON)
                return
            }

            guard let webView = tab.webView else {
                completion(CreditCardHelperError.injectionIssue)
                return
            }

            let fillCreditCardInfoCallback = "__firefox__.CreditCardHelper.fillFormFields(\(jsonDataVal))"
            webView.evaluateJavascriptInDefaultContentWorld(fillCreditCardInfoCallback, frame) { _, error in
                guard let error = error else {
                    TelemetryWrapper.recordEvent(category: .action,
                                                 method: .tap,
                                                 object: .creditCardAutofilled)
                    completion(nil)
                    return
                }
                TelemetryWrapper.recordEvent(category: .action,
                                             method: .tap,
                                             object: .creditCardAutofillFailed)
                completion(error)
                logger.log("Credit card script error \(error)",
                           level: .debug,
                           category: .webview)
            }
        } catch let error as NSError {
            logger.log("Credit card script error \(error)",
                       level: .debug,
                       category: .webview)
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

    // MARK: Next & Previous focus fields

    static func focusNextInputField(tabWebView: WKWebView,
                                    logger: Logger) {
        let fxWindowValExtras = "window.__firefox__.CreditCardExtras"
        let fillCreditCardInfoCallback = "\(fxWindowValExtras).focusNextInputField()"

        tabWebView.evaluateJavascriptInDefaultContentWorld(fillCreditCardInfoCallback) { _, error in
            guard let error = error else { return }
            logger.log("Unable to go next field: \(error)",
                       level: .debug,
                       category: .webview)
        }
    }

    static func focusPreviousInputField(tabWebView: WKWebView,
                                        logger: Logger) {
        let fxWindowValExtras = "window.__firefox__.CreditCardExtras"
        let fillCreditCardInfoCallback = "\(fxWindowValExtras).focusPreviousInputField()"

        tabWebView.evaluateJavascriptInDefaultContentWorld(fillCreditCardInfoCallback) { _, error in
            guard let error = error else { return }
            logger.log("Unable to go previous field: \(error)",
                       level: .debug,
                       category: .webview)
        }
    }

    // Note: document.activeElement.blur() is used to remove the focus from the
    // currently focused element on a web page. When an element is focused,
    // it typically has a visual indication such as a highlighted border or change in appearance.
    // The reason we do it is because after pressing done the focus still remains in WKWebview
    static func blurActiveElement(tabWebView: WKWebView,
                                  logger: Logger) {
        let fillCreditCardInfoCallback = "document.activeElement.blur()"
        tabWebView.evaluateJavascriptInDefaultContentWorld(fillCreditCardInfoCallback) { _, error in
            guard let error = error else { return }
            logger.log("Unable to go previous field: \(error)",
                       level: .debug,
                       category: .webview)
        }
    }
}
