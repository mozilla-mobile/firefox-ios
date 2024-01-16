// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum BrowserError: Error {
    case dataTaskError(String)
    case jsonSerialization(String)
    case emptyResponse
    case suggestionsNotAvailable
    case webviewNavigation(String)

    var message: String {
        switch self {
        case .dataTaskError(let error):
            return "DataTask error: \(error)"
        case .jsonSerialization(let error):
            return "JSONSerialization error: \(error)"
        case .emptyResponse:
            return "Empty response error"
        case .suggestionsNotAvailable:
            return "Search information is not available"
        case .webviewNavigation(let error):
            return "Webview fail loading page \(error)"
        }
    }
}
