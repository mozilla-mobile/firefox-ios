// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol OverlayModeManager {
    var inOverlayMode: Bool { get }
    func enterOverlayMode(_ locationText: String?, pasted: Bool, search: Bool)
    func leaveOverlayMode(didCancel cancel: Bool)
}

extension OverlayModeManager {
    func enterOverlayMode(_ locationText: String? = nil, pasted: Bool = false, search: Bool = true) {
        enterOverlayMode(locationText, pasted: pasted, search: search)
    }

    func leaveOverlayMode(didCancel cancel: Bool = false) {
        leaveOverlayMode(didCancel: cancel)
    }
}

class DefaultOverlayModeManager: OverlayModeManager {
    private var urlBarView: URLBarViewProtocol

    var inOverlayMode: Bool {
        return urlBarView.inOverlayMode
    }

    init(urlBarView: URLBarViewProtocol) {
        self.urlBarView = urlBarView
    }

    func enterOverlayMode(_ locationText: String?, pasted: Bool, search: Bool) {
        guard !inOverlayMode else { return }

        urlBarView.enterOverlayMode(locationText, pasted: pasted, search: search)
    }

    func leaveOverlayMode(didCancel cancel: Bool) {
        guard inOverlayMode else { return }

        urlBarView.leaveOverlayMode(didCancel: cancel)
    }
}
