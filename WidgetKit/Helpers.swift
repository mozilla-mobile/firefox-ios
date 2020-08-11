/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

var scheme: String {
    guard let string = Bundle.main.object(forInfoDictionaryKey: "MozInternalURLScheme") as? String else {
        return "firefox"
    }
    return string
}

func linkToContainingApp(_ urlSuffix: String = "", query: String) -> URL {
    let urlString = "\(scheme)://\(query)\(urlSuffix)"
    return URL(string: urlString)!
}
