// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import QuickLook

class OpenQLPreviewHelper: NSObject, QLPreviewControllerDataSource {
    private var previewItem = NSURL()
    private let presenter: Presenter
    private let previewController: QLPreviewController

    init(presenter: Presenter) {
        self.presenter = presenter
        self.previewController = QLPreviewController()
        super.init()
    }

    static func shouldOpenPreviewHelper(response: URLResponse,
                                        forceDownload: Bool) -> Bool {
        guard let mimeType = response.mimeType else { return false }

        return (mimeType == MIMEType.USDZ || mimeType == MIMEType.Reality) && !forceDownload
    }

    func canOpen(url: URL?) -> Bool {
        guard let url = url as? NSURL else {
            return false
        }

        previewItem = url
        return QLPreviewController.canPreview(url)
    }

    func open() {
        previewController.dataSource = self
        ensureMainThread {
            self.presenter.present(self.previewController,
                                   animated: true,
                                   completion: nil)
        }
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController,
                           previewItemAt index: Int) -> QLPreviewItem {
        return previewItem
    }
}
