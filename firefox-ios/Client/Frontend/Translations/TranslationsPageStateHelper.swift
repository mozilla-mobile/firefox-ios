// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import WebKit

/// `pageshow` is the earliest point at which a document can be asked whether it is translated.
class TranslationsPageStateHelper: TabContentScript {
    private weak var tab: Tab?

    class func name() -> String { return "TranslationsPageStateHelper" }

    required init(tab: Tab) {
        self.tab = tab
    }

    func scriptMessageHandlerNames() -> [String]? { return ["translationsPageState"] }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceiveScriptMessage message: WKScriptMessage
    ) {
        guard let tab,
              let body = message.body as? [String: Any] else { return }

        store.dispatch(TranslationsPageStateAction(
            windowUUID: tab.windowUUID,
            pageState: Self.pageState(from: body),
            tabUUID: tab.tabUUID,
            actionType: TranslationsActionType.pageDidReportTranslationState
        ))
    }

    static func pageState(from body: [String: Any]) -> PageTranslationState {
        guard body["translated"] as? Bool == true,
              let from = body["from"] as? String,
              let to = body["to"] as? String,
              !from.isEmpty,
              !to.isEmpty
        else { return .notTranslated }

        return .translated(from: from, to: to)
    }
}
