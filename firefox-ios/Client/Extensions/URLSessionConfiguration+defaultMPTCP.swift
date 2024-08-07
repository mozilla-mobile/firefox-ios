// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension URLSessionConfiguration{
    static var defaultMPTCP: URLSessionConfiguration{
        var conf = Self.default
        #if os(iOS)
            // multipath is only available on iOS, enable it only in this case
            conf.multipathServiceType = .handover
        #endif
        // if we aren't building for iOS, defaultMPTCP == default, thus fall back to TCP
        return conf
    }
    
    static var ephemeralMPTCP: URLSessionConfiguration{
        var conf = Self.ephemeral
        #if os(iOS)
            // multipath is only available on iOS, enable it only in this case
            conf.multipathServiceType = .handover
        #endif
        // if we aren't building for iOS, defaultMPTCP == default, thus fall back to TCP
        return conf
    }
}
