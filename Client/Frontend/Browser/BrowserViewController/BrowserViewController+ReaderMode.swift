// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared

extension BrowserViewController: ReaderModeDelegate {
    func readerMode(_ readerMode: ReaderMode, didChangeReaderModeState state: ReaderModeState, forTab tab: Tab) {
        // If this reader mode availability state change is for the tab that we currently show, then update
        // the button. Otherwise do nothing and the button will be updated when the tab is made active.
        if tabManager.selectedTab === tab {
            urlBar.updateReaderModeState(state, hideReloadButton: shouldUseiPadSetup())
        }
    }

    func readerMode(_ readerMode: ReaderMode, didDisplayReaderizedContentForTab tab: Tab) {
        // If this reader mode availability state change is for the tab that we currently show, then update
        // the button. Otherwise do nothing and the button will be updated when the tab is made active.
        if tabManager.selectedTab === tab {
            self.showReaderModeBar(animated: true)
            tab.showContent(true)
        }
    }

    func readerMode(_ readerMode: ReaderMode, didParseReadabilityResult readabilityResult: ReadabilityResult, forTab tab: Tab) {
        TabEvent.post(.didLoadReadability(readabilityResult), for: tab)
    }
}

extension BrowserViewController: ReaderModeStyleViewControllerDelegate {
    func readerModeStyleViewController(_ readerModeStyleViewController: ReaderModeStyleViewController,
                                       didConfigureStyle style: ReaderModeStyle,
                                       isUsingUserDefinedColor: Bool) {
        var newStyle = style
        if !isUsingUserDefinedColor {
            newStyle.ensurePreferredColorThemeIfNeeded()
        }
        
        // Persist the new style to the profile
        let encodedStyle: [String: Any] = style.encodeAsDictionary()
        profile.prefs.setObject(encodedStyle, forKey: ReaderModeProfileKeyStyle)

        // Change the reader mode style on all tabs that have reader mode active
        for tabIndex in 0..<tabManager.count {
            guard let tab = tabManager[tabIndex],
                  let readerMode = tab.getContentScript(name: "ReaderMode") as? ReaderMode,
                  readerMode.state == ReaderModeState.active else { continue }

            readerMode.style = ReaderModeStyle(theme: newStyle.theme,
                                               fontType: ReaderModeFontType(type: newStyle.fontType.rawValue),
                                               fontSize: newStyle.fontSize)
        }
    }
}

extension BrowserViewController {
    func updateReaderModeBar() {
        guard let readerModeBar = readerModeBar else { return }
        readerModeBar.applyTheme()

        if let url = self.tabManager.selectedTab?.url?.displayURL?.absoluteString, let record = profile.readingList.getRecordWithURL(url).value.successValue {
            readerModeBar.unread = record.unread
            readerModeBar.added = true
        } else {
            readerModeBar.unread = true
            readerModeBar.added = false
        }
    }

    func showReaderModeBar(animated: Bool) {
        if self.readerModeBar == nil {
            let readerModeBar = ReaderModeBarView(frame: CGRect.zero)
            readerModeBar.delegate = self
            if isBottomSearchBar {
                overKeyboardContainer.addArrangedViewToTop(readerModeBar)
            } else {
                header.addArrangedViewToBottom(readerModeBar)
            }

            self.readerModeBar = readerModeBar
        }

        updateReaderModeBar()

        updateViewConstraints()
    }

    func hideReaderModeBar(animated: Bool) {
        guard let readerModeBar = readerModeBar else { return }
        if isBottomSearchBar {
            overKeyboardContainer.removeArrangedView(readerModeBar)
        } else {
            header.removeArrangedView(readerModeBar)
        }
        self.readerModeBar = nil
        updateViewConstraints()
    }

    /// There are two ways we can enable reader mode. In the simplest case we open a URL to our internal reader mode
    /// and be done with it. In the more complicated case, reader mode was already open for this page and we simply
    /// navigated away from it. So we look to the left and right in the BackForwardList to see if a readerized version
    /// of the current page is there. And if so, we go there.

    func enableReaderMode() {
        guard let tab = tabManager.selectedTab, let webView = tab.webView else { return }

        let backList = webView.backForwardList.backList
        let forwardList = webView.backForwardList.forwardList

        guard let currentURL = webView.backForwardList.currentItem?.url,
                let readerModeURL = currentURL.encodeReaderModeURL(WebServer.sharedInstance.baseReaderModeURL()) else { return }

        if backList.count > 1 && backList.last?.url == readerModeURL {
            webView.go(to: backList.last!)
        } else if forwardList.count > 0 && forwardList.first?.url == readerModeURL {
            webView.go(to: forwardList.first!)
        } else {
            // Store the readability result in the cache and load it. This will later move to the ReadabilityHelper.
            webView.evaluateJavascriptInDefaultContentWorld("\(ReaderModeNamespace).readerize()") { object, error in
                guard let readabilityResult = ReadabilityResult(object: object as AnyObject?) else { return }

                try? self.readerModeCache.put(currentURL, readabilityResult)
                if let nav = webView.load(PrivilegedRequest(url: readerModeURL) as URLRequest) {
                    self.ignoreNavigationInTab(tab, navigation: nav)
                }
            }
        }
    }

    /// Disabling reader mode can mean two things. In the simplest case we were opened from the reading list, which
    /// means that there is nothing in the BackForwardList except the internal url for the reader mode page. In that
    /// case we simply open a new page with the original url. In the more complicated page, the non-readerized version
    /// of the page is either to the left or right in the BackForwardList. If that is the case, we navigate there.

    func disableReaderMode() {
        guard let tab = tabManager.selectedTab,
              let webView = tab.webView else { return }

        let backList = webView.backForwardList.backList
        let forwardList = webView.backForwardList.forwardList

        guard let currentURL = webView.backForwardList.currentItem?.url,
              let originalURL = currentURL.decodeReaderModeURL else { return }

        if backList.count > 1 && backList.last?.url == originalURL {
            webView.go(to: backList.last!)
        } else if forwardList.count > 0 && forwardList.first?.url == originalURL {
            webView.go(to: forwardList.first!)
        } else if let nav = webView.load(URLRequest(url: originalURL)) {
            ignoreNavigationInTab(tab, navigation: nav)
        }
    }

    @objc func dynamicFontChanged(_ notification: Notification) {
        guard notification.name == .DynamicFontChanged else { return }

        var readerModeStyle = DefaultReaderModeStyle
        if let dict = profile.prefs.dictionaryForKey(ReaderModeProfileKeyStyle),
           let style = ReaderModeStyle(dict: dict as [String: AnyObject]) {
            readerModeStyle = style
        }

        readerModeStyle.fontSize = ReaderModeFontSize.defaultSize
        readerModeStyleViewController(ReaderModeStyleViewController(),
                                      didConfigureStyle: readerModeStyle,
                                      isUsingUserDefinedColor: false)
    }
    
    func appyThemeForPreferences(_ preferences: Prefs, contentScript: TabContentScript) {
        ReaderModeStyleViewController().applyTheme(preferences, contentScript: contentScript)
    }
}

extension BrowserViewController: ReaderModeBarViewDelegate {
    func readerModeBar(_ readerModeBar: ReaderModeBarView, didSelectButton buttonType: ReaderModeBarButtonType) {
        libraryDrawerViewController?.close()

        switch buttonType {
        case .settings:
            guard let readerMode = tabManager.selectedTab?.getContentScript(name: "ReaderMode") as? ReaderMode,
                    readerMode.state == ReaderModeState.active else { break }

            var readerModeStyle = DefaultReaderModeStyle
            if let dict = profile.prefs.dictionaryForKey(ReaderModeProfileKeyStyle),
               let style = ReaderModeStyle(dict: dict as [String: AnyObject]) {
                readerModeStyle = style
            }

            let readerModeViewModel = ReaderModeStyleViewModel(isBottomPresented: isBottomSearchBar,
                                                               readerModeStyle: readerModeStyle)
            let readerModeStyleViewController = ReaderModeStyleViewController.initReaderModeViewController(viewModel: readerModeViewModel)
            readerModeStyleViewController.delegate = self
            readerModeStyleViewController.modalPresentationStyle = .popover

            let setupPopover = { [unowned self] in
                guard let popoverPresentationController = readerModeStyleViewController.popoverPresentationController else { return }

                let arrowDirection: UIPopoverArrowDirection = isBottomSearchBar ? .down : .up
                let ySpacing = isBottomSearchBar ? -1 : UIConstants.ToolbarHeight

                popoverPresentationController.backgroundColor = UIColor.Photon.White100
                popoverPresentationController.delegate = self
                popoverPresentationController.sourceView = readerModeBar
                popoverPresentationController.sourceRect = CGRect(x: readerModeBar.frame.width/2, y: ySpacing,
                                                                  width: 1, height: 1)
                popoverPresentationController.permittedArrowDirections = arrowDirection
            }

            setupPopover()

            if readerModeStyleViewController.popoverPresentationController != nil {
                displayedPopoverController = readerModeStyleViewController
                updateDisplayedPopoverProperties = setupPopover
            }

            present(readerModeStyleViewController, animated: true, completion: nil)

        case .markAsRead:
            guard let url = self.tabManager.selectedTab?.url?.displayURL?.absoluteString,
                  let record = profile.readingList.getRecordWithURL(url).value.successValue else { break }

            profile.readingList.updateRecord(record, unread: false) // TODO Check result, can this fail?
            readerModeBar.unread = false

        case .markAsUnread:
            guard let url = self.tabManager.selectedTab?.url?.displayURL?.absoluteString,
                    let record = profile.readingList.getRecordWithURL(url).value.successValue else { break }

            profile.readingList.updateRecord(record, unread: true) // TODO Check result, can this fail?
            readerModeBar.unread = true

        case .addToReadingList:
            guard let tab = tabManager.selectedTab,
                  let rawURL = tab.url, rawURL.isReaderModeURL,
                  let url = rawURL.decodeReaderModeURL else { break }

            profile.readingList.createRecordWithURL(url.absoluteString,
                                                    title: tab.title ?? "",
                                                    addedBy: UIDevice.current.name) // TODO Check result, can this fail?
            readerModeBar.added = true
            readerModeBar.unread = true

        case .removeFromReadingList:
            guard let url = self.tabManager.selectedTab?.url?.displayURL?.absoluteString,
                  let record = profile.readingList.getRecordWithURL(url).value.successValue else { break }

            profile.readingList.deleteRecord(record) // TODO Check result, can this fail?
            readerModeBar.added = false
            readerModeBar.unread = false
        }
    }
}
