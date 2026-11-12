// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

final class MockTabLossTelemetry: TabLossTelemetryRecording {
    private(set) var recordTabLossDetectedCalled = 0
    private(set) var recordTabCountDiscrepancyCalled = 0
    private(set) var savedTabLossDetectedDetails: TabLossTelemetry.TabLossDiagnostic?
    private(set) var savedTabCountDiscrepancyDetails: TabLossTelemetry.TabLossDiagnostic?

    func recordTabLossDetected(withDetails details: TabLossTelemetry.TabLossDiagnostic) {
        recordTabLossDetectedCalled += 1
        savedTabLossDetectedDetails = details
    }

    func recordTabCountDiscrepancy(withDetails details: TabLossTelemetry.TabLossDiagnostic) {
        recordTabCountDiscrepancyCalled += 1
        savedTabCountDiscrepancyDetails = details
    }
}
