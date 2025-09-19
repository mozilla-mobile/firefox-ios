// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import XCTest

@testable import Client

class MockRecordVisitObservationManager: RecordVisitObserving {
    private(set) var recordVisitCalled = 0
    private(set) var resetVisitCalled = 0
    var lastVisitObservation: VisitObservation?

    func recordVisit(visitObservation: VisitObservation, isPrivateTab: Bool) {
        recordVisitCalled += 1
        lastVisitObservation = visitObservation
    }

    func resetRecording() {
        resetVisitCalled += 1
    }
}
