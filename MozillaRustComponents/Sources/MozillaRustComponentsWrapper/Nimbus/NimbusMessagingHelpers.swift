/* This Source Code Form is subject to the terms of the Mozilla
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Glean

/**
 * Instances of this class are useful for implementing a messaging service based upon
 * Nimbus.
 *
 * The message helper is designed to help string interpolation and JEXL evalutaiuon against the context
 * of the attrtibutes Nimbus already knows about.
 *
 * App-specific, additional context can be given at creation time.
 *
 * The helpers are designed to evaluate multiple messages at a time, however: since the context may change
 * over time, the message helper should not be stored for long periods.
 */
public protocol NimbusMessagingProtocol {
    func createMessageHelper() throws -> NimbusMessagingHelperProtocol
    func createMessageHelper(additionalContext: [String: Any]) throws -> NimbusMessagingHelperProtocol
    func createMessageHelper<T: Encodable>(additionalContext: T) throws -> NimbusMessagingHelperProtocol

    var events: NimbusEventStore { get }
}

public protocol NimbusMessagingHelperProtocol: NimbusStringHelperProtocol, NimbusTargetingHelperProtocol {
    /**
     * Clear the JEXL cache
     */
    func clearCache()
}

/**
 * A helper object to make working with Strings uniform across multiple implementations of the messaging
 * system.
 *
 * This object provides access to a JEXL evaluator which runs against the same context as provided by
 * Nimbus targeting.
 *
 * It should also provide a similar function for String substitution, though this scheduled for EXP-2159.
 */
public class NimbusMessagingHelper: NimbusMessagingHelperProtocol {
    private let targetingHelper: NimbusTargetingHelperProtocol
    private let stringHelper: NimbusStringHelperProtocol
    private var cache: [String: Bool]

    public init(targetingHelper: NimbusTargetingHelperProtocol,
                stringHelper: NimbusStringHelperProtocol,
                cache: [String: Bool] = [:])
    {
        self.targetingHelper = targetingHelper
        self.stringHelper = stringHelper
        self.cache = cache
    }

    public func evalJexl(expression: String) throws -> Bool {
        if let result = cache[expression] {
            return result
        } else {
            let result = try targetingHelper.evalJexl(expression: expression)
            cache[expression] = result
            return result
        }
    }

    public func clearCache() {
        cache.removeAll()
    }

    public func getUuid(template: String) -> String? {
        stringHelper.getUuid(template: template)
    }

    public func stringFormat(template: String, uuid: String?) -> String {
        stringHelper.stringFormat(template: template, uuid: uuid)
    }
}

// MARK: Dummy implementations

class AlwaysConstantTargetingHelper: NimbusTargetingHelperProtocol {
    private let constant: Bool

    init(constant: Bool = false) {
        self.constant = constant
    }

    func evalJexl(expression _: String) throws -> Bool {
        constant
    }
}

class EchoStringHelper: NimbusStringHelperProtocol {
    func getUuid(template _: String) -> String? {
        nil
    }

    func stringFormat(template: String, uuid _: String?) -> String {
        template
    }
}
