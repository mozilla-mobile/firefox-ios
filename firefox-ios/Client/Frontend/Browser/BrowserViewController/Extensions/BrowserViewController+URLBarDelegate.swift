// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Glean
import Common

import enum MozillaAppServices.VisitType

protocol OnViewDismissable: AnyObject {
    var onViewDismissed: (() -> Void)? { get set }
}

class DismissableNavigationViewController: UINavigationController, OnViewDismissable {
    var onViewDismissed: (() -> Void)?
    var onViewWillDisappear: (() -> Void)?

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onViewWillDisappear?()
        onViewWillDisappear = nil
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onViewDismissed?()
        onViewDismissed = nil
    }
}

extension BrowserViewController {
    func showTabTray(withFocusOnUnselectedTab tabToFocus: Tab? = nil,
                     focusedSegment: TabTrayPanelType? = nil) {
        updateFindInPageVisibility(isVisible: false)

        let isPrivateTab = tabManager.selectedTab?.isPrivate ?? false
        let selectedSegment: TabTrayPanelType = focusedSegment ?? (isPrivateTab ? .privateTabs : .tabs)
        navigationHandler?.showTabTray(selectedPanel: selectedSegment)
    }

    func submitSearchText(_ text: String, forTab tab: Tab) {
        guard let engine = searchEnginesManager.defaultEngine,
              let searchURL = engine.searchURLForQuery(text)
        else {
            DefaultLogger.shared.log("Error handling URL entry: \"\(text)\".", level: .warning, category: .tabs)
            return
        }

        let conversionMetrics = UserConversionMetrics()
        conversionMetrics.didPerformSearch()

        Experiments.events.recordEvent(BehavioralTargetingEvent.performedSearch)

        let engineTelemetryID: String = engine.telemetryID
        GleanMetrics.Search
            .counts["\(engineTelemetryID).\(SearchLocation.actionBar.rawValue)"]
            .add()
        searchTelemetry.shouldSetUrlTypeSearch = true

        finishEditingAndSubmit(searchURL, visitType: VisitType.typed, forTab: tab)
    }
}
