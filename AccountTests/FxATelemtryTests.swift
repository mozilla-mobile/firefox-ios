// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

@testable import Account
import SwiftyJSON
import SyncTelemetry
import Foundation

import Shared
import XCTest

class FxATelemetryTests: XCTestCase {
    func testParseTelemetry()  {
        let events: [Event] = FxATelemetry.parseTelemetry(fromJSONString:
        """
        {
          "commands_sent": [
            {
              "flow_id": "some flow_id 1",
              "stream_id": "some stream_id 1"
            },
            {
              "flow_id": "some flow_id 2",
              "stream_id": "some stream_id 2"
            }
          ],
          "commands_received": [
            {
              "flow_id": "some flow_id 3",
              "stream_id": "some stream_id 3",
              "reason": "some reason 3"
            },
            {
              "flow_id": "some flow_id 4",
              "stream_id": "some stream_id 4",
              "reason": "some reason 4"
            },
            {
              "flow_id": "some flow_id 5",
              "stream_id": "some stream_id 5",
              "reason": "some reason 5"
            }
          ]
        }
        """
        )

        XCTAssertEqual(events.count, 5)
    }
}
