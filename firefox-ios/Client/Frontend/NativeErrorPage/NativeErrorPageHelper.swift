// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit
import GCDWebServers
import Shared
import Storage

class NativeErrorPageHelper {
    enum NetworkErrorType {
        case noInternetConnection
    }

    var error: NSError

    var errorDescriptionItem: String {
        return error.localizedDescription
    }

    init(error: NSError) {
        self.error = error
    }

    func parseErrorDetails() -> ErrorPageModel {
        var title = ""
        var description = ""

        switch error.code {
        case Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue):
            title = .NativeErrorPage.NoInternetConnection.TitleLabel
            description = .NativeErrorPage.NoInternetConnection.Description
        default:
            break
        }

        let model = ErrorPageModel(errorTitle: title, errorDescription: description)
        return model
    }
}
