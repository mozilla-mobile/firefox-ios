// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct ShareExtensionTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func shareURL(extensionSource: String = "action-extension") {
        let extra = GleanMetrics.ShareOpenInFirefoxExtension.UrlSharedExtra(extensionSource: extensionSource)
        gleanWrapper.recordEvent(for: GleanMetrics.ShareOpenInFirefoxExtension.urlShared, extras: extra)
    }

    func shareText(extensionSource: String = "action-extension") {
        let extra = GleanMetrics.ShareOpenInFirefoxExtension.TextSharedExtra(extensionSource: extensionSource)
        gleanWrapper.recordEvent(for: GleanMetrics.ShareOpenInFirefoxExtension.textShared, extras: extra)
    }
}
