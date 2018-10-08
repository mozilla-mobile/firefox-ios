/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftyJSON
import WebKit

private func jsonFromFile(at url: URL) -> JSON? {
    guard let string = try? NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue) as String else {
        return nil
    }

    let json = JSON(parseJSON: string)
    guard json.count > 0 else {
        return nil
    }

    return json
}

class WebExtensionLocalization {
    let webExtension: WebExtension
    let locales: JSON

    init(webExtension: WebExtension) {
        self.webExtension = webExtension

        let tempDirectoryURL = webExtension.tempDirectoryURL
        let localesDirectoryURL = tempDirectoryURL.appendingPathComponent("_locales")

        var locales: JSON = JSON()

        let directoryURLs = (try? FileManager.default.contentsOfDirectory(at: localesDirectoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        for directoryURL in directoryURLs {
            let locale = directoryURL.lastPathComponent
            let messagesFileURL = directoryURL.appendingPathComponent("messages.json")
            if let messagesJSON = jsonFromFile(at: messagesFileURL) {
                locales[locale] = messagesJSON
            }
        }

        self.locales = locales
    }
}
