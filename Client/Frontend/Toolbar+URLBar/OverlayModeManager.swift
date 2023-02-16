// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol OverlayStateProtocol {
    var inOverlayMode: Bool { get }
}

protocol OverlayModeManager: OverlayStateProtocol {
    func setURLBar(urlBarView: URLBarViewProtocol)
    func pasteContent(pasteContent: String)
    func openNewTab(_ locationText: String?, url: URL?)
    func finishEdition(didCancel: Bool)
    func switchTab(didCancel: Bool)
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

    func finishEdition(didCancel: Bool) {
        leaveOverlayMode(didCancel: didCancel)
    }

    func pasteContent(pasteContent: String) {
        enterOverlayMode(pasteContent, pasted: true, search: true)
    }

    func openNewTab(_ locationText: String?, url: URL?) {
        if url == nil || url?.isFxHomeUrl ?? false {
            enterOverlayMode(locationText, pasted: false, search: true)
        }
    }

    func switchTab(didCancel: Bool) {
        leaveOverlayMode(didCancel: didCancel)
    }

    private func enterOverlayMode(_ locationText: String?, pasted: Bool, search: Bool) {
        urlBarView?.enterOverlayMode(locationText, pasted: pasted, search: search)
    }

    private func leaveOverlayMode(didCancel cancel: Bool) {
        urlBarView?.leaveOverlayMode(didCancel: cancel)
    }
}
