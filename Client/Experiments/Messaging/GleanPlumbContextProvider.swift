// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class GleanPlumbContextProvider {

    /// JEXLs are more accurately evaluated when given certain details about the app on device.
    /// There is a limited amount of context you can give. See:
    /// - https://experimenter.info/mobile-messaging/#list-of-attributes
    /// We should pass as much device context as possible.
    func createAdditionalDeviceContext() -> [String: Any] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-mm-dd"
        let todaysDate = dateFormatter.string(from: Date())

        return ["date_string": todaysDate]
    }
    
}


