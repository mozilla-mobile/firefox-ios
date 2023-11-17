// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// These strings modify the default title, message and button text
/// of the Firefox no connection error page
/// when the error is `NSURLErrorDomain`
/// more info in `ErrorPageHandler`

extension ErrorPageHandler {
    
    var noConnectionErrorTitle: String {
        .localized(.noConnectionNSURLErrorTitle)
    }
    
    var noConnectionErrorMessage: String {
        .localized(.noConnectionNSURLErrorMessage)
    }
    
    var noConnectionErrorButtonTitle: String {
        .localized(.noConnectionNSURLErrorRefresh)
    }
    
}
