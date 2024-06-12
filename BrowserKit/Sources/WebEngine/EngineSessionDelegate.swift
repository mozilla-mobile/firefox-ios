// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit.UIContextMenuConfiguration

/// Delegate used by the class that want to observe an engine session
public protocol EngineSessionDelegate: AnyObject {
    /// Event to indicate the title on the session has changed.
    func onTitleChange(title: String)

    /// Event to indicate the URL on the session has changed.
    func onLocationChange(url: String)

    /// Event to indicate whether the page loaded all resources through encrypted connections.
    func onHasOnlySecureContentChanged(secure: Bool)

    /// Event to indicate the loading progress has been updated.
    func onProgress(progress: Double)

    /// Event to indicate there has been a navigation change.
    func onNavigationStateChange(canGoBack: Bool, canGoForward: Bool)

    /// Event to indicate the loading state has changed
    func onLoadingStateChange(loading: Bool)

    /// Event to indicate that the page metadata was loaded or updated
    func didLoad(pageMetadata: EnginePageMetadata)

    // MARK: Menu items
    /// Relates to adding native `UIMenuController.shared.menuItems` in webview textfields

    /// Event to indicate a webview text field menu item was selected to start a find in page action
    func findInPage(with selection: String)

    /// Event to indicate a webview text field menu item was selected to start a search action
    func search(with selection: String)

    /// Event to indicate that a contextual menu has been requested for the given URL (typically
    /// as a result of the user long-pressing on link).
    /// - Parameter linkURL: the link (if any) associated with the event.
    /// - Returns: a menu configuration, or nil (will not show a menu)
    func onProvideContextualMenu(linkURL: URL?) -> UIContextMenuConfiguration?

    /// Allows delegates to participate in whether or not a keyboard accessory view is shown
    /// for the current engine session.
    func onWillDisplayAccessoryView() -> EngineInputAccessoryView

    /// Allows delegates to provide custom definitions for ads tracking, for ads found on webpages.
    /// This is utilized in conjunction with the related ads telemetry events (e.g. `.trackAdsFoundOnPage`
    /// which are also passed along to telemetry proxy (`EngineTelemetryProxy`).
    func adsSearchProviderModels() -> [EngineSearchProviderModel]
}
