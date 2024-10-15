// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Storage
import Glean
import Common
import ComponentLibrary

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

        if isTabTrayRefactorEnabled {
            let isPrivateTab = tabManager.selectedTab?.isPrivate ?? false
            let selectedSegment: TabTrayPanelType = focusedSegment ?? (isPrivateTab ? .privateTabs : .tabs)
            navigationHandler?.showTabTray(selectedPanel: selectedSegment)
        } else {
            willNavigateAway()
            showLegacyTabTrayViewController(withFocusOnUnselectedTab: tabToFocus,
                                            focusedSegment: focusedSegment)
        }
    }

    private func showLegacyTabTrayViewController(withFocusOnUnselectedTab tabToFocus: Tab? = nil,
                                                 focusedSegment: TabTrayPanelType? = nil) {
        tabTrayViewController = LegacyTabTrayViewController(
            tabTrayDelegate: self,
            profile: profile,
            tabToFocus: tabToFocus,
            tabManager: tabManager,
            overlayManager: overlayManager,
            focusedSegment: focusedSegment)
        (tabTrayViewController as? LegacyTabTrayViewController)?.qrCodeNavigationHandler = navigationHandler
        tabTrayViewController?.openInNewTab = { url, isPrivate in
            let tab = self.tabManager.addTab(
                URLRequest(url: url),
                afterTab: self.tabManager.selectedTab,
                isPrivate: isPrivate
            )
            // If we are showing toptabs a user can just use the top tab bar
            // If in overlay mode switching doesnt correctly dismiss the homepanels
            guard !self.topTabsVisible,
                  !self.isToolbarRefactorEnabled,
                  !self.urlBar.inOverlayMode else { return }
            // We're not showing the top tabs; show a toast to quick switch to the fresh new tab.
            let viewModel = ButtonToastViewModel(labelText: .ContextMenuButtonToastNewTabOpenedLabelText,
                                                 buttonText: .ContextMenuButtonToastNewTabOpenedButtonText)
            let toast = ButtonToast(viewModel: viewModel,
                                    theme: self.currentTheme(),
                                    completion: { buttonPressed in
                if buttonPressed {
                    self.tabManager.selectTab(tab)
                }
            })
            self.show(toast: toast)
        }

        tabTrayViewController?.didSelectUrl = { url, visitType in
            guard let tab = self.tabManager.selectedTab else { return }
            self.finishEditingAndSubmit(url, visitType: visitType, forTab: tab)
        }

        guard self.tabTrayViewController != nil else { return }

        let navigationController = ThemedDefaultNavigationController(rootViewController: tabTrayViewController!,
                                                                     windowUUID: windowUUID)
        navigationController.presentationController?.delegate = tabTrayViewController

        self.present(navigationController, animated: true, completion: nil)

        TelemetryWrapper.recordEvent(category: .action, method: .open, object: .tabTray)

        // App store review in-app prompt
        ratingPromptManager.showRatingPromptIfNeeded()
    }

    func urlBarDidPressReload(_ urlBar: URLBarView) {
        tabManager.selectedTab?.reload()
    }

    func urlBarDidPressShare(_ urlBar: URLBarView, shareView: UIView) {
        didTapOnShare(from: shareView)
    }

    internal func dismissFakespotIfNeeded(animated: Bool = true) {
        guard !contentStackView.isSidebarVisible else {
            // hide sidebar as user tapped on shopping icon for a second time
            navigationHandler?.dismissFakespotSidebar(sidebarContainer: contentStackView, parentViewController: self)
            return
        }

        // dismiss modal as user tapped on shopping icon for a second time
        navigationHandler?.dismissFakespotModal(animated: animated)
    }

    internal func handleFakespotFlow(productURL: URL, viewSize: CGSize? = nil) {
        let shouldDisplayInSidebar = FakespotUtils().shouldDisplayInSidebar(viewSize: viewSize)
        if !shouldDisplayInSidebar, contentStackView.isSidebarVisible {
            // Quick fix: make sure to sidebar is hidden
            // Relates to FXIOS-7844
            contentStackView.hideSidebar(self)
        }

        if shouldDisplayInSidebar {
            navigationHandler?.showFakespotFlowAsSidebar(productURL: productURL,
                                                         sidebarContainer: contentStackView,
                                                         parentViewController: self)
        } else {
            navigationHandler?.showFakespotFlowAsModal(productURL: productURL)
        }
    }

    func urlBarPresentCFR(at sourceView: UIView) {
        configureShoppingContextVC(at: sourceView)
    }

    private func configureShoppingContextVC(at sourceView: UIView) {
        let windowUUID = windowUUID
        shoppingContextHintVC.configure(
            anchor: sourceView,
            withArrowDirection: isBottomSearchBar ? .down : .up,
            andDelegate: self,
            presentedUsing: { [unowned self] in
                self.present(shoppingContextHintVC, animated: true)
                TelemetryWrapper.recordEvent(
                    category: .action,
                    method: .navigate,
                    object: .shoppingButton,
                    value: .shoppingCFRsDisplayed
                )
            },
            andActionForButton: {
                let action = FakespotAction(windowUUID: windowUUID,
                                            actionType: FakespotActionType.show)
                store.dispatch(action)
            },
            overlayState: overlayManager)
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
            return [pasteGoAction, pasteAction, copyAddressAction]
        } else {
            return [copyAddressAction]
        }
    }

    func urlBarDisplayTextForURL(_ url: URL?) -> (String?, Bool) {
        // use the initial value for the URL so we can do proper pattern matching with search URLs
        var searchURL = self.tabManager.selectedTab?.url
        if let url = searchURL, InternalURL.isValid(url: url) {
            searchURL = url
        }
        if let query = profile.searchEngines.queryForSearchURL(searchURL as URL?) {
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
        if !contentContainer.hasLegacyHomepage {
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
        guard let engine = profile.searchEngines.defaultEngine,
              let searchURL = engine.searchURLForQuery(text)
        else {
            DefaultLogger.shared.log("Error handling URL entry: \"\(text)\".", level: .warning, category: .tabs)
            return
        }

        let conversionMetrics = UserConversionMetrics()
        conversionMetrics.didPerformSearch()

        Experiments.events.recordEvent(BehavioralTargetingEvent.performedSearch)

        GleanMetrics.Search
            .counts["\(engine.engineID ?? "custom").\(SearchLocation.actionBar.rawValue)"]
            .add()
        searchTelemetry?.shouldSetUrlTypeSearch = true

        let searchData = LegacyTabGroupData(searchTerm: text,
                                            searchUrl: searchURL.absoluteString,
                                            nextReferralUrl: "")
        tab.metadataManager?.updateTimerAndObserving(
            state: .navSearchLoaded,
            searchData: searchData,
            isPrivate: tab.isPrivate
        )
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
