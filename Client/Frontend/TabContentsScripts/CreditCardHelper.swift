// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebKit
import Common
import Storage

enum ValidFieldType: String, CaseIterable {
    case ccNumber = "cc-number"
    case ccExpMonth = "cc-exp-month"
    case ccExpYear = "cc-exp-year"
    case ccName = "cc-name"
}

struct Payload: Codable {
    let id: Int
    let fieldTypes: [FieldType]
}

struct FieldType: Codable {
    let type: String
    let value: String
}

struct FillCreditCardForm: Codable {
    let payload: Payload
    let type: String
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

    private var requestID: Int = -1

    // MARK: Retrieval
    func userContentController(_ userContentController: WKUserContentController,
                               didReceiveScriptMessage message: WKScriptMessage) {
        guard let data = message.body as? [String: Any] else { return }
        guard let payload = parseFieldType(messageBody: data)?.payload else { return }
        guard !payload.fieldTypes.isEmpty else { return }
        requestID = payload.id
        var fieldTypes = payload.fieldTypes
        let fieldTypeValues = getFieldTypeValues(fieldTypes: fieldTypes)
        foundFieldValues?(fieldTypeValues)
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

    func getFieldTypeValues(fieldTypes: [FieldType]) -> UnencryptedCreditCardFields {
        var ccPlainText = UnencryptedCreditCardFields()
        fieldTypes.forEach { field in
            if let fieldType = ValidFieldType(rawValue: field.type) {
                switch fieldType {
                case .ccName:
                    ccPlainText.ccName = field.value
                case .ccExpMonth:
                    let val = field.value.filter { $0.isNumber }
                    ccPlainText.ccExpMonth = Int64(val) ?? 0
                case .ccExpYear:
                    let val = field.value.filter { $0.isNumber }
                    ccPlainText.ccExpYear = Int64(val) ?? 0
                case .ccNumber:
                    let val = field.value.filter { $0.isNumber }
                    ccPlainText.ccNumber = "\(val)"
                }
            }
        }
        return ccPlainText
    }

    // MARK: Injection
    func injectCardInfo(card: UnencryptedCreditCardFields,
                        tab: Tab) -> Bool {
        guard !card.ccNumber.isEmpty, card.ccExpYear > 0, !card.ccName.isEmpty else {
            return false
        }

        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: injectionJSONBuilder(card: card, reqID: requestID))
            guard let jsonDataVal = String(data: jsonData, encoding: .utf8) else {
                return false
            }
            let fxWindowVal = "window.__firefox__.CreditCardHelper"
            let fillCreditCardInfoCallback = "\(fxWindowVal).fillCreditCardInfo('\(jsonDataVal)')"
            guard let webView = tab.webView else {
                return false
            }
            webView.evaluateJavascriptInDefaultContentWorld(fillCreditCardInfoCallback) { _, err in
                guard let err = err else {
                    return
                }
                self.logger.log("Credit card script error \(err)",
                                level: .debug,
                                category: .webview)
            }
        } catch let error as NSError {
            logger.log("Credit card script error \(error)",
                       level: .debug,
                       category: .webview)
        }

        return true
    }

    private func injectionJSONBuilder(card: UnencryptedCreditCardFields,
                                      reqID: Int) -> [String: Any] {
        let injectionJSON: [String: Any] = [
             "data": [
                "cc-name": card.ccName,
                "cc-number": card.ccNumber,
                "cc-exp-month": "\(card.ccExpMonth)",
                "cc-exp-year": "\(card.ccExpYear)",
                "cc-exp": "\(card.ccExpMonth)/\(card.ccExpYear)",
               ],
             "id": reqID,
        ]

        return injectionJSON
    }
}
