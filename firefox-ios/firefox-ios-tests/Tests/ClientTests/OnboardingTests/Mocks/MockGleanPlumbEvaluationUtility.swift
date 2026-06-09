// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import MozillaAppServices

@testable import Client

enum JexlError: Error {
    case unknownJexl
}

final class MockNimbusTargetingHelper: NimbusTargetingHelperProtocol, @unchecked Sendable {
    func evalJexl(expression: String) throws -> Bool {
        switch expression {
        case "true": return true
        case "false": return false
        default: throw JexlError.unknownJexl
        }
    }

    func evalJexlDebug(expression: String) throws -> String {
        switch expression {
        case "true":
            return """
            {"success": true, "result": true}
            """
        case "false":
            return """
            {"success": true, "result": false}
            """
        default:
            return """
            {"success": false, "error": "Unknown JEXL expression"}
            """
        }
    }
}

final class MockNimbusStringHelper: NimbusStringHelperProtocol, @unchecked Sendable {
    func stringFormat(template: String, uuid: String?) -> String {
        if let uuid = uuid {
            return template.replacingOccurrences(of: "{uuid}", with: uuid)
        } else {
            return template
        }
    }

    func getUuid(template: String) -> String? {
        if template.contains("{uuid}") {
            return "MY-UUID"
        } else {
            return nil
        }
    }
}

final class MockNimbusMessagingHelperUtility: NimbusMessagingHelperUtilityProtocol {
    required init(logger: Logger = DefaultLogger.shared) { }

    func createNimbusMessagingHelper() -> NimbusMessagingHelperProtocol? {
        return NimbusMessagingHelper(
            targetingHelper: MockNimbusTargetingHelper(),
            stringHelper: MockNimbusStringHelper())
    }
}
