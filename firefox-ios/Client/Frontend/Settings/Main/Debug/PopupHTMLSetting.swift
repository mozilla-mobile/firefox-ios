// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

class PopupHTMLSetting: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Show Popup HTML")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let url = Bundle.main.url(forResource: "testPopUp.html", withExtension: nil)
        guard let url else { return }
        settings.tabManager?.selectedTab?.webView?.load(PrivilegedRequest(url: url) as URLRequest)
        settings.dismiss(animated: true)
    }
}
