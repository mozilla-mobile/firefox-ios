// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

/// Telemetry for the "Open in Firefox" extension, supporting both Action Extension and Share Extension
struct ShareExtensionTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    /// Records when a user shares a URL from the extension
    /// - Parameter extensionSource: The source of the extension event. Defaults to "action-extension".
    ///   Use "share-extension" for legacy Share Extension events.
    func shareURL(extensionSource: String = "action-extension") {
        let extra = GleanMetrics.ShareOpenInFirefoxExtension.UrlSharedExtra(extensionSource: extensionSource)
        gleanWrapper.recordEvent(for: GleanMetrics.ShareOpenInFirefoxExtension.urlShared, extras: extra)
    }

    /// Records when a user shares text from the extension
    /// - Parameter extensionSource: The source of the extension event. Defaults to "action-extension".
    ///   Use "share-extension" for legacy Share Extension events.
    func shareText(extensionSource: String = "action-extension") {
        let extra = GleanMetrics.ShareOpenInFirefoxExtension.TextSharedExtra(extensionSource: extensionSource)
        gleanWrapper.recordEvent(for: GleanMetrics.ShareOpenInFirefoxExtension.textShared, extras: extra)
    }

    /// Records when a user loads a page in the background from the Share Extension
    func loadInBackground() {
        gleanWrapper.recordEvent(for: GleanMetrics.ShareOpenInFirefoxExtension.loadInBackground)
    }

    /// Records when a user bookmarks a page from the Share Extension
    func bookmarkThisPage() {
        gleanWrapper.recordEvent(for: GleanMetrics.ShareOpenInFirefoxExtension.bookmarkThisPage)
    }

    /// Records when a user adds a page to the reading list from the Share Extension
    func addToReadingList() {
        gleanWrapper.recordEvent(for: GleanMetrics.ShareOpenInFirefoxExtension.addToReadingList)
    }

    /// Records when a user sends a tab to another device from the Share Extension
    func sendToDevice() {
        gleanWrapper.recordEvent(for: GleanMetrics.ShareOpenInFirefoxExtension.sendToDevice)
    }
}
