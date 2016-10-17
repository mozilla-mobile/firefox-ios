/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit

private let SearchTemplate = "https://duckduckgo.com/?q=%s"

class BrowserViewController: UIViewController {
    fileprivate let browser = Browser()
    fileprivate let urlBar = URLBar()
    fileprivate let browserToolbar = BrowserToolbar()
    fileprivate let progressBar = UIProgressView(progressViewStyle: .bar)
    fileprivate var homeView: HomeView?

    override func viewDidLoad() {
        super.viewDidLoad()

        let urlBarContainer = URLBarContainer()
        view.addSubview(urlBarContainer)

        urlBarContainer.addSubview(urlBar)
        urlBar.focus()
        urlBar.delegate = self

        view.addSubview(browser.view)
        browser.delegate = self

        view.addSubview(progressBar)
        progressBar.progressTintColor = UIConstants.colors.progressBar

        view.addSubview(browserToolbar)
        browserToolbar.delegate = self

        let homeView = HomeView()
        self.homeView = homeView
        view.addSubview(homeView)
        homeView.delegate = self

        urlBarContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self.view)
        }

        UIView.animate(withDuration: 0.5) {
            self.urlBar.snp.makeConstraints { make in
                make.top.equalTo(self.topLayoutGuide.snp.bottom)
                make.leading.trailing.bottom.equalTo(urlBarContainer)
            }
            self.urlBar.layoutIfNeeded()
        }

        progressBar.snp.makeConstraints { make in
            make.centerY.equalTo(urlBarContainer.snp.bottom)
            make.leading.trailing.equalTo(self.view)
            make.height.equalTo(1)
        }

        browser.view.snp.makeConstraints { make in
            make.top.equalTo(urlBar.snp.bottom)
            make.leading.trailing.bottom.equalTo(view)
        }

        browserToolbar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(view)
            make.height.equalTo(UIConstants.layout.browserToolbarHeight)
        }

        homeView.snp.makeConstraints { make in
            make.edges.equalTo(browser.view)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }
}

extension BrowserViewController: URLBarDelegate {
    func urlBar(urlBar: URLBar, didSubmitText text: String) {
        var url = URIFixup.getURL(entry: text)

        if url == nil {
            guard let escaped = text.addingPercentEncoding(withAllowedCharacters: .urlQueryParameterAllowed),
                  let searchUrl = URL(string: SearchTemplate.replacingOccurrences(of: "%s", with: escaped)) else {
                assertionFailure("Invalid search URL")
                return
            }

            url = searchUrl
        }

        browser.loadRequest(URLRequest(url: url!))
    }

    func urlBarDidCancel(urlBar: URLBar) {
        urlBar.url = browser.url
    }
}

extension BrowserViewController: BrowserToolbarDelegate {
    func browserToolbarDidPressBack(browserToolbar: BrowserToolbar) {
        browser.goBack()
    }

    func browserToolbarDidPressForward(browserToolbar: BrowserToolbar) {
        browser.goForward()
    }

    func browserToolbarDidPressReload(browserToolbar: BrowserToolbar) {
        browser.reload()
    }

    func browserToolbarDidPressStop(browserToolbar: BrowserToolbar) {
        browser.stop()
    }

    func browserToolbarDidPressSend(browserToolbar: BrowserToolbar) {
        guard let url = browser.url else { return }
        OpenUtils.openInExternalBrowser(url: url)
    }
}

extension BrowserViewController: BrowserDelegate {
    func browserDidStartNavigation(_ browser: Browser) {
        browserToolbar.isLoading = true

        // Remove the initial view once we start navigating.
        if let homeView = homeView {
            homeView.removeFromSuperview()
            self.homeView = nil
        }
    }

    func browserDidFinishNavigation(_ browser: Browser) {
        browserToolbar.isLoading = false
    }

    func browser(_ browser: Browser, didFailNavigationWithError error: Error) {
        browserToolbar.isLoading = false
    }

    func browser(_ browser: Browser, didUpdateCanGoBack canGoBack: Bool) {
        browserToolbar.canGoBack = canGoBack
    }

    func browser(_ browser: Browser, didUpdateCanGoForward canGoForward: Bool) {
        browserToolbar.canGoForward = canGoForward
    }

    func browser(_ browser: Browser, didUpdateEstimatedProgress estimatedProgress: Float) {
        if estimatedProgress == 0 {
            progressBar.progress = 0
            progressBar.animateHidden(false, duration: 0.3)
            return
        }

        progressBar.setProgress(estimatedProgress, animated: true)

        if estimatedProgress == 1 {
            progressBar.animateHidden(true, duration: 0.3)
        }
    }

    func browser(_ browser: Browser, didUpdateURL url: URL?) {
        urlBar.url = url
    }
}

extension BrowserViewController: HomeViewDelegate {
    func homeViewDidPressSettings(homeView: HomeView) {
        let settingsViewController = SettingsViewController()
        navigationController!.pushViewController(settingsViewController, animated: true)
        navigationController!.setNavigationBarHidden(false, animated: true)
    }
}
