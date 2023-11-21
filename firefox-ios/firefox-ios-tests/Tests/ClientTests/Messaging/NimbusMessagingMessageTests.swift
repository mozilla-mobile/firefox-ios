// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

import Common
import Foundation
import MozillaAppServices
import Shared

@testable import Client

final class NimbusMessagingMessageTests: XCTestCase {
    var feature = FxNimbus.shared.features.messaging.value()
    lazy var subject = GleanPlumbMessageManager(
        messagingStore: MockGleanPlumbMessageStore(messageId: "")
    )

    func testAllMessageIntegrity() throws {
        let messages = subject.getMessages(feature)
        let rawMessages = feature.messages

        XCTAssertFalse(rawMessages.isEmpty)

        if rawMessages.count != messages.count {
            let expected = Set(rawMessages.keys)
            let observed = Set(messages.map { $0.id })
            let missing = expected.symmetricDifference(observed)
            XCTFail("Problem with message(s) in FML: \(missing)")
        }

        XCTAssertEqual(rawMessages.count, messages.count)
    }

    func testAllMessageTriggers() throws {
        let evaluationUtility = NimbusMessagingEvaluationUtility()
        let helper = NimbusMessagingHelperUtility().createNimbusMessagingHelper()!

        let messages = subject.getMessages(feature)
        var cache = [String: Bool]()
        messages.forEach { message in
            do {
                _ = try evaluationUtility.isMessageEligible(
                    message,
                    messageHelper: helper,
                    jexlCache: &cache)
            } catch {
                XCTFail("Message \(message.id) failed with invalid JEXL triggers")
            }
        }
    }
}
