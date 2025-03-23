// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Delegate to handle fullscreen state changes for a `WKWebView`.
///
/// According to Apple’s documentation, when a webpage requests fullscreen mode,
/// the system removes the `WKWebView` from the app’s view hierarchy. See:
/// [WKPreferences.isElementFullscreenEnabled](https://developer.apple.com/documentation/webkit/wkpreferences/iselementfullscreenenabled)
///
/// Due to limited documentation on this behavior, the following methods handle
/// fullscreen transitions based on trial and error.
public protocol FullscreenDelegate: AnyObject {
    /// Called when the web view enters fullscreen mode.
    ///
    /// When `WKWebView` is removed from the view hierarchy, two updates must be made
    /// to restore proper rendering:
    /// 1. Set `translatesAutoresizingMaskIntoConstraints = true`
    /// 2. Set a flexible `autoresizingMask`
    ///
    /// These adjustments ensure the web page is displayed correctly.
    func enteringFullscreen()

    /// Called when the web view exits fullscreen mode.
    ///
    /// The `WKWebView` must be re-added to the app’s view hierarchy to restore normal behavior.
    func exitingFullscreen()
}
