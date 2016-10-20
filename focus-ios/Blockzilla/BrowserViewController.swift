/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit

class BrowserViewController: UIViewController {
    fileprivate var browser = Browser()
    fileprivate let urlBar = URLBar()
    fileprivate let browserToolbar = BrowserToolbar()
    fileprivate var homeView = HomeView()
    fileprivate let overlayView = OverlayView()
    fileprivate let searchEngine = SearchEngine()

    private let urlBarContainer = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIConstants.colors.background

        let urlBarBackground = GradientBackgroundView()
        urlBarContainer.addSubview(urlBarBackground)
        view.addSubview(urlBarContainer)

        urlBar.focus()
        urlBar.delegate = self
        urlBarContainer.addSubview(urlBar)

        homeView.delegate = self
        view.addSubview(homeView)

        browser.view.isHidden = true
        browser.delegate = self
        view.addSubview(browser.view)

        browserToolbar.isHidden = true
        browserToolbar.alpha = 0
        browserToolbar.delegate = self
        browserToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(browserToolbar)

        overlayView.isHidden = true
        overlayView.alpha = 0
        overlayView.delegate = self
        overlayView.backgroundColor = UIConstants.colors.overlayBackground
        view.addSubview(overlayView)

        urlBarContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view)
        }

        urlBarBackground.snp.makeConstraints { make in
            make.edges.equalTo(urlBarContainer)
        }

        urlBar.snp.makeConstraints { make in
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.leading.trailing.bottom.equalTo(urlBarContainer)
        }

        browserToolbar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(view)
            make.height.equalTo(UIConstants.layout.browserToolbarHeight)
        }

        homeView.snp.makeConstraints { make in
            make.top.equalTo(urlBarContainer.snp.bottom)
            make.leading.trailing.bottom.equalTo(view)
        }

        browser.view.snp.makeConstraints { make in
            make.top.equalTo(urlBarContainer.snp.bottom)
            make.leading.trailing.bottom.equalTo(view)
        }

        overlayView.snp.makeConstraints { make in
            make.top.equalTo(urlBarContainer.snp.bottom)
            make.leading.trailing.bottom.equalTo(view)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }

    fileprivate func resetBrowser() {
        urlBar.url = nil
        urlBar.progressBar.isHidden = true

        view.layoutIfNeeded()
        UIView.animate(withDuration: UIConstants.layout.deleteAnimationDuration, animations: {
            self.browser.view.snp.remakeConstraints { make in
                make.leading.trailing.equalTo(self.view)
                make.height.equalTo(self.view)
                make.top.equalTo(self.view.snp.bottom)
            }

            self.view.layoutIfNeeded()
        }, completion: { finished in
            self.browser.view.isHidden = true
            self.browser.reset()

            self.browser.view.snp.remakeConstraints { make in
                make.top.equalTo(self.urlBarContainer.snp.bottom)
                make.leading.trailing.bottom.equalTo(self.view)
            }

            self.urlBar.focus()
        })

        browserToolbar.animateHidden(true, duration: UIConstants.layout.toolbarFadeAnimationDuration)
    }

    fileprivate func showSettings() {
        let settingsViewController = SettingsViewController()
        navigationController!.pushViewController(settingsViewController, animated: true)
        navigationController!.setNavigationBarHidden(false, animated: true)
    }

    fileprivate func submit(url: URL) {
        // If this is the first navigation, show the browser and the toolbar.
        if browser.view.isHidden {
            browser.view.isHidden = false
            browserToolbar.animateHidden(false, duration: UIConstants.layout.toolbarFadeAnimationDuration)
        }

        browser.loadRequest(URLRequest(url: url))
    }
}

extension BrowserViewController: URLBarDelegate {
    func urlBar(urlBar: URLBar, didEnterText text: String) {
        overlayView.setSearchQuery(query: text, animated: true)
    }

    func urlBar(urlBar: URLBar, didSubmitText text: String) {
        urlBar.dismiss()

        let text = text.trimmingCharacters(in: .whitespaces)
        if !text.isEmpty, let url = URIFixup.getURL(entry: text) ?? searchEngine.urlForQuery(text) {
            submit(url: url)
        } else {
            urlBar.url = browser.url
        }
    }

    func urlBarDidDismiss(urlBar: URLBar) {
        overlayView.dismiss()
    }

    func urlBarDidPressDelete(urlBar: URLBar) {
        self.resetBrowser()
    }

    func urlBarDidFocus(urlBar: URLBar) {
        overlayView.present()
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
            urlBar.progressBar.progress = 0
            urlBar.progressBar.animateHidden(false, duration: 0.3)
            return
        }

        urlBar.progressBar.setProgress(estimatedProgress, animated: true)

        if estimatedProgress == 1 {
            urlBar.progressBar.animateHidden(true, duration: 0.3)
        }
    }

    func browser(_ browser: Browser, didUpdateURL url: URL?) {
        urlBar.url = url
    }
}

extension BrowserViewController: HomeViewDelegate {
    func homeViewDidPressSettings(homeView: HomeView) {
        showSettings()
    }
}

extension BrowserViewController: OverlayViewDelegate {
    func overlayViewDidPressSettings(_ overlayView: OverlayView) {
        showSettings()
    }

    func overlayViewDidTouchEmptyArea(_ overlayView: OverlayView) {
        urlBar.dismiss()
    }

    func overlayView(_ overlayView: OverlayView, didSearchForQuery query: String) {
        urlBar.dismiss()
        if let url = searchEngine.urlForQuery(query) {
            submit(url: url)
        }
    }
}
