// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing

import XCTest

@testable import Client

class MockRelayController: RelayControllerProtocol {
    func shouldDisplayRelaySettings() -> Bool {
        return true
    }

    func emailFocusShouldDisplayRelayPrompt(url: URL) -> Bool {
        return true
    }

    func populateEmailFieldWithRelayMask(for tab: Client.Tab, completion: @escaping Client.RelayPopulateCompletion) {
    }

    func emailFieldFocused(in tab: Client.Tab) {
    }

    var telemetry: Client.RelayMaskTelemetry {
        return Client.RelayMaskTelemetry(gleanWrapper: MockGleanWrapper())
    }
}
