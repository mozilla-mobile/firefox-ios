// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol OverlayStateProtocol {
    var inOverlayMode: Bool { get }
}

protocol OverlayModeManager: OverlayStateProtocol {
    /// Set URLBar which is not available when the manager is created
    /// - Parameter urlBarView: URLBar that contains textfield which open and dismiss the keyboard
    func setURLBar(urlBarView: URLBarViewProtocol)

    /// Enter overlay mode with paste content
    /// - Parameter pasteContent: String with the content to paste on the search
    func openSearch(with pasteContent: String)

    /// Enter overlay mode when opening a new tab
    /// - Parameters:
    ///   - locationText: String with initial search text
    ///   - url: Tab url to determine if is the url is homepage or nil
    func openNewTab(_ locationText: String?, url: URL?)

    /// Leave overlay mode when user finish edition, either pressing the go button, enter etc
    /// - Parameter shouldCancelLoading: Bool value determine if the loading animation of the current search should be canceled
    func finishEdition(shouldCancelLoading: Bool)

    /// Leave overlay mode when tab change happens, like switching tabs or open a site from any homepage section
    /// - Parameter shouldCancelLoading: Bool value determine if the loading animation of the current search should be canceled
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

    func openNewTab(_ locationText: String?, url: URL?) {
        if url == nil || url?.isFxHomeUrl ?? false {
            enterOverlayMode(locationText, pasted: false, search: true)
        }
    }

    func finishEdition(shouldCancelLoading: Bool) {
        leaveOverlayMode(didCancel: shouldCancelLoading)
    }

    func switchTab(shouldCancelLoading: Bool) {
        leaveOverlayMode(didCancel: shouldCancelLoading)
    }

    private func enterOverlayMode(_ locationText: String?, pasted: Bool, search: Bool) {
        urlBarView?.enterOverlayMode(locationText, pasted: pasted, search: search)
    }

    private func leaveOverlayMode(didCancel cancel: Bool) {
        urlBarView?.leaveOverlayMode(didCancel: cancel)
    }
}
