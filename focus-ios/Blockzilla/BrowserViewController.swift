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
    private var showsToolsetInURLBar = false

    override func viewDidLoad() {
        super.viewDidLoad()

        showsToolsetInURLBar = UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.orientation.isLandscape

        let background = GradientBackgroundView(alpha: 0.6, startPoint: CGPoint.zero, endPoint: CGPoint(x: 1, y: 1))
        view.addSubview(background)

        view.addSubview(homeViewContainer)

        urlBarContainer.alpha = 0
        view.addSubview(urlBarContainer)

        browser.view.isHidden = true
        browser.bottomInset = showsToolsetInURLBar ? 0 : UIConstants.layout.browserToolbarHeight
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

        background.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }

        urlBarContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view)
            make.height.equalTo(view).multipliedBy(0.6).priority(500)
        }

        browserToolbar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(view)
            make.height.equalTo(UIConstants.layout.browserToolbarHeight)
        }

        homeViewContainer.snp.makeConstraints { make in
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.leading.trailing.bottom.equalTo(view)
        }

        browser.view.snp.makeConstraints { make in
            make.top.equalTo(urlBarContainer.snp.bottom).priority(500)
            make.bottom.equalTo(view).priority(500)
            make.leading.trailing.equalTo(view)
        }

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
        guard let homeView = homeView else {
            assertionFailure("Home view must exist to create the URL bar")
            return
        }

        urlBar = URLBar()
        urlBar.delegate = self
        urlBar.toolsetDelegate = self
        urlBar.shrinkFromView = urlBarContainer
        urlBar.showToolset = showsToolsetInURLBar
        view.insertSubview(urlBar, belowSubview: browser.view)

        urlBar.snp.makeConstraints { make in
            topURLBarConstraints = [
                make.top.equalTo(topLayoutGuide.snp.bottom).constraint,
                make.leading.trailing.bottom.equalTo(urlBarContainer).constraint
            ]

            // Initial centered constraints, which will effectively be deactivated when
            // the top constraints are active because of their reduced priorities.
            make.width.equalTo(view).multipliedBy(0.95).priority(500)
            make.center.equalTo(homeView).priority(500)
        }
        topURLBarConstraints.forEach { $0.deactivate() }
    }

    fileprivate func resetBrowser() {
        // Screenshot the browser, showing the screenshot on top.
        let image = view.screenshot()
        let screenshotView = UIImageView(image: image)
        view.addSubview(screenshotView)
        screenshotView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }

        // Reset the views. These changes won't be immediately visible since they'll be under the screenshot.
        browser.reset()
        browser.view.isHidden = true
        browserToolbar.isHidden = true
        urlBar.removeFromSuperview()
        urlBarContainer.alpha = 0
        createHomeView()
        createURLBar()

        // Clear the cache and cookies, starting a new session.
        WebCacheUtils.reset()

        // Zoom out on the screenshot, then slide down, then remove it.
        view.layoutIfNeeded()
        UIView.animate(withDuration: UIConstants.layout.deleteAnimationDuration, animations: {
            screenshotView.snp.remakeConstraints { make in
                make.center.equalTo(self.view)
                make.size.equalTo(self.view).multipliedBy(0.9)
            }
            self.view.layoutIfNeeded()
        }, completion: { _ in
            UIView.animate(withDuration: UIConstants.layout.deleteAnimationDuration / 2, animations: {
                screenshotView.snp.remakeConstraints { make in
                    make.centerX.equalTo(self.view)
                    make.top.equalTo(self.view.snp.bottom)
                    make.size.equalTo(self.view).multipliedBy(0.9)
                }
                self.view.layoutIfNeeded()
            }, completion: { _ in
                Toast(text: UIConstants.strings.eraseMessage).show()
                screenshotView.removeFromSuperview()
            })
        })

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
            browser.view.isHidden = false
            homeView?.removeFromSuperview()
            homeView = nil
            urlBar.inBrowsingMode = true

            if !showsToolsetInURLBar {
                browserToolbar.animateHidden(false, duration: UIConstants.layout.toolbarFadeAnimationDuration)
            }
        }

        browser.loadRequest(URLRequest(url: url))
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        guard UIDevice.current.userInterfaceIdiom == .phone else { return }

        // UIDevice.current.orientation isn't reliable. See https://bugzilla.mozilla.org/show_bug.cgi?id=1315370#c5
        // As a workaround, consider the phone to be in landscape if the new width is greater than the height.
        showsToolsetInURLBar = size.width > size.height

        coordinator.animate(alongsideTransition: { _ in
            self.urlBar.showToolset = self.showsToolsetInURLBar
            self.browserToolbar.animateHidden(self.homeView != nil || self.showsToolsetInURLBar, duration: coordinator.transitionDuration)
            self.browser.bottomInset = self.showsToolsetInURLBar ? 0 : UIConstants.layout.browserToolbarHeight
        })
    }
}

extension BrowserViewController: URLBarDelegate {
    func urlBar(_ urlBar: URLBar, didEnterText text: String) {
        overlayView.setSearchQuery(query: text, animated: true)
    }

    func urlBar(_ urlBar: URLBar, didSubmitText text: String) {
        let text = text.trimmingCharacters(in: .whitespaces)

        guard !text.isEmpty else {
            urlBar.url = browser.url
            return
        }

        var url = URIFixup.getURL(entry: text)
        if url == nil {
            AdjustIntegration.track(eventName: .search)
            url = searchEngine.urlForQuery(text)
        } else {
            AdjustIntegration.track(eventName: .browse)
        }

        submit(url: url!)
        urlBar.url = url
        urlBar.dismiss()
    }

    func urlBarDidDismiss(_ urlBar: URLBar) {
        overlayView.dismiss()
        urlBarContainer.isBright = !browser.isLoading
    }

    func urlBarDidPressDelete(_ urlBar: URLBar) {
        self.resetBrowser()
    }

    func urlBarDidFocus(_ urlBar: URLBar) {
        overlayView.present()
        urlBarContainer.isBright = false
    }

    func urlBarDidActivate(_ urlBar: URLBar) {
        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration) {
            self.topURLBarConstraints.forEach { $0.activate() }
            self.urlBarContainer.alpha = 1
            self.view.layoutIfNeeded()
        }
    }

    func urlBarDidDeactivate(_ urlBar: URLBar) {
        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration) {
            self.topURLBarConstraints.forEach { $0.deactivate() }
            self.urlBarContainer.alpha = 0
            self.view.layoutIfNeeded()
        }
    }
}

extension BrowserViewController: BrowserToolsetDelegate {
    func browserToolsetDidPressBack(_ browserToolset: BrowserToolset) {
        urlBar.dismiss()
        browser.goBack()
    }

    func browserToolsetDidPressForward(_ browserToolset: BrowserToolset) {
        urlBar.dismiss()
        browser.goForward()
    }

    func browserToolsetDidPressReload(_ browserToolset: BrowserToolset) {
        urlBar.dismiss()
        browser.reload()
    }

    func browserToolsetDidPressStop(_ browserToolset: BrowserToolset) {
        urlBar.dismiss()
        browser.stop()
    }

    func browserToolsetDidPressSend(_ browserToolset: BrowserToolset) {
        urlBar.dismiss()
        guard let url = browser.url else { return }
        OpenUtils.openInExternalBrowser(url: url)
    }

    func browserToolsetDidPressSettings(_ browserToolbar: BrowserToolset) {
        showSettings()
    }
}

extension BrowserViewController: BrowserDelegate {
    func browserDidStartNavigation(_ browser: Browser) {
        urlBar.isLoading = true
        browserToolbar.isLoading = true
        urlBarContainer.isBright = false
    }

    func browserDidFinishNavigation(_ browser: Browser) {
        urlBar.isLoading = false
        browserToolbar.isLoading = false
        urlBarContainer.isBright = !urlBar.isEditing
    }

    func browser(_ browser: Browser, didFailNavigationWithError error: Error) {
        urlBar.isLoading = false
        browserToolbar.isLoading = false
        urlBarContainer.isBright = true
    }

    func browser(_ browser: Browser, didUpdateCanGoBack canGoBack: Bool) {
        urlBar.canGoBack = canGoBack
        browserToolbar.canGoBack = canGoBack
    }

    func browser(_ browser: Browser, didUpdateCanGoForward canGoForward: Bool) {
        urlBar.canGoForward = canGoForward
        browserToolbar.canGoForward = canGoForward
    }

    func browser(_ browser: Browser, didUpdateEstimatedProgress estimatedProgress: Float) {
        // Don't update progress if the home view is visible. This prevents the centered URL bar
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
        urlBar.dismiss()
    }

    func overlayView(_ overlayView: OverlayView, didSearchForQuery query: String) {
        if let url = searchEngine.urlForQuery(query) {
            AdjustIntegration.track(eventName: .search)
            submit(url: url)
        }

        urlBar.dismiss()
    }
}
