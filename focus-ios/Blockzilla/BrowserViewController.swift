/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit

class BrowserViewController: UIViewController {
    fileprivate let webView = UIWebView()
    fileprivate let browserToolbar = BrowserToolbar(frame: CGRect.zero)

    override func viewDidLoad() {
        super.viewDidLoad()

        let urlBarContainer = UIView()
        urlBarContainer.backgroundColor = UIConstants.colors.urlBarBackground

        let urlBar = URLBar(frame: CGRect.zero)
        urlBar.delegate = self

        browserToolbar.delegate = self
        webView.delegate = self

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

        view.addSubview(browserToolbar)
        browserToolbar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(view)
            make.height.equalTo(UIConstants.layout.browserToolbarHeight)
        }
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
        guard let url = URIFixup.getURL(entry: text) else {
            print("TODO: Search not yet supported.")
            return
        }

        webView.loadRequest(URLRequest(url: url))
    }
}

extension BrowserViewController: BrowserToolbarDelegate {
    func browserToolbarDidPressBack(browserToolbar: BrowserToolbar) {
        webView.goBack()
    }

    func browserToolbarDidPressForward(browserToolbar: BrowserToolbar) {
        webView.goForward()
    }

    func browserToolbarDidPressReload(browserToolbar: BrowserToolbar) {
        webView.reload()
    }

    func browserToolbarDidPressStop(browserToolbar: BrowserToolbar) {
        webView.stopLoading()
    }

    func browserToolbarDidPressSend(browserToolbar: BrowserToolbar) {
        print("TODO: Sending not yet supported.")
    }
}

extension BrowserViewController: UIWebViewDelegate {
    func webViewDidStartLoad(_ webView: UIWebView) {
        browserToolbar.isLoading = true
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        browserToolbar.isLoading = false
        updateToolbar()
    }

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        updateToolbar()
    }

    private func updateToolbar() {
        browserToolbar.canGoBack = webView.canGoBack
        browserToolbar.canGoForward = webView.canGoForward
    }
}
