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
        var foxImageName = ""

        switch error.code {
        case Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue):
            foxImageName = ImageIdentifiers.NativeErrorPage.noInternetConnection
            title = .NativeErrorPage.NoInternetConnection.TitleLabel
            description = .NativeErrorPage.NoInternetConnection.Description
        default:
            foxImageName = ImageIdentifiers.NativeErrorPage.noInternetConnection
            title = .NativeErrorPage.GenericError.TitleLabel
            description = .NativeErrorPage.GenericError.Description
        }

        let model = ErrorPageModel(errorTitle: title, errorDescription: description, foxImageName: foxImageName)
        return model
    }
}
