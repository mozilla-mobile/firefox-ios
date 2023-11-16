// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common
import MozillaAppServices

@testable import Client

enum JexlError: Error {
    case unknownJexl
}

class MockNimbusTargetingHelper: NimbusTargetingHelperProtocol {
    func evalJexl(expression: String) throws -> Bool {
        switch expression {
        case "true": return true
        case "false": return false
        default: throw JexlError.unknownJexl
        }
    }
}

class MockNimbusStringHelper: NimbusStringHelperProtocol {
    func stringFormat(template: String, uuid: String?) -> String {
        return template
    }

    func getUuid(template: String) -> String? {
        return nil
    }
}

class MockNimbusMessagingHelperUtility: NimbusMessagingHelperUtilityProtocol {
    required init(logger: Logger = DefaultLogger.shared) { }

    func createNimbusMessagingHelper() -> NimbusMessagingHelperProtocol? {
        return NimbusMessagingHelper(
            targetingHelper: MockNimbusTargetingHelper(),
            stringHelper: MockNimbusStringHelper())
    }
}
