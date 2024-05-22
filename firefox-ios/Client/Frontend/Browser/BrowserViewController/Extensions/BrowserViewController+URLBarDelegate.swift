// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Storage
import Glean
import Common
import ComponentLibrary

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
        updateFindInPageVisibility(visible: false)

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
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .awesomebarLocation,
                                     value: .awesomebarShareTap,
                                     extras: nil)

        if let selectedtab = tabManager.selectedTab, let tabUrl = selectedtab.canonicalURL?.displayURL {
            navigationHandler?.showShareExtension(
                url: tabUrl,
                sourceView: shareView,
                toastContainer: contentContainer,
                popoverArrowDirection: isBottomSearchBar ? .down : .up)
        }
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
        guard let tab = tabManager.selectedTab,
              let readerMode = tab.getContentScript(name: "ReaderMode") as? ReaderMode
        else { return }

        switch readerMode.state {
        case .available:
            enableReaderMode()
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .readerModeOpenButton)
        case .active:
            disableReaderMode()
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .readerModeCloseButton)
        case .unavailable:
            break
        }
    }

    func urlBarDidLongPressReaderMode(_ urlBar: URLBarView) -> Bool {
        guard let tab = tabManager.selectedTab,
              let url = tab.url?.displayURL
        else {
            UIAccessibility.post(
                notification: UIAccessibility.Notification.announcement,
                argument: String.ReaderModeAddPageGeneralErrorAccessibilityLabel
            )
            return false
        }

        let result = profile.readingList.createRecordWithURL(
            url.absoluteString,
            title: tab.title ?? "",
            addedBy: UIDevice.current.name
        )

        switch result.value {
        case .success:
            UIAccessibility.post(
                notification: UIAccessibility.Notification.announcement,
                argument: String.ReaderModeAddPageSuccessAcessibilityLabel
            )
            SimpleToast().showAlertWithText(.ShareAddToReadingListDone,
                                            bottomContainer: contentContainer,
                                            theme: currentTheme())
        case .failure:
            UIAccessibility.post(
                notification: UIAccessibility.Notification.announcement,
                argument: String.ReaderModeAddPageMaybeExistsErrorAccessibilityLabel
            )
        }
        return true
    }

    func urlBarDidLongPressReload(_ urlBar: URLBarView, from button: UIButton) {
        guard let tab = tabManager.selectedTab else { return }
        let urlActions = self.getRefreshLongPressMenu(for: tab)
        guard !urlActions.isEmpty else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        let shouldSuppress = !topTabsVisible && UIDevice.current.userInterfaceIdiom == .pad
        let style: UIModalPresentationStyle = !shouldSuppress ? .popover : .overCurrentContext
        let viewModel = PhotonActionSheetViewModel(
            actions: [urlActions],
            closeButtonTitle: .CloseButtonTitle,
            modalStyle: style
        )
        presentSheetWith(viewModel: viewModel, on: self, from: button)
    }

    func locationActionsForURLBar(_ urlBar: URLBarView) -> [AccessibleAction] {
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
        let urlActions = self.getLongPressLocationBarActions(with: urlBar, alertContainer: contentContainer)
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        let shouldSuppress = UIDevice.current.userInterfaceIdiom != .pad
        let style: UIModalPresentationStyle = !shouldSuppress ? .popover : .overCurrentContext
        let viewModel = PhotonActionSheetViewModel(
            actions: [urlActions],
            closeButtonTitle: .CloseButtonTitle,
            modalStyle: style
        )
        self.presentSheetWith(viewModel: viewModel, on: self, from: urlBar)
    }

    func urlBarDidPressScrollToTop(_ urlBar: URLBarView) {
        guard let selectedTab = tabManager.selectedTab else { return }
        if !contentContainer.hasHomepage {
            // Only scroll to top if we are not showing the home view controller
            selectedTab.webView?.scrollView.setContentOffset(CGPoint.zero, animated: true)
        }
    }

    func urlBarLocationAccessibilityActions(_ urlBar: URLBarView) -> [UIAccessibilityCustomAction]? {
        return locationActionsForURLBar(urlBar).map { $0.accessibilityCustomAction }
    }

    func urlBar(_ urlBar: URLBarView, didRestoreText text: String) {
        if text.isEmpty {
            hideSearchController()
        } else {
            configureOverlayView()
        }

        searchController?.searchQuery = text
        searchController?.searchTelemetry?.searchQuery = text
        searchController?.searchTelemetry?.interactionType = .refined
        searchLoader?.setQueryWithoutAutocomplete(text)
    }

    func urlBar(_ urlBar: URLBarView, didEnterText text: String) {
        if text.isEmpty {
            hideSearchController()
        } else {
            configureOverlayView()
        }
        urlBar.locationTextField?.applyUIMode(
            isPrivate: tabManager.selectedTab?.isPrivate ?? false,
            theme: self.currentTheme()
        )
        searchController?.searchQuery = text
        searchController?.searchTelemetry?.searchQuery = text
        searchController?.searchTelemetry?.clearVisibleResults()
        searchLoader?.query = text
        searchController?.searchTelemetry?.determineInteractionType()
    }

    func urlBar(_ urlBar: URLBarView, didSubmitText text: String) {
        guard let currentTab = tabManager.selectedTab else { return }

        if let fixupURL = URIFixup.getURL(text) {
            // The user entered a URL, so use it.
            finishEditingAndSubmit(fixupURL, visitType: VisitType.typed, forTab: currentTab)
            return
        }

        // We couldn't build a URL, so check for a matching search keyword.
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        guard let possibleKeywordQuerySeparatorSpace = trimmedText.firstIndex(of: " ") else {
            submitSearchText(text, forTab: currentTab)
            return
        }

        let possibleKeyword = String(trimmedText[..<possibleKeywordQuerySeparatorSpace])
        let possibleQuery = String(trimmedText[trimmedText.index(after: possibleKeywordQuerySeparatorSpace)...])

        profile.places.getBookmarkURLForKeyword(keyword: possibleKeyword).uponQueue(.main) { result in
            if var urlString = result.successValue ?? "",
               let escapedQuery = possibleQuery.addingPercentEncoding(
                withAllowedCharacters: NSCharacterSet.urlQueryAllowed
               ),
               let range = urlString.range(of: "%s") {
                urlString.replaceSubrange(range, with: escapedQuery)

                if let url = URL(string: urlString, invalidCharacters: false) {
                    self.finishEditingAndSubmit(url, visitType: VisitType.typed, forTab: currentTab)
                    return
                }
            }

            self.submitSearchText(text, forTab: currentTab)
        }
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
        guard let profile = profile as? BrowserProfile else { return }

        if .blankPage == NewTabAccessors.getNewTabPage(profile.prefs) {
            UIAccessibility.post(
                notification: UIAccessibility.Notification.screenChanged,
                argument: UIAccessibility.Notification.screenChanged
            )
        } else {
            if let toast = clipboardBarDisplayHandler?.clipboardToast {
                toast.removeFromSuperview()
            }

            showEmbeddedHomepage(inline: false, isPrivate: tabManager.selectedTab?.isPrivate ?? false)
        }

        urlBar.applyTheme(theme: currentTheme())
    }

    func urlBar(_ urlBar: URLBarView, didLeaveOverlayModeForReason reason: URLBarLeaveOverlayModeReason) {
        if searchSessionState == .active {
            // This delegate method may be called even if the user isn't
            // currently searching, but we only want to update the search
            // session state if they are.
            searchSessionState = switch reason {
            case .finished: .engaged
            case .cancelled: .abandoned
            }
        }
        destroySearchController()
        updateInContentHomePanel(tabManager.selectedTab?.url as URL?)

        urlBar.applyTheme(theme: currentTheme())
    }

    func urlBarDidBeginDragInteraction(_ urlBar: URLBarView) {
        dismissVisibleMenus()
    }
}
