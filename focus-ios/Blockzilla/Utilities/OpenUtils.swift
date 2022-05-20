/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Telemetry

class OpenUtils: NSObject {
    private let selectedURL: URL
    private let webViewController: WebViewController

    init(url: URL, webViewController: WebViewController) {
        self.selectedURL = url
        self.webViewController = webViewController
    }

    func buildShareViewController() -> UIActivityViewController {
        var activityItems: [Any] = [selectedURL]

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = selectedURL.absoluteString
        printInfo.outputType = .general
        activityItems.append(printInfo)

        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(webViewController.printFormatter, startingAtPageAt: 0)
        activityItems.append(renderer)

        if let title = webViewController.pageTitle {
            activityItems.append(TitleActivityItemProvider(title: title))
        }

        let shareController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)

        shareController.popoverPresentationController?.permittedArrowDirections = .up
        shareController.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
            if !completed {
                return
            }

            // Bug 1392418 - When copying a url using the share extension there are 2 urls in the pasteboard.
            // Make sure the pasteboard only has one url.
            if let url = UIPasteboard.general.urls?.first {
                UIPasteboard.general.urls = [url]
            }
        }
        return shareController
    }
}
