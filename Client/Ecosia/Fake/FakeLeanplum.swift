/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class Leanplum {
    static func deviceId() -> String? { return nil }
    static func hasStarted() -> Bool { return false }
    static func forceContentUpdate() {}
    static func setUserAttributes(_ attr: [String: Any]) {}
    static func setDeviceId(_ id: String?) {}
    static func setAppId(_ id: String?, withDevelopmentKey: String? = nil, withProductionKey: String? = nil) {}
    static func syncResourcesAsync(_ b: Bool) {}
    static func start(withUserId: String?, userAttributes: [AnyHashable: Any], responseHandler: (String)->()) {}
    static func variants() -> [Dictionary<AnyHashable, AnyObject>]? { return nil }
    static func track(_ e: String, withParameters: [String:Any]? = nil) {}
    static func setTestModeEnabled(_ e: Bool) {}
    static func setUserAttributes(_ a: [AnyHashable: Any]?) {}
    static func defineAction(_ s: String, of: String, withArguments: [LPActionArg], withOptions: [String: Any], withResponder: LeanplumActionBlock) {}
}

class LPActionArg {
    init(named: String, with: Any) {}
    init(named: String, withAction: Any?) {}

}

class LPVar {
    static func define(_ x: String, with: Bool) -> LPVar? { return nil }
    func boolValue() -> Bool { return false }
}
let kLeanplumActionKindMessage = ""
typealias LeanplumActionBlock = ((Any)->(Bool))
