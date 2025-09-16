// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol OverlayStateProtocol {
    var inOverlayMode: Bool { get }
}

/// Overlay mode (aka attentive mode) refers to when the URL bar is focused and in the editing state
protocol OverlayModeManager: OverlayStateProtocol {
    /// Set URLBar which is not available when the manager is created
    /// - Parameter urlBarView: URLBar that contains textfield which open and dismiss the keyboard
    func setURLBar(urlBarView: URLBarViewProtocol)

    /// Enter overlay mode with paste content
    /// - Parameter pasteContent: String with the content to paste on the search
    func openSearch(with pasteContent: String)

    /// Enter overlay mode when opening a new tab
    /// - Parameters:
    ///   - url: Tab url to determine if is the url is homepage or nil
    ///   - newTabSettings: User option for new tab, if it's a custom url (homepage) the keyboard is not raised
    func openNewTab(url: URL?, newTabSettings: NewTabPage)

    /// Leave overlay mode when the user finishes editing. This is called when
    /// the user commits their edits, either by tapping "go" / Enter on the
    /// keyboard, or by tapping on a suggestion in the search view.
    /// - Parameter shouldCancelLoading: Bool value determine if the loading animation of the current
    ///                                  search should be canceled
    func finishEditing(shouldCancelLoading: Bool)

    /// Leave overlay mode when the user cancels editing. This is called when
    /// the user dismisses the search view without committing their edits.
    /// - Parameter shouldCancelLoading: Bool value determine if the loading animation of the current
    ///                                  search should be canceled
    func cancelEditing(shouldCancelLoading: Bool)

    /// Leave overlay mode when tab change happens, like switching tabs or open a site from any homepage section
    /// - Parameter shouldCancelLoading: Bool value determine if the loading animation of the current
    ///                                  search should be canceled
    func switchTab(shouldCancelLoading: Bool)
}

class DefaultOverlayModeManager: OverlayModeManager {
    private var urlBarView: URLBarViewProtocol?

    var inOverlayMode: Bool {
        return urlBarView?.inOverlayMode ?? false
    }

    init() {}

    func setURLBar(urlBarView: URLBarViewProtocol) {
        self.urlBarView = urlBarView
    }

    func openSearch(with pasteContent: String) {
        enterOverlayMode(pasteContent, pasted: true, search: true)
    }

    func openNewTab(url: URL?, newTabSettings: NewTabPage) {
        guard shouldEnterOverlay(for: url, newTabSettings: newTabSettings) else { return }

        enterOverlayMode(nil, pasted: false, search: true)
    }

    func finishEditing(shouldCancelLoading: Bool) {
        guard inOverlayMode else { return }
        leaveOverlayMode(reason: .finished, shouldCancelLoading: shouldCancelLoading)
    }

    func cancelEditing(shouldCancelLoading: Bool) {
        leaveOverlayMode(reason: .cancelled, shouldCancelLoading: shouldCancelLoading)
    }

    func switchTab(shouldCancelLoading: Bool) {
        guard inOverlayMode else { return }

        leaveOverlayMode(reason: .finished, shouldCancelLoading: shouldCancelLoading)
    }

    private func shouldEnterOverlay(for url: URL?, newTabSettings: NewTabPage) -> Bool {
        // The NewTabPage cases are weird topSites = homepage
        // and homepage = customURL
        switch newTabSettings {
        case .topSites: return url?.isFxHomeUrl ?? true
        case .blankPage: return true
        case .homePage: return false
        }
    }

    private func enterOverlayMode(_ locationText: String?, pasted: Bool, search: Bool) {
        urlBarView?.enterOverlayMode(locationText, pasted: pasted, search: search)
    }

    private func leaveOverlayMode(reason: URLBarLeaveOverlayModeReason, shouldCancelLoading cancel: Bool) {
        urlBarView?.leaveOverlayMode(reason: reason, shouldCancelLoading: cancel)
    }
}
