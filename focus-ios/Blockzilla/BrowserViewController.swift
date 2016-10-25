/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit

class BrowserViewController: UIViewController {
    fileprivate var browser = Browser()
    fileprivate let browserToolbar = BrowserToolbar()
    fileprivate var homeView: HomeView?
    fileprivate let overlayView = OverlayView()
    fileprivate let searchEngine = SearchEngine()
    fileprivate let urlBarContainer = URLBarContainer()
    fileprivate var urlBar: URLBar!
    fileprivate var topURLBarConstraints = [Constraint]()

    private var homeViewContainer = UIView()
    private var browserSlideOffConstraints = [Constraint]()

    override func viewDidLoad() {
        super.viewDidLoad()

        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0.2, y: 0)
        gradient.endPoint = CGPoint(x: 0.8, y: 1)
        gradient.colors = [UIConstants.colors.homeGradientLeft.cgColor, UIConstants.colors.homeGradientMiddle.cgColor, UIConstants.colors.homeGradientRight.cgColor]
        let backgroundView = GradientBackgroundView(gradient: gradient)
        view.addSubview(backgroundView)

        urlBarContainer.alpha = 1
        view.addSubview(urlBarContainer)

        view.addSubview(homeViewContainer)

        browser.view.isHidden = true
        browser.bottomInset = UIConstants.layout.browserToolbarHeight
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

        backgroundView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }

        urlBarContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view)

            // Shrink the container to 0 height when there's no URL bar.
            // This will make it animate down from the top when the URL bar is added.
            make.height.equalTo(0).priority(500)
        }

        browserToolbar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(view)
            make.height.equalTo(UIConstants.layout.browserToolbarHeight)
        }

        homeViewContainer.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }

        browser.view.snp.makeConstraints { make in
            make.top.equalTo(urlBarContainer.snp.bottom).priority(500)
            make.bottom.equalTo(view).priority(500)
            make.leading.trailing.equalTo(view)

            browserSlideOffConstraints = [
                make.top.equalTo(view.snp.bottom).constraint,
                make.height.equalTo(view).constraint
            ]
        }
        browserSlideOffConstraints.forEach { $0.deactivate() }

        overlayView.snp.makeConstraints { make in
            make.top.equalTo(urlBarContainer.snp.bottom)
            make.leading.trailing.bottom.equalTo(view)
        }

        createHomeView()
        createURLBar()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }

    private func createHomeView() {
        let homeView = HomeView()
        homeView.delegate = self
        homeViewContainer.addSubview(homeView)

        homeView.snp.makeConstraints { make in
            make.edges.equalTo(homeViewContainer)
        }

        if let homeView = self.homeView {
            homeView.removeFromSuperview()
        }
        self.homeView = homeView
    }

    private func createURLBar() {
        urlBar = URLBar()
        urlBar.delegate = self
        view.insertSubview(urlBar, belowSubview: browser.view)

        urlBar.snp.makeConstraints { make in
            topURLBarConstraints = [
                make.top.equalTo(topLayoutGuide.snp.bottom).constraint,
                make.leading.trailing.bottom.equalTo(urlBarContainer).constraint
            ]

            // Initial centered constraints, which will effectively be deactivated when
            // the top constraints are active because of their reduced priorities.
            make.width.equalTo(view).multipliedBy(0.95).priority(500)
            make.center.equalTo(view).priority(500)
        }
        topURLBarConstraints.forEach { $0.deactivate() }
    }

    fileprivate func resetBrowser() {
        let oldURLBar = urlBar

        createHomeView()
        createURLBar()

        WebCacheUtils.reset()

        view.layoutIfNeeded()
        UIView.animate(withDuration: UIConstants.layout.deleteAnimationDuration, animations: {
            oldURLBar?.alpha = 0
            self.urlBarContainer.alpha = 0
            self.browserSlideOffConstraints.forEach { $0.activate() }
            self.view.layoutIfNeeded()
        }, completion: { finished in
            oldURLBar?.removeFromSuperview()
            self.browser.view.isHidden = true
            self.browser.reset()
            self.browserSlideOffConstraints.forEach { $0.deactivate() }
        })

        browserToolbar.animateHidden(true, duration: UIConstants.layout.toolbarFadeAnimationDuration)

        AdjustIntegration.track(eventName: .clear)
    }

    fileprivate func showSettings() {
        let settingsViewController = SettingsViewController()
        navigationController!.pushViewController(settingsViewController, animated: true)
        navigationController!.setNavigationBarHidden(false, animated: true)
    }

    fileprivate func submit(url: URL) {
        // If this is the first navigation, show the browser and the toolbar.
        if browser.view.isHidden {
            urlBar.showButtons = true
            browser.view.isHidden = false
            browserToolbar.animateHidden(false, duration: UIConstants.layout.toolbarFadeAnimationDuration)
            homeView?.removeFromSuperview()
            homeView = nil
        }

        browser.loadRequest(URLRequest(url: url))

        if searchEngine.isSearchURL(url: url) {
            AdjustIntegration.track(eventName: .search)
        } else {
            AdjustIntegration.track(eventName: .browse)
        }
    }
}

extension BrowserViewController: URLBarDelegate {
    func urlBar(urlBar: URLBar, didEnterText text: String) {
        overlayView.setSearchQuery(query: text, animated: true)
    }

    func urlBar(urlBar: URLBar, didSubmitText text: String) {
        let text = text.trimmingCharacters(in: .whitespaces)
        if !text.isEmpty, let url = URIFixup.getURL(entry: text) ?? searchEngine.urlForQuery(text) {
            submit(url: url)
            urlBar.dismiss()
        } else {
            urlBar.url = browser.url
        }
    }

    func urlBarDidDismiss(urlBar: URLBar) {
        overlayView.dismiss()
        urlBarContainer.isBright = !browser.isLoading
    }

    func urlBarDidPressDelete(urlBar: URLBar) {
        self.resetBrowser()
    }

    func urlBarDidFocus(urlBar: URLBar) {
        overlayView.present()
        urlBarContainer.isBright = false
    }

    func urlBarDidPressActivateButton(urlBar: URLBar) {
        UIView.animate(withDuration: UIConstants.layout.urlBarMoveToTopAnimationDuration) {
            self.view.bringSubview(toFront: self.urlBar)
            self.topURLBarConstraints.forEach { $0.activate() }
            self.urlBarContainer.alpha = 1
            self.view.layoutIfNeeded()
        }
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
        urlBarContainer.isBright = false
    }

    func browserDidFinishNavigation(_ browser: Browser) {
        browserToolbar.isLoading = false
        urlBarContainer.isBright = !urlBar.isEditing
    }

    func browser(_ browser: Browser, didFailNavigationWithError error: Error) {
        browserToolbar.isLoading = false
        urlBarContainer.isBright = true
    }

    func browser(_ browser: Browser, didUpdateCanGoBack canGoBack: Bool) {
        browserToolbar.canGoBack = canGoBack
    }

    func browser(_ browser: Browser, didUpdateCanGoForward canGoForward: Bool) {
        browserToolbar.canGoForward = canGoForward
    }

    func browser(_ browser: Browser, didUpdateEstimatedProgress estimatedProgress: Float) {
        // Don't update progress is the home view is visible. This prevents the centered URL bar
        // from catching the global progress events.
        guard homeView == nil else { return }

        if estimatedProgress == 0 {
            urlBar.progressBar.progress = 0
            urlBar.progressBar.animateHidden(false, duration: UIConstants.layout.progressVisibilityAnimationDuration)
            return
        }

        urlBar.progressBar.setProgress(estimatedProgress, animated: true)

        if estimatedProgress == 1 {
            urlBar.progressBar.animateHidden(true, duration: UIConstants.layout.progressVisibilityAnimationDuration)
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
        guard homeView == nil else { return }
        urlBar.dismiss()
    }

    func overlayView(_ overlayView: OverlayView, didSearchForQuery query: String) {
        if let url = searchEngine.urlForQuery(query) {
            submit(url: url)
        }
        urlBar.dismiss()
    }
}
