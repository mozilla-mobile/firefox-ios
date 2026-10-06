// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MockTabsPanelTelemetry: TabsPanelTelemetryProtocol {
    var newTabButtonCalled: (callCount: Int, withMode: Mode?) = (0, nil)

    func newTabButtonTapped(mode: Mode) {
        newTabButtonCalled = (newTabButtonCalled.callCount + 1, mode)
    }

    func tabModeSelected(mode: Mode) {}
    func tabSelected(at index: Int?, mode: Mode) {}
    func closeAllTabsSheetOptionSelected(option: CloseAllPanelOption, mode: Mode) {}
    func tabClosed(mode: Mode) {}
    func doneButtonTapped(mode: Mode) {}
    func deleteNormalTabsSheetOptionSelected(period: TabsDeletionPeriod) {}
}
