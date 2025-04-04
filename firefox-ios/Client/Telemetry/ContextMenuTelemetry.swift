// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct ContextMenuTelemetry {
    enum OptionExtra: String {
        case openInNewTab
        case openInNewPrivateTab
        case bookmarkLink
        case removeBookmark
        case downloadLink
        case copyLink
        case shareLink
        case saveImage
        case copyImage
        case copyImageLink
    }

    enum OriginExtra: String {
        case webLink
        case imageLink
    }

    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func optionSelected(option: OptionExtra, origin: OriginExtra) {
        let optionSelectedExtras = GleanMetrics.ContextMenu.OptionSelectedExtra(
            option: option.rawValue,
            origin: origin.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.ContextMenu.optionSelected, extras: optionSelectedExtras)
    }

    func shown(origin: OriginExtra) {
        let shownExtras = GleanMetrics.ContextMenu.ShownExtra(origin: origin.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.ContextMenu.shown, extras: shownExtras)
    }

    func dismissed(origin: OriginExtra) {
        let dismissedExtras = GleanMetrics.ContextMenu.DismissedExtra(origin: origin.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.ContextMenu.dismissed, extras: dismissedExtras)
    }
}
