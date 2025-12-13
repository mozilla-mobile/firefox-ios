// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

/// Represents the source of an extension telemetry event
enum ExtensionSource: String {
    case actionExtension = "action-extension"
    case shareExtension = "share-extension"
}

/// Represents the option selected in the Share Extension
enum ShareExtensionOption: String {
    case openInFirefox = "open_in_firefox"
    case loadInBackground = "load_in_background"
    case bookmarkThisPage = "bookmark_this_page"
    case addToReadingList = "add_to_reading_list"
    case sendToDevice = "send_to_device"
}

/// Telemetry for the "Open in Firefox" extension, supporting both Action Extension and Share Extension
struct ShareExtensionTelemetry {
    private let gleanWrapper: GleanWrapper
    private let extensionSource: ExtensionSource

    /// Initializes ShareExtensionTelemetry with a specific extension source
    /// - Parameters:
    ///   - extensionSource: The source of the extension event
    ///   - gleanWrapper: The Glean wrapper for recording events
    init(
        extensionSource: ExtensionSource,
        gleanWrapper: GleanWrapper = DefaultGleanWrapper()
    ) {
        self.extensionSource = extensionSource
        self.gleanWrapper = gleanWrapper
    }

    /// Records when a user shares a URL from the extension
    func shareURL() {
        let extra = GleanMetrics.ShareOpenInFirefoxExtensionList.OptionSelectedExtra(
            extensionSource: extensionSource.rawValue,
            option: ShareExtensionOption.openInFirefox.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.ShareOpenInFirefoxExtensionList.optionSelected, extras: extra)
    }

    /// Records when a user shares text from the extension
    func shareText() {
        let extra = GleanMetrics.ShareOpenInFirefoxExtensionList.OptionSelectedExtra(
            extensionSource: extensionSource.rawValue,
            option: ShareExtensionOption.openInFirefox.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.ShareOpenInFirefoxExtensionList.optionSelected, extras: extra)
    }

    /// Records when a user loads a page in the background from the Share Extension
    func loadInBackground() {
        let extra = GleanMetrics.ShareOpenInFirefoxExtensionList.OptionSelectedExtra(
            extensionSource: extensionSource.rawValue,
            option: ShareExtensionOption.loadInBackground.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.ShareOpenInFirefoxExtensionList.optionSelected, extras: extra)
    }

    /// Records when a user bookmarks a page from the Share Extension
    func bookmarkThisPage() {
        let extra = GleanMetrics.ShareOpenInFirefoxExtensionList.OptionSelectedExtra(
            extensionSource: extensionSource.rawValue,
            option: ShareExtensionOption.bookmarkThisPage.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.ShareOpenInFirefoxExtensionList.optionSelected, extras: extra)
    }

    /// Records when a user adds a page to the reading list from the Share Extension
    func addToReadingList() {
        let extra = GleanMetrics.ShareOpenInFirefoxExtensionList.OptionSelectedExtra(
            extensionSource: extensionSource.rawValue,
            option: ShareExtensionOption.addToReadingList.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.ShareOpenInFirefoxExtensionList.optionSelected, extras: extra)
    }

    /// Records when a user sends a tab to another device from the Share Extension
    func sendToDevice() {
        let extra = GleanMetrics.ShareOpenInFirefoxExtensionList.OptionSelectedExtra(
            extensionSource: extensionSource.rawValue,
            option: ShareExtensionOption.sendToDevice.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.ShareOpenInFirefoxExtensionList.optionSelected, extras: extra)
    }
}
