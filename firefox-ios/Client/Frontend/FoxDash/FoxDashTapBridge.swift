// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

/// Lets the app take over taps while a Fox Dash round runs, since a tap handled by WebKit
/// holds back the game's next frame. The game reports when a round starts and stops,
/// and the app forwards each tap back to it.
final class FoxDashTapBridge: NSObject, WKScriptMessageHandler {
    static let messageHandlerName = "foxDashPlaying"

    var onPlayingChange: ((Bool) -> Void)?

    func receive(_ body: Any) {
        guard let isPlaying = body as? Bool else { return }
        onPlayingChange?(isPlaying)
    }

    func tapScript(at point: CGPoint) -> String {
        return "window.foxDashTap?.(\(point.x), \(point.y))"
    }

    // MARK: - WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        receive(message.body)
    }
}
