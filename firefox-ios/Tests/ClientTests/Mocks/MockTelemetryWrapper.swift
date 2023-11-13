// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

class MockTelemetryWrapper: TelemetryWrapperProtocol {
    var recordEventCallCount = 0
    var recordedCategories = [TelemetryWrapper.EventCategory]()
    var recordedMethods = [TelemetryWrapper.EventMethod]()
    var recordedObjects = [TelemetryWrapper.EventObject]()

    func recordEvent(category: TelemetryWrapper.EventCategory,
                     method: TelemetryWrapper.EventMethod,
                     object: TelemetryWrapper.EventObject,
                     value: TelemetryWrapper.EventValue?,
                     extras: [String: Any]?) {
        recordEventCallCount += 1
        recordedCategories.append(category)
        recordedMethods.append(method)
        recordedObjects.append(object)
    }
}
