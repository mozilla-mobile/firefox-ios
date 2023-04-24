// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct ScreenShotData {
    var pdfData: Data
    var rect: CGRect
}

protocol ScreenShotAbleView: UIViewController {
    func getScreenshotData() -> ScreenShotData?
}

class ScreenShotService: NSObject, UIScreenshotServiceDelegate {
    var screenshotAbleView: ScreenShotAbleView?

    func screenshotService(
        _ screenshotService: UIScreenshotService,
        generatePDFRepresentationWithCompletion completionHandler: @escaping (Data?, Int, CGRect) -> Void
    ) {

        guard let screenShotAbleView = screenshotAbleView,
              screenShotAbleView.presentedViewController == nil,
              let screenshotData = screenShotAbleView.getScreenshotData() else {
            completionHandler(nil, 0, .zero)
            return
        }

        completionHandler(screenshotData.pdfData, 0, screenshotData.rect)
    }
}
