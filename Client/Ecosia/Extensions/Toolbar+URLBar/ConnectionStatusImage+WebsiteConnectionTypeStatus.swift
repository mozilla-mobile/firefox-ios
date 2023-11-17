// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

extension ConnectionStatusImage {
    
    /// Retrieves the image with its appriate `tintColor` based on the website scheme (e.g. http or https)
    static func getForStatus(status: WebsiteConnectionTypeStatus) -> UIImage? {
        switch status {
        case .secure:
            return ConnectionStatusImage.connectionSecureImage
        case .unsecure:
            return ConnectionStatusImage.connectionUnsecureImage
        }
    }
}
