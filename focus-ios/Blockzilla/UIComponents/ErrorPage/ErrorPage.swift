/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class ErrorPage {
    let error: NSError

    init(error: Error) {
        self.error = error as NSError
    }

    var data: Data {
        guard let fileURL = Bundle.main.url(forResource: "errorPage", withExtension: "html"),
              let fileContents = try? String(contentsOf: fileURL) else {
            fatalError("Failed to load 'errorPage.html' from bundle.")
        }
        let page = fileContents.replacingOccurrences(of: "%messageLong%", with: error.localizedDescription)
                                 .replacingOccurrences(of: "%button%", with: UIConstants.strings.errorTryAgain)
        guard let pageData = page.data(using: .utf8) else {
            fatalError("Failed to convert HTML string to Data.")
        }
        return pageData
    }
}
