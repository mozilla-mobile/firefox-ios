/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit

class BrowserViewController: UIViewController {
    let webView = UIWebView()

    override func viewDidLoad() {
        super.viewDidLoad()

        let urlBarContainer = UIView()
        urlBarContainer.backgroundColor = UIConstants.colors.urlBarBackground

        let urlBar = URLBar(frame: CGRect.zero)

        view.addSubview(urlBarContainer)
        urlBarContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self.view)
        }

        urlBarContainer.addSubview(urlBar)
        urlBar.snp.makeConstraints { make in
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.leading.trailing.bottom.equalTo(urlBarContainer)
        }

        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.top.equalTo(urlBar.snp.bottom)
            make.leading.trailing.bottom.equalTo(view)
        }

        urlBar.delegate = self
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func settingsClicked() {
        let settingsViewController = SettingsViewController()
        present(settingsViewController, animated: true, completion: nil)
    }
}

extension BrowserViewController: URLBarDelegate {
    func urlBar(urlBar: URLBar, didSubmitText text: String) {
        let url = "http://" + text
        webView.loadRequest(URLRequest(url: URL(string: url)!))
    }
}
