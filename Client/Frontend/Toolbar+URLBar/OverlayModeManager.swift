// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class OverlayModeManager {
    private var urlBarView: URLBarViewProtocol

    init(urlBarView: URLBarViewProtocol) {
        self.urlBarView = urlBarView
    }

    func openNewHomepage() {
        enterOverlayMode(nil, pasted: false, search: false)
    }

    func changeTab() {
        if urlBarView.inOverlayMode {
            leaveOverlayMode(didCancel: true)
        }
    }

    // MARK: - Private

    private func enterOverlayMode(_ locationText: String?, pasted: Bool, search: Bool) {
        guard !urlBarView.inOverlayMode else { return }

        print("YRD Mgr enterOverlay")
        urlBarView.enterOverlayMode(locationText, pasted: pasted, search: search)
    }

    private func leaveOverlayMode(didCancel cancel: Bool) {
        guard urlBarView.inOverlayMode else { return }

        print("YRD Mgr leaveOverlayMode")
        urlBarView.leaveOverlayMode(didCancel: cancel)
    }
}
