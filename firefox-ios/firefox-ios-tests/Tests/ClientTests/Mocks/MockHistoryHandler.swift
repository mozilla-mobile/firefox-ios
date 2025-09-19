// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import Storage
import XCTest

@testable import Client

final class MockHistoryHandler: HistoryHandler {
    var applied: [VisitObservation] = []
    var appplyObservationCallCount = 0
    var nextResult: Result<Void, Error> = .success(())
    var onApply: (() -> Void)?

    func applyObservation(visitObservation: VisitObservation, completion: (Result<Void, any Error>) -> Void) {
        appplyObservationCallCount += 1
        applied.append(visitObservation)
        completion(nextResult)
        onApply?()
    }
}
