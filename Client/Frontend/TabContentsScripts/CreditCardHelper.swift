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

class CreditCardHelper: TabContentScript {
    private weak var tab: Tab?
    private var logger: Logger = DefaultLogger.shared

    // Closure to send the field values
    var foundFieldValues: ((UnencryptedCreditCardFields) -> Void)?

    class func name() -> String {
        return "CreditCardHelper"
    }

    required init(tab: Tab) {
        self.tab = tab
    }

    func scriptMessageHandlerName() -> String? {
        return "creditCardMessageHandler"
    }

    // MARK: Retrieval

    func userContentController(_ userContentController: WKUserContentController,
                               didReceiveScriptMessage message: WKScriptMessage) {
        guard let data = getValidPayloadData(from: message) else { return }
        guard let payload = parseFieldType(messageBody: data)?.creditCardPayload else { return }
        foundFieldValues?(getFieldTypeValues(payload: payload))
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
        } catch {
            logger.log("Unable to parse field type for CC",
                       level: .warning,
                       category: .webview)
        }

        return nil
    }

    func getFieldTypeValues(payload: CreditCardPayload) -> UnencryptedCreditCardFields {
        var ccPlainText = UnencryptedCreditCardFields()

        ccPlainText.ccName = payload.ccName
        ccPlainText.ccExpMonth = Int64(payload.ccExpMonth.filter { $0.isNumber }) ?? 0
        ccPlainText.ccExpYear = Int64(payload.ccExpYear.filter { $0.isNumber }) ?? 0
        ccPlainText.ccNumber = "\(payload.ccNumber.filter { $0.isNumber })"
        return ccPlainText
    }

    // MARK: Injection

    func injectCardInfo(card: UnencryptedCreditCardFields,
                        tab: Tab,
                        completion: @escaping (Error?) -> Void) {
        guard !card.ccNumber.isEmpty,
              card.ccExpYear > 0,
              !card.ccName.isEmpty
        else {
            completion(CreditCardHelperError.injectionInvalidFields)
            return
        }

        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: injectionJSONBuilder(card: card))
            guard let jsonDataVal = String(data: jsonData, encoding: .utf8) else {
                completion(CreditCardHelperError.injectionInvalidJSON)
                return
            }
            let fxWindowVal = "window.__firefox__.CreditCardHelper"
            let fillCreditCardInfoCallback = "\(fxWindowVal).fillFormFields('\(jsonDataVal)')"
            guard let webView = tab.webView else {
                completion(CreditCardHelperError.injectionIssue)
                return
            }
            webView.evaluateJavascriptInDefaultContentWorld(fillCreditCardInfoCallback) { _, err in
                guard let err = err else {
                    completion(nil)
                    return
                }
                completion(err)
                self.logger.log("Credit card script error \(err)",
                                level: .debug,
                                category: .webview)
            }
        } catch let error as NSError {
            logger.log("Credit card script error \(error)",
                       level: .debug,
                       category: .webview)
        }
    }

    private func injectionJSONBuilder(card: UnencryptedCreditCardFields) -> [String: Any] {
        let injectionJSON: [String: Any] = [
                "cc-name": card.ccName,
                "cc-number": card.ccNumber,
                "cc-exp-month": "\(card.ccExpMonth)",
                "cc-exp-year": "\(card.ccExpYear)",
                "cc-exp": "\(card.ccExpMonth)/\(card.ccExpYear)",
        ]

        return injectionJSON
    }

    // MARK: Next & Previous focus fields

    static func focusNextInputField(tabWebView: WKWebView,
                                    logger: Logger = DefaultLogger.shared) {
        let fxWindowValExtras = "window.__firefox__.CreditCardExtras"
        let fillCreditCardInfoCallback = "\(fxWindowValExtras).focusNextInputField()"

        tabWebView.evaluateJavascriptInDefaultContentWorld(fillCreditCardInfoCallback) { _, err in
            guard let err = err else { return }
            logger.log("Unable to go next field: \(err)",
                       level: .debug,
                       category: .webview)
        }
    }

    static func focusPreviousInputField(tabWebView: WKWebView,
                                        logger: Logger = DefaultLogger.shared) {
        let fxWindowValExtras = "window.__firefox__.CreditCardExtras"
        let fillCreditCardInfoCallback = "\(fxWindowValExtras).focusPreviousInputField()"

        tabWebView.evaluateJavascriptInDefaultContentWorld(fillCreditCardInfoCallback) { _, err in
            guard let err = err else { return }
            logger.log("Unable to go next field: \(err)",
                       level: .debug,
                       category: .webview)
        }
    }
}
