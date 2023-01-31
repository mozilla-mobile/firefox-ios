// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class OverlayModeManager {
    private var urlBarView: URLBarViewProtocol
    private var profile: Profile
    // We need to know if homepage is showing because is a new search or just returning to an existing homepage
    // Raise the keyboard for the first one

    init(urlBarView: URLBarViewProtocol,
         profile: Profile) {
        self.urlBarView = urlBarView
        self.profile
    }

    // Depending on the Setting for new Search the new tab can be defined to be:
    // blank, homepage or custom URL
    func openNewSearch(didChangePanelSelection: Bool, didAddNewTab: Bool ) {
        // Make sure is taken care https://mozilla-hub.atlassian.net/browse/FXIOS-4018
        guard NewTabAccessors.getNewTabPage(self.profile.prefs) == .blankPage else { return }

        enterOverlayMode(nil, pasted: false, search: false)
    }

    func changeTab() {
        leaveOverlayMode(didCancel: true)
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
