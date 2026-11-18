// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebKit

/// Persists the Fox Dash best score in prefs and receives new best scores posted by the game.
final class FoxDashBestScoreStore: NSObject, WKScriptMessageHandler {
    static let messageHandlerName = "foxDashBestScore"

    private let prefs: Prefs

    init(prefs: Prefs) {
        self.prefs = prefs
    }

    var bestScore: Int {
        return Int(prefs.longForKey(PrefsKeys.FoxDashBestScore) ?? 0)
    }

    /// Saves `body` when it is a positive integer higher than the stored best score; anything else is ignored.
    func save(_ body: Any) {
        guard let score = body as? Int, score > bestScore else { return }
        prefs.setLong(Int64(score), forKey: PrefsKeys.FoxDashBestScore)
    }

    // MARK: - WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        save(message.body)
    }
}
