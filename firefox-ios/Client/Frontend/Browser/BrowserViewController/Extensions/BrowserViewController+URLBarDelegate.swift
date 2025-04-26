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

extension BrowserViewController: URLBarDelegate {
    func showTabTray(withFocusOnUnselectedTab tabToFocus: Tab? = nil,
                     focusedSegment: TabTrayPanelType? = nil) {
        updateFindInPageVisibility(isVisible: false)

        let isPrivateTab = tabManager.selectedTab?.isPrivate ?? false
        let selectedSegment: TabTrayPanelType = focusedSegment ?? (isPrivateTab ? .privateTabs : .tabs)
        navigationHandler?.showTabTray(selectedPanel: selectedSegment)
    }

    func urlBarDidPressReload(_ urlBar: URLBarView) {
        tabManager.selectedTab?.reload()
    }

    func urlBarPresentCFR(at sourceView: UIView) {
    }

    func urlBarDidPressQRButton(_ urlBar: URLBarView) {
        navigationHandler?.showQRCode(delegate: self)
    }

    func urlBarDidTapShield(_ urlBar: URLBarView) {
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .trackingProtectionMenu)
        navigationHandler?.showEnhancedTrackingProtection(sourceView: urlBar.locationView.trackingProtectionButton)
     }

    func urlBarDidPressStop(_ urlBar: URLBarView) {
        tabManager.selectedTab?.stop()
    }

    func urlBarDidPressTabs(_ urlBar: URLBarView) {
        showTabTray()
    }

    func urlBarDidPressReaderMode(_ urlBar: URLBarView) {
        toggleReaderMode()
    }

    func urlBarDidLongPressReaderMode(_ urlBar: URLBarView) -> Bool {
        toggleReaderModeLongPressAction()
    }

    func urlBarDidLongPressReload(_ urlBar: URLBarView, from button: UIButton) {
        presentRefreshLongPressAction(from: button)
    }

    func locationActionsForURLBar() -> [AccessibleAction] {
        if UIPasteboard.general.hasStrings {
            return [pasteGoAction, pasteAction, copyAddressAction].compactMap { $0 }
        } else {
            return [copyAddressAction].compactMap { $0 }
        }
    }

    func urlBarDisplayTextForURL(_ url: URL?) -> (String?, Bool) {
        // use the initial value for the URL so we can do proper pattern matching with search URLs
        var searchURL = self.tabManager.selectedTab?.url
        if let url = searchURL, InternalURL.isValid(url: url) {
            searchURL = url
        }
        if let query = searchEnginesManager.queryForSearchURL(searchURL as URL?) {
            return (query, true)
        } else {
            return (url?.absoluteString, false)
        }
    }

    func urlBarDidLongPressLocation(_ urlBar: URLBarView) {
        presentLocationViewActionSheet(from: urlBar)
    }

    func urlBarDidPressScrollToTop(_ urlBar: URLBarView) {
        guard let selectedTab = tabManager.selectedTab else { return }
        if !contentContainer.hasAnyHomepage {
            // Only scroll to top if we are not showing the home view controller
            selectedTab.webView?.scrollView.setContentOffset(CGPoint.zero, animated: true)
        }
    }

    func urlBarLocationAccessibilityActions(_ urlBar: URLBarView) -> [UIAccessibilityCustomAction]? {
        return locationActionsForURLBar().map { $0.accessibilityCustomAction }
    }

    func urlBar(_ urlBar: URLBarView, didRestoreText text: String) {
        if text.isEmpty {
            hideSearchController()
        } else {
            configureOverlayView()
        }

        searchController?.viewModel.searchQuery = text
        searchController?.searchTelemetry?.searchQuery = text
        searchController?.searchTelemetry?.interactionType = .refined
        searchLoader?.setQueryWithoutAutocomplete(text)
    }

    func urlBar(_ urlBar: URLBarView, didEnterText text: String) {
        searchSuggestions(searchTerm: text)
        urlBar.locationTextField?.applyUIMode(
            isPrivate: tabManager.selectedTab?.isPrivate ?? false,
            theme: self.currentTheme()
        )
    }

    func urlBar(_ urlBar: URLBarView, didSubmitText text: String) {
        didSubmitSearchText(text)
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

    func urlBarDidEnterOverlayMode(_ urlBar: URLBarView) {
        urlBar.searchEnginesDidUpdate()
        addressToolbarDidEnterOverlayMode(urlBar)
    }

    func urlBar(_ urlBar: URLBarView, didLeaveOverlayModeForReason reason: URLBarLeaveOverlayModeReason) {
        addressToolbar(urlBar, didLeaveOverlayModeForReason: reason)
    }

    func urlBarDidBeginDragInteraction(_ urlBar: URLBarView) {
        dismissVisibleMenus()
    }
}
