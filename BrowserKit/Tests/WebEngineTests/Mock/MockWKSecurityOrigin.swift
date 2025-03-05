// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
@testable import WebEngine

class MockWKSecurityOrigin: WKSecurityOrigin {
    var overridenProtocol: String!
    var overridenHost: String!
    var overridenPort: Int!

    class func new(_ url: URL?) -> MockWKSecurityOrigin {
        // Dynamically allocate a WKSecurityOriginMock instance because the initializer for WKSecurityOrigin is unavailable
        //  https://github.com/WebKit/WebKit/blob/52222cf447b7215dd9bcddee659884f704001827/Source/WebKit/UIProcess/API/Cocoa/WKSecurityOrigin.h#L40
        guard let instance = self.perform(NSSelectorFromString("alloc"))?.takeUnretainedValue()
                as? MockWKSecurityOrigin
        else {
            fatalError("Could not allocate WKSecurityOriginMock instance")
        }
        instance.overridenProtocol = url?.scheme ?? ""
        instance.overridenHost = url?.host ?? ""
        instance.overridenPort = url?.port ?? 0
        return instance
    }

    override var `protocol`: String { overridenProtocol }
    override var host: String { overridenHost }
    override var port: Int { overridenPort }
}
