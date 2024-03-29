// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Defines events which are engine-agnostic but typically applicable to all WebEngine
/// clients, such as web view navigation failures and error page events.
public enum EngineTelemetryEvent {
    // Navigation failed.
    case didFailNavigation

    // Provisional navigation failed.
    case didFailProvisionalNavigation

    // An error page was shown on the page. Includes error code.
    case showErrorPage(errorCode: Int)

    // A page load started.
    case pageLoadStarted

    // A page load was cancelled.
    case pageLoadCancelled

    // A page load was completed.
    case pageLoadFinished

    /// Sends an event for ads found on the page. Includes the provider name and ad URLs.
    case trackAdsFoundOnPage(providerName: String, adUrls: [String])

    /// Sends an event for ads clicked on the page. Includes the provider name.
    case trackAdsClickedOnPage(providerName: String)
}

/// Protocol for handling WebEngine telemetry events. These can be custom-handled
/// by clients to be recorded through Glean or any other preferred API.
public protocol EngineTelemetryProxy: AnyObject {
    func handleTelemetry(session: EngineSession, event: EngineTelemetryEvent)
}
