// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

import Common
import Foundation
import MozillaAppServices
import Shared

@testable import Client

final class NimbusMessagingTriggerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        AppContainer.shared.reset()
        super.tearDown()
    }

    lazy var feature: Messaging = {
        FxNimbus.shared.initialize(with: { nil })
        return FxNimbusMessaging.shared.features.messaging.value()
    }()

    func testTriggers() throws {
        Experiments.events.clearEvents()
        Experiments.events.recordEvent(BehavioralTargetingEvent.appForeground)
        let helper = Experiments.createJexlHelper()!
        let triggers = feature.triggers

        var badJexlExpressions = [String: String]()
        triggers.forEach { (key, expression) in
            do {
                _ = try helper.evalJexl(expression: expression)
            } catch {
                DefaultLogger.shared.log("Failed to evaluate \(key) expression: \(expression)",
                                         level: .warning,
                                         category: .experiments)
                badJexlExpressions[key] = expression
            }
        }

        if !badJexlExpressions.isEmpty {
            XCTFail("JEXL trigger expressions \(badJexlExpressions.keys) are not valid")
        }
    }
}
