// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

@testable import WebEngine

class MockEngineSession: NSObject, EngineSession {
    var viewPrintFormatterCalled = 0

    var delegate: EngineSessionDelegate?
    var telemetryProxy: EngineTelemetryProxy?
    var isActive = false

    func load(browserURL: WebEngine.BrowserURL) { }

    func stopLoading() { }

    func goBack() { }

    func goForward() { }

    func scrollToTop() { }

    func goToHistory(item: any WebEngine.EngineSessionBackForwardListItem) { }

    func currentHistoryItem() -> (EngineSessionBackForwardListItem)? { return nil }

    func getBackListItems() -> [EngineSessionBackForwardListItem] { return [] }

    func getForwardListItems() -> [EngineSessionBackForwardListItem] { return [] }

    func restore(state: Data) { }

    func close() { }

    func switchToStandardTrackingProtection() { }

    func switchToStrictTrackingProtection() { }

    func disableTrackingProtection() { }

    func toggleNoImageMode() { }

    func updatePageZoom(_ change: WebEngine.ZoomChangeValue) { }

    func viewPrintFormatter() -> UIPrintFormatter {
        viewPrintFormatterCalled += 1
        return UIPrintFormatter()
    }
}
