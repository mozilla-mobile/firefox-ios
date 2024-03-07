// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Protocol representing a single engine session. In browsers usually a session corresponds to a tab.
public protocol EngineSession {
    /// Engine session delegate
    var delegate: EngineSessionDelegate? { get set }

    /// Proxy object for handling telemetry events.
    var telemetryProxy: EngineTelemetryProxy? { get set }

    /// Find in page delegate.
    var findInPageDelegate: FindInPageHelperDelegate? { get set }

    /// The engine received a request to load a URL.
    /// - Parameter url: The URL string that is requested
    func load(url: String)

    /// Stops loading the current session.
    func stopLoading()

    /// Reloads the current URL.
    func reload()

    /// Navigates back in the history of this session.
    func goBack()

    /// Navigates forward in the history of this session.
    func goForward()

    /// Scroll the session to the top.
    func scrollToTop()

    /// Find a text selection in this session.
    /// - Parameters:
    ///   - text: The text to search
    ///   - function: The functionality the find in page should search with
    func findInPage(text: String, function: FindInPageFunction)

    /// Called whenever the find in page session should be ended.
    func findInPageDone()

    /// Navigates to the specified index in the history of this session. The current index of
    /// this session's history  will be updated but the items within it will be unchanged.
    /// Invalid index values are ignored.
    /// - Parameter index: index the index of the session's history to navigate to
    func goToHistory(index: Int)

    /// Restore a saved state; only data that is saved (history, scroll position, zoom, and form data)
    /// will be restored.
    /// - Parameter state: A saved session state.
    func restore(state: Data)

    /// Close the session. This may free underlying objects. Call this when you are finished using this session.
    func close()

    /// Switch to standard tracking protection mode.
    func switchToStandardTrackingProtection()

    /// Switch to strict tracking protection mode.
    func switchToStrictTrackingProtection()

    /// Disable all tracking protection.
    func disableTrackingProtection()

    /// Toggle image blocking mode.
    func toggleNoImageMode()

    /// Change the page zoom scale.
    func updatePageZoom(_ change: ZoomChangeValue)
}
