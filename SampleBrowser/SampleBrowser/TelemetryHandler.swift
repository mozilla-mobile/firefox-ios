// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebEngine

final class TelemetryHandler: EngineTelemetryProxy {
    func handleTelemetry(session: EngineSession, event: EngineTelemetryEvent) {
        switch event {
        case .didFailNavigation:
            print("Telemetry event triggered: Did fail navigation")
        case .didFailProvisionalNavigation:
            print("Telemetry event triggered: Did fail provisional navigation")
        case .showErrorPage(let errorCode):
            print("Telemetry event triggered: Show error page. Error code \(errorCode)")
        case .pageLoadStarted:
            print("Telemetry event triggered: Page load started.")
        case .pageLoadFinished:
            print("Telemetry event triggered: Page load finished.")
        case .pageLoadCancelled:
            print("Telemetry event triggered: Page load cancelled.")
        case .trackAdsFoundOnPage(let providerName, _):
            print("Telemetry event triggered: Track ads found on page \(providerName).")
        case .trackAdsClickedOnPage(let providerName):
            print("Telemetry event triggered: Track ads clicked on page \(providerName).")
        }
    }
}
