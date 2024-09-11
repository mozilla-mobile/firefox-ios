// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

extension BrowserViewController {
    func updateFindInPageVisibility(isVisible: Bool, tab: Tab? = nil, withSearchText searchText: String? = nil) {
        // TODO: The find interactions for iOS 16 close themselves, so once the min deployment target is iOS 16,
        // we may be able to remove the `isVisible` flag and let the system manage dismissal.
        if #available(iOS 16, *) {
            useSystemFindInteraction(isVisible: isVisible, withSearchText: searchText)
        } else {
            useCustomFindInteraction(isVisible: isVisible, tab: tab)
        }
        tabManager.selectedTab?.isFindInPageMode = isVisible && isBottomSearchBar
    }

    @available(iOS 16, *)
    private func useSystemFindInteraction(isVisible: Bool, withSearchText searchText: String?) {
        guard let webView = tabManager.selectedTab?.webView else { return }

        if isVisible {
            webView.isFindInteractionEnabled = true
            webView.findInteraction?.searchText = searchText ?? ""
            webView.findInteraction?.presentFindNavigator(showingReplace: false)
        } else {
            webView.findInteraction?.dismissFindNavigator()
            webView.isFindInteractionEnabled = false
        }
    }

    private func useCustomFindInteraction(isVisible: Bool, tab: Tab? = nil) {
        if isVisible {
            if findInPageBar == nil { setupFindInPage() }

            self.findInPageBar?.becomeFirstResponder()
        } else if let findInPageBar = self.findInPageBar {
            removeFindInPage(findInPageBar, tab: tab)
        }
    }

    private func setupFindInPage() {
        let findInPageBar = FindInPageBar()
        self.findInPageBar = findInPageBar
        findInPageBar.delegate = self

        bottomContentStackView.addArrangedViewToBottom(findInPageBar, animated: false, completion: {
            self.view.layoutIfNeeded()
        })

        findInPageBar.heightAnchor.constraint(
            greaterThanOrEqualToConstant: UIConstants.ToolbarHeight
        ).isActive = true

        findInPageBar.applyTheme(theme: currentTheme())

        updateViewConstraints()

        // We make the find-in-page bar the first responder below, causing the keyboard delegates
        // to fire. This, in turn, will animate the Find in Page container since we use the same
        // delegate to slide the bar up and down with the keyboard. We don't want to animate the
        // constraints added above, however, so force a layout now to prevent these constraints
        // from being lumped in with the keyboard animation.
        findInPageBar.layoutIfNeeded()
    }

    private func removeFindInPage(_ findInPageBar: FindInPageBar, tab: Tab? = nil) {
        findInPageBar.endEditing(true)
        let tab = tab ?? tabManager.selectedTab
        guard let webView = tab?.webView else { return }
        webView.evaluateJavascriptInDefaultContentWorld("__firefox__.findDone()")
        bottomContentStackView.removeArrangedView(findInPageBar)
        self.findInPageBar = nil
        updateViewConstraints()
    }
}

extension BrowserViewController: FindInPageBarDelegate, FindInPageHelperDelegate {
    func findInPage(_ findInPage: FindInPageBar, didTextChange text: String) {
        find(text, function: "find")
    }

    func findInPage(_ findInPage: FindInPageBar, didFindNextWithText text: String) {
        findInPageBar?.endEditing(true)
        find(text, function: "findNext")
    }

    func findInPage(_ findInPage: FindInPageBar, didFindPreviousWithText text: String) {
        findInPageBar?.endEditing(true)
        find(text, function: "findPrevious")
    }

    func findInPageDidPressClose(_ findInPage: FindInPageBar) {
        updateFindInPageVisibility(isVisible: false)
    }

    fileprivate func find(_ text: String, function: String) {
        guard let webView = tabManager.selectedTab?.webView else { return }
        let escaped = text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        webView.evaluateJavascriptInDefaultContentWorld("__firefox__.\(function)(\"\(escaped)\")")
    }

    func findInPageHelper(_ findInPageHelper: FindInPageHelper, didUpdateCurrentResult currentResult: Int) {
        findInPageBar?.currentResult = currentResult
    }

    func findInPageHelper(_ findInPageHelper: FindInPageHelper, didUpdateTotalResults totalResults: Int) {
        findInPageBar?.totalResults = totalResults
    }
}
