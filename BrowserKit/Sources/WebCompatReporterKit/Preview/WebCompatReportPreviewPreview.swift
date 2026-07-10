// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if DEBUG
import Common
import SwiftUI

@available(iOS 17.0, *)
#Preview("With screenshot") {
    WebCompatReportPreviewPreviewController(showsScreenshot: true)
}

@available(iOS 17.0, *)
#Preview("Without screenshot") {
    WebCompatReportPreviewPreviewController(showsScreenshot: false)
}

@available(iOS 17.0, *)
#Preview("Screenshot viewer") {
    WebCompatScreenshotZoomViewController(
        image: webCompatPreviewSampleScreenshot(),
        closeAccessibilityLabel: "Close",
        theme: LightTheme()
    ) {}
}
#endif
