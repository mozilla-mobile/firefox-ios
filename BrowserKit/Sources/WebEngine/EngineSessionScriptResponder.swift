// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// The object responsible to respond to events thrown from scripts added to the `EngineSession`
class EngineSessionScriptResponder: ContentScriptDelegate {
    weak var session: EngineSession?

    func contentScriptDidSendEvent(_ event: ScriptEvent) {
        switch event {
        case .trackedAdsFoundOnPage(let provider, let urls):
            session?.telemetryProxy?.handleTelemetry(event: .trackAdsFoundOnPage(providerName: provider, adUrls: urls))
        case .trackedAdsClickedOnPage(let provider):
            session?.telemetryProxy?.handleTelemetry(event: .trackAdsClickedOnPage(providerName: provider))
        default:
            break
        }
    }
}
