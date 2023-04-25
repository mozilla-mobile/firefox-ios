// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct ScreenshotData {
    var pdfData: Data
    var rect: CGRect
}

/// A protocol to get PDF data for the fullscreen screenshot feature
protocol ScreenshotableView: UIViewController {
    func getScreenshotData(completionHandler: @escaping (ScreenshotData?) -> Void)
}

class ScreenshotService: NSObject, UIScreenshotServiceDelegate {
    var screenshotableView: ScreenshotableView?

    func screenshotService(
        _ screenshotService: UIScreenshotService,
        generatePDFRepresentationWithCompletion completionHandler: @escaping (Data?, Int, CGRect) -> Void
    ) {
        guard let screenshotableView = screenshotableView,
              screenshotableView.presentedViewController == nil else {
            completionHandler(nil, 0, .zero)
            return
        }

        screenshotableView.getScreenshotData { screenshotData in
            guard let screenshotData = screenshotData else {
                completionHandler(nil, 0, .zero)
                return
            }

            completionHandler(screenshotData.pdfData, 0, screenshotData.rect)
        }
    }
}
