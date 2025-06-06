// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

/// Protocol representing a single engine session. In browsers usually a session corresponds to a tab.
public protocol EngineSession: NSObject {
    /// Engine session delegate
    var delegate: EngineSessionDelegate? { get set }

    /// Proxy object for handling telemetry events.
    var telemetryProxy: EngineTelemetryProxy? { get set }

    /// Whether the engine session is currently being rendered
    var isActive: Bool { get set }

    /// The engine received a request to load a URL.
    /// - Parameter browserURL: The BrowserURL that is requested to load
    func load(browserURL: BrowserURL)

    /// Stops loading the current session.
    func stopLoading()

    /// Reloads the current URL.
    /// - Parameter bypassCache: Bypass the cache and fully reload from the origin
    func reload(bypassCache: Bool)

    /// Navigates back in the history of this session.
    func goBack()

    /// Navigates forward in the history of this session.
    func goForward()

    /// Scroll the session to the top.
    func scrollToTop()

    /// Show the web view's built-in find interaction.
    /// The find interactions close themselves.
    /// - Parameter searchText: The optional text to search with in the find in page bar.
    @available(iOS 16.0, *)
    func showFindInPage(withSearchText searchText: String?)

    /// Navigates to the specified history item
    /// - Parameter item: EngineSessionBackForwardListItem in the back forward list that
    /// you would like to navigate to.
    func goToHistory(item: EngineSessionBackForwardListItem)

    /// Returns the current EngineSessionBackForwardListItem
    func currentHistoryItem() -> EngineSessionBackForwardListItem?

    /// Returns the history backlist as a list of EngineSessionBackForwardListItems
    func getBackListItems() -> [EngineSessionBackForwardListItem]

    /// Returns the history forwardlist as a list of EngineSessionBackForwardListItems
    func getForwardListItems() -> [EngineSessionBackForwardListItem]

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

public extension EngineSession {
    func reload(bypassCache: Bool = false) {
        reload(bypassCache: bypassCache)
    }

    @available(iOS 16.0, *)
    func showFindInPage(withSearchText searchText: String? = nil) {
        showFindInPage(withSearchText: searchText)
    }
}
