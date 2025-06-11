// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import Common

struct TabsPanelTelemetry {
    enum Mode: String {
        case normal
        case `private`
        case sync

        var hasNewTabButton: Bool {
            switch self {
            case .normal, .private:
                return true
            default:
                return false
            }
        }
    }

    enum CloseAllPanelOption: String {
        case all
        case cancel
        case old
    }

    private enum TabType: String {
        case normal
        case `private`
        case inactive
        case total
    }

    private let gleanWrapper: GleanWrapper
    private let logger: Logger

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper(), logger: Logger = DefaultLogger.shared) {
        self.gleanWrapper = gleanWrapper
        self.logger = logger
    }

    func newTabButtonTapped(mode: Mode) {
        guard mode.hasNewTabButton else {
            logger.log("Mode is not of expected mode types for new button", level: .debug, category: .tabs)
            return
        }

        let extras = GleanMetrics.TabsPanel.NewTabButtonTappedExtra(mode: mode.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.TabsPanel.newTabButtonTapped, extras: extras)
    }

    func tabModeSelected(mode: Mode) {
        let extras = GleanMetrics.TabsPanel.TabModeSelectedExtra(mode: mode.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.TabsPanel.tabModeSelected, extras: extras)
    }

    func tabSelected(at index: Int?, mode: Mode) {
        let indexForGlean: Int32? = index != nil ? Int32(index!) : nil
        let extras = GleanMetrics.TabsPanel.TabSelectedExtra(mode: mode.rawValue, selectedTabIndex: indexForGlean)
        gleanWrapper.recordEvent(for: GleanMetrics.TabsPanel.tabSelected, extras: extras)
    }

    func closeAllTabsSheetOptionSelected(option: CloseAllPanelOption, mode: Mode) {
        let extras = GleanMetrics.TabsPanelCloseAllTabsSheet.OptionSelectedExtra(
            mode: mode.rawValue,
            option: option.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.TabsPanelCloseAllTabsSheet.optionSelected, extras: extras)
    }

    func tabClosed(mode: Mode) {
        let extras = GleanMetrics.TabsPanel.TabClosedExtra(
            mode: mode.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.TabsPanel.tabClosed, extras: extras)
    }

    func doneButtonTapped(mode: Mode) {
        let extras = GleanMetrics.TabsPanel.DoneButtonTappedExtra(mode: mode.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.TabsPanel.doneButtonTapped, extras: extras)
    }

    func deleteNormalTabsSheetOptionSelected(period: TabsDeletionPeriod) {
        let extras = GleanMetrics.TabsPanelCloseOldTabsSheet.OptionSelectedExtra(
            period: period.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.TabsPanelCloseOldTabsSheet.optionSelected, extras: extras)
    }
}
