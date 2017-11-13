/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Telemetry

class BrowserViewController: UIViewController {
    private class DrawerView: UIView {
        override var intrinsicContentSize: CGSize { return CGSize(width: 320, height: 0) }
    }

    private let mainContainerView = UIView(frame: .zero)
    private let drawerContainerView = DrawerView(frame: .zero)
    private let drawerOverlayView = UIView()
    
    private let webViewController = WebViewController()
    private let webViewContainer = UIView()

    private let trackingProtectionSummaryController = TrackingProtectionSummaryViewController()

    fileprivate let browserToolbar = BrowserToolbar()
    fileprivate var homeView: HomeView?
    fileprivate let overlayView = OverlayView()
    fileprivate let searchEngineManager = SearchEngineManager(prefs: UserDefaults.standard)
    fileprivate let urlBarContainer = URLBarContainer()
    fileprivate var urlBar: URLBar!
    fileprivate var topURLBarConstraints = [Constraint]()
    fileprivate let requestHandler = RequestHandler()

    fileprivate var drawerConstraint: Constraint!
    fileprivate var toolbarBottomConstraint: Constraint!
    fileprivate var urlBarTopConstraint: Constraint!
    fileprivate var homeViewBottomConstraint: Constraint!
    fileprivate var browserBottomConstraint: Constraint!
    fileprivate var lastScrollOffset = CGPoint.zero
    fileprivate var lastScrollTranslation = CGPoint.zero
    fileprivate var scrollBarOffsetAlpha: CGFloat = 0
    fileprivate var scrollBarState: URLBarScrollState = .expanded

    fileprivate enum URLBarScrollState {
        case collapsed
        case expanded
        case transitioning
        case animating
    }

    private var trackingProtectionStatus: TrackingProtectionStatus = .on(TrackingInformation()) {
        didSet {
            trackingProtectionSummaryController.trackingProtectionStatus = trackingProtectionStatus
            urlBar.updateTrackingProtectionBadge(trackingStatus: trackingProtectionStatus)
        }
    }

    private var homeViewContainer = UIView()

    fileprivate var showsToolsetInURLBar = false {
        didSet {
            if showsToolsetInURLBar {
                browserBottomConstraint.deactivate()
            } else {
                browserBottomConstraint.activate()
            }
        }
    }

    private var shouldEnsureBrowsingMode = false
    private var initialUrl: URL?

    convenience init() {
        self.init(nibName: nil, bundle: nil)
        drawerContainerView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        KeyboardHelper.defaultHelper.addDelegate(delegate: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(mainContainerView)
        view.addSubview(drawerContainerView)

        drawerOverlayView.backgroundColor = UIColor(white: 0, alpha: 0.8)
        drawerOverlayView.layer.opacity = 0
        drawerOverlayView.isHidden = true
        drawerOverlayView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideDrawer)))
        view.addSubview(drawerOverlayView)
        drawerOverlayView.snp.makeConstraints { make in
            make.edges.equalTo(mainContainerView.snp.edges)
        }

        mainContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            make.bottom.equalToSuperview()
            make.leading.equalTo(drawerContainerView.snp.trailing)
        }

        drawerContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.lessThanOrEqualTo(320)
            make.trailing.lessThanOrEqualToSuperview().offset(-55)
            make.trailing.equalTo(view.snp.leading).priority(500)

            self.drawerConstraint = make.leading.equalToSuperview().constraint
        }
        self.drawerConstraint.deactivate()

        trackingProtectionSummaryController.delegate = self
        containTrackingProtectionSummary()

        webViewController.delegate = self

        let background = GradientBackgroundView(alpha: 0.7, startPoint: CGPoint.zero, endPoint: CGPoint(x: 1, y: 1))
        mainContainerView.addSubview(background)

        mainContainerView.addSubview(homeViewContainer)

        webViewContainer.isHidden = true
        mainContainerView.addSubview(webViewContainer)

        urlBarContainer.alpha = 0
        mainContainerView.addSubview(urlBarContainer)

        browserToolbar.isHidden = true
        browserToolbar.alpha = 0
        browserToolbar.delegate = self
        browserToolbar.translatesAutoresizingMaskIntoConstraints = false
        mainContainerView.addSubview(browserToolbar)

        overlayView.isHidden = true
        overlayView.alpha = 0
        overlayView.delegate = self
        overlayView.backgroundColor = UIConstants.colors.overlayBackground
        mainContainerView.addSubview(overlayView)

        background.snp.makeConstraints { make in
            make.edges.equalTo(mainContainerView)
        }

        urlBarContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(mainContainerView)
            make.height.equalTo(mainContainerView).multipliedBy(0.6).priority(500)
        }

        browserToolbar.snp.makeConstraints { make in

            make.leading.trailing.equalTo(mainContainerView)
            toolbarBottomConstraint = make.bottom.equalTo(mainContainerView).constraint
        }

        homeViewContainer.snp.makeConstraints { make in
            make.top.equalTo(mainContainerView.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalTo(mainContainerView)
            homeViewBottomConstraint = make.bottom.equalTo(mainContainerView).constraint
            homeViewBottomConstraint.activate()
        }

        webViewContainer.snp.makeConstraints { make in
            make.top.equalTo(urlBarContainer.snp.bottom).priority(500)
            make.bottom.equalTo(mainContainerView).priority(500)
            browserBottomConstraint = make.bottom.equalTo(browserToolbar.snp.top).priority(1000).constraint

            if !showsToolsetInURLBar {
                browserBottomConstraint.activate()
            }

            make.leading.trailing.equalTo(mainContainerView)
        }

        overlayView.snp.makeConstraints { make in
            make.top.equalTo(urlBarContainer.snp.bottom)
            make.leading.trailing.bottom.equalTo(mainContainerView)
        }

        // true if device is an iPad or is an iPhone in landscape mode
        showsToolsetInURLBar = (UIDevice.current.userInterfaceIdiom == .pad && (UIScreen.main.bounds.width == view.frame.size.width || view.frame.size.width > view.frame.size.height)) || (UIDevice.current.userInterfaceIdiom == .phone && view.frame.size.width > view.frame.size.height)
        
        containWebView()
        createHomeView()
        createURLBar()

        guard shouldEnsureBrowsingMode else { return }
        ensureBrowsingMode()
        guard let url = initialUrl else { return }
        submit(url: url)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)

        // Prevent the keyboard from showing up until after the user has viewed the Intro.
        let userHasSeenIntro = UserDefaults.standard.integer(forKey: AppDelegate.prefIntroDone) == AppDelegate.prefIntroVersion

        if userHasSeenIntro && !urlBar.inBrowsingMode {
            urlBar.becomeFirstResponder()
        }
        
        homeView?.setHighlightWhatsNew(shouldHighlight: shouldShowWhatsNew())
        
        super.viewWillAppear(animated)
    }

    private func containWebView() {
        addChildViewController(webViewController)
        webViewContainer.addSubview(webViewController.view)
        webViewController.didMove(toParentViewController: self)

        webViewController.view.snp.makeConstraints { make in
            make.edges.equalTo(webViewContainer.snp.edges)
        }
    }

    private func containTrackingProtectionSummary() {
        addChildViewController(trackingProtectionSummaryController)
        drawerContainerView.addSubview(trackingProtectionSummaryController.view)
        trackingProtectionSummaryController.didMove(toParentViewController: self)

        trackingProtectionSummaryController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
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
        mainContainerView.insertSubview(urlBar, aboveSubview: urlBarContainer)

        urlBar.snp.makeConstraints { make in
            urlBarTopConstraint = make.top.equalTo(mainContainerView.safeAreaLayoutGuide.snp.top).constraint
            topURLBarConstraints = [
                urlBarTopConstraint,
                make.leading.trailing.bottom.equalTo(urlBarContainer).constraint
            ]

            // Initial centered constraints, which will effectively be deactivated when
            // the top constraints are active because of their reduced priorities.
            make.leading.equalTo(mainContainerView.safeAreaLayoutGuide).priority(500)
            make.top.equalTo(homeView).priority(500)

            // Note: this padding here is in addition to the 8px that’s already applied for the Cancel action
            make.trailing.equalTo(homeView.settingsButton.snp.leading).offset(-8).priority(500)
        }
        topURLBarConstraints.forEach { $0.deactivate() }
    }

    @objc fileprivate func hideDrawer() {
        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration, delay: 0, options: .curveEaseIn, animations: {
            self.drawerConstraint.deactivate()
            self.drawerOverlayView.layer.opacity = 0
            self.view.layoutIfNeeded()
        }, completion: { completed in
            self.drawerOverlayView.isHidden = true
        })

        Telemetry.default.recordEvent(TelemetryEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.close, object: TelemetryEventObject.trackingProtectionDrawer))
    }

    fileprivate func showDrawer() {
        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration, delay: 0, options: .curveEaseIn, animations: {
            self.drawerConstraint.activate()
            self.drawerOverlayView.isHidden = false
            self.drawerOverlayView.layer.opacity = 1
            self.view.layoutIfNeeded()
        }, completion: nil)

        Telemetry.default.recordEvent(TelemetryEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.open, object: TelemetryEventObject.trackingProtectionDrawer))
    }

    fileprivate func resetBrowser() {
        // Screenshot the browser, showing the screenshot on top.
        let image = mainContainerView.screenshot()
        let screenshotView = UIImageView(image: image)
        mainContainerView.addSubview(screenshotView)
        screenshotView.snp.makeConstraints { make in
            make.edges.equalTo(mainContainerView)
        }

        // Reset the views. These changes won't be immediately visible since they'll be under the screenshot.
        webViewController.reset()
        webViewContainer.isHidden = true
        browserToolbar.isHidden = true
        urlBar.removeFromSuperview()
        urlBarContainer.alpha = 0
        createHomeView()
        createURLBar()

        // Clear the cache and cookies, starting a new session.
        WebCacheUtils.reset()

        // Zoom out on the screenshot, then slide down, then remove it.
        mainContainerView.layoutIfNeeded()
        UIView.animate(withDuration: UIConstants.layout.deleteAnimationDuration, delay: 0, options: .curveEaseInOut, animations: {
            screenshotView.snp.remakeConstraints { make in
                make.center.equalTo(self.mainContainerView)
                make.size.equalTo(self.mainContainerView).multipliedBy(0.9)
            }
            self.mainContainerView.layoutIfNeeded()
        }, completion: { _ in
            UIView.animate(withDuration: UIConstants.layout.deleteAnimationDuration, animations: {
                screenshotView.snp.remakeConstraints { make in
                    make.centerX.equalTo(self.mainContainerView)
                    make.top.equalTo(self.mainContainerView.snp.bottom)
                    make.size.equalTo(self.mainContainerView).multipliedBy(0.9)
                }
                screenshotView.alpha = 0
                self.mainContainerView.layoutIfNeeded()
            }, completion: { _ in
                self.urlBar.becomeFirstResponder()
                Toast(text: UIConstants.strings.eraseMessage).show()
                screenshotView.removeFromSuperview()
            })
        })

        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.eraseButton)
    }

    fileprivate func showSettings() {
        urlBar.shouldPresent = false
        let settingsViewController = SettingsViewController(searchEngineManager: searchEngineManager, whatsNew: self)
        navigationController!.pushViewController(settingsViewController, animated: true)
        navigationController!.setNavigationBarHidden(false, animated: true)

        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.settingsButton)
    }

    func ensureBrowsingMode() {
        guard urlBar != nil else { shouldEnsureBrowsingMode = true; return }
        guard !urlBar.inBrowsingMode else { return }

        urlBarContainer.alpha = 1
        urlBar.ensureBrowsingMode()

        topURLBarConstraints.forEach { $0.activate() }
        shouldEnsureBrowsingMode = false
    }

    func submit(url: URL) {
        // If this is the first navigation, show the browser and the toolbar.
        guard isViewLoaded else { initialUrl = url; return }

        if webViewContainer.isHidden {
            webViewContainer.isHidden = false
            homeView?.removeFromSuperview()
            homeView = nil
            urlBar.inBrowsingMode = true

            if !showsToolsetInURLBar {
                browserToolbar.animateHidden(false, duration: UIConstants.layout.toolbarFadeAnimationDuration)
            }
        }

        webViewController.load(URLRequest(url: url))
    }

    func openOverylay(text: String) {
        urlBar.becomeFirstResponder()
        urlBar.fillUrlBar(text: text)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Fixes the issue of a user fresh-opening Focus via Split View
        guard isViewLoaded else { return }
        
        // UIDevice.current.orientation isn't reliable. See https://bugzilla.mozilla.org/show_bug.cgi?id=1315370#c5
        // As a workaround, consider the phone to be in landscape if the new width is greater than the height.
        showsToolsetInURLBar = (UIDevice.current.userInterfaceIdiom == .pad && (UIScreen.main.bounds.width == size.width || size.width > size.height)) || (UIDevice.current.userInterfaceIdiom == .phone && size.width > size.height)
        urlBar.updateConstraints()
        browserToolbar.updateConstraints()
        
        coordinator.animate(alongsideTransition: { _ in
            self.urlBar.showToolset = self.showsToolsetInURLBar

            if self.homeView == nil && self.scrollBarState != .expanded {
                self.urlBar.collapseUrlBar(expandAlpha: 0, collapseAlpha: 1)
            }

            self.browserToolbar.animateHidden(self.homeView != nil || self.showsToolsetInURLBar, duration: coordinator.transitionDuration)
        })
    }

    fileprivate func presentImageActionSheet(title: String, link: String?, saveAction: @escaping () -> Void, copyAction: @escaping () -> Void) {
        let alertController = UIAlertController(title: title.truncated(limit: 160, position: .middle), message: nil, preferredStyle: .actionSheet)

        if let link = link {
            alertController.addAction(UIAlertAction(title: UIConstants.strings.copyLink, style: .default) { _ in
                UIPasteboard.general.string = link
            })

            alertController.addAction(UIAlertAction(title: UIConstants.strings.shareLink, style: .default) { _ in
                let activityViewController = UIActivityViewController(activityItems: [link], applicationActivities: nil)
                self.present(activityViewController, animated: true, completion: nil)
            })
        }

        alertController.addAction(UIAlertAction(title: UIConstants.strings.saveImage, style: .default) { _ in saveAction() })
        alertController.addAction(UIAlertAction(title: UIConstants.strings.copyImage, style: .default) { _ in copyAction() })
        alertController.addAction(UIAlertAction(title: UIConstants.strings.cancel, style: .cancel))

        alertController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: 0)
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func selectLocationBar() {
        urlBar.becomeFirstResponder()
    }
    
    @objc private func reload() {
        webViewController.reload()
    }
    
    @objc private func goBack() {
        webViewController.goBack()
    }
    
    @objc private func goForward() {
        webViewController.goForward()
    }

    private func toggleURLBarBackground(isBright: Bool) {
        if case .on = trackingProtectionStatus {
            urlBarContainer.isBright = isBright
        } else {
            urlBarContainer.isBright = false
        }
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: "l", modifierFlags: .command, action: #selector(BrowserViewController.selectLocationBar), discoverabilityTitle: UIConstants.strings.selectLocationBarTitle),
            UIKeyCommand(input: "r", modifierFlags: .command, action: #selector(BrowserViewController.reload), discoverabilityTitle: UIConstants.strings.browserReload),
            UIKeyCommand(input: "[", modifierFlags: .command, action: #selector(BrowserViewController.goBack), discoverabilityTitle: UIConstants.strings.browserBack),
            UIKeyCommand(input: "]", modifierFlags: .command, action: #selector(BrowserViewController.goForward), discoverabilityTitle: UIConstants.strings.browserForward),
        ]
    }
}

extension BrowserViewController: URLBarDelegate {
    func urlBar(_ urlBar: URLBar, didEnterText text: String) {
        overlayView.setSearchQuery(query: text, animated: true)
    }

    func urlBarDidPressScrollTop(_: URLBar) {
        guard !urlBar.isEditing else { return }

        switch scrollBarState {
        case .expanded:
            // Just scroll the vertical position so the page doesn't appear under
            // the notch on the iPhone X
            var point = webViewController.scrollView.contentOffset
            point.y = 0
            webViewController.scrollView.setContentOffset(point, animated: true)
        case .collapsed: showToolbars()
        default: break
        }
    }

    func urlBar(_ urlBar: URLBar, didSubmitText text: String) {
        let text = text.trimmingCharacters(in: .whitespaces)

        guard !text.isEmpty else {
            urlBar.url = webViewController.url
            return
        }

        var url = URIFixup.getURL(entry: text)
        if url == nil {
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.typeQuery, object: TelemetryEventObject.searchBar)
            url = searchEngineManager.activeEngine.urlForQuery(text)
        } else {
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.typeURL, object: TelemetryEventObject.searchBar)
        }
        if let urlBarURL = url {
            submit(url: urlBarURL)
            urlBar.url = urlBarURL
        }
        urlBar.dismiss()
    }

    func urlBarDidDismiss(_ urlBar: URLBar) {
        overlayView.dismiss()
        toggleURLBarBackground(isBright: !webViewController.isLoading)
    }

    func urlBarDidPressDelete(_ urlBar: URLBar) {
        self.resetBrowser()
    }

    func urlBarDidFocus(_ urlBar: URLBar) {
        overlayView.present()
        toggleURLBarBackground(isBright: false)
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

    func urlBarDidTapShield(_ urlBar: URLBar) {
        showDrawer()
    }
}

extension BrowserViewController: BrowserToolsetDelegate {
    func browserToolsetDidPressBack(_ browserToolset: BrowserToolset) {
        urlBar.dismiss()
        webViewController.goBack()
    }

    func browserToolsetDidPressForward(_ browserToolset: BrowserToolset) {
        urlBar.dismiss()
        webViewController.goForward()
    }

    func browserToolsetDidPressReload(_ browserToolset: BrowserToolset) {
        urlBar.dismiss()
        webViewController.reload()
    }

    func browserToolsetDidPressStop(_ browserToolset: BrowserToolset) {
        urlBar.dismiss()
        webViewController.stop()
    }

    func browserToolsetDidPressSend(_ browserToolset: BrowserToolset) {
        guard let url = webViewController.url else { return }

        present(OpenUtils.buildShareViewController(url: url, title: webViewController.title, printFormatter: webViewController.printFormatter, anchor: browserToolset.sendButton), animated: true, completion: nil)
    }

    func browserToolsetDidPressSettings(_ browserToolbar: BrowserToolset) {
        showSettings()
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
        if let url = searchEngineManager.activeEngine.urlForQuery(query) {
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.selectQuery, object: TelemetryEventObject.searchBar)
            submit(url: url)
            urlBar.url = url
        }

        urlBar.dismiss()
    }
    func overlayView(_ overlayView: OverlayView, didSubmitText text: String) {
        let text = text.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else {
            urlBar.url = webViewController.url
            return
        }
        
        var url = URIFixup.getURL(entry: text)
        if url == nil {
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.typeQuery, object: TelemetryEventObject.searchBar)
            url = searchEngineManager.activeEngine.urlForQuery(text)
        } else {
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.typeURL, object: TelemetryEventObject.searchBar)
        }
        if let overlayURL = url {
            submit(url: overlayURL)
            urlBar.url = overlayURL
        }
        urlBar.dismiss()
    }
}

extension BrowserViewController: WebControllerDelegate {
    func webControllerDidStartNavigation(_ controller: WebController) {
        urlBar.isLoading = true
        browserToolbar.isLoading = true
        toggleURLBarBackground(isBright: false)
        showToolbars()
    }

    func webControllerDidFinishNavigation(_ controller: WebController) {
        if webViewController.url?.absoluteString != "about:blank" {
            urlBar.url = webViewController.url
        }
        urlBar.isLoading = false
        browserToolbar.isLoading = false
        toggleURLBarBackground(isBright: !urlBar.isEditing)
        urlBar.progressBar.hideProgressBar()
    }

    func webController(_ controller: WebController, didFailNavigationWithError error: Error) {
        urlBar.url = webViewController.url
        urlBar.isLoading = false
        browserToolbar.isLoading = false
        toggleURLBarBackground(isBright: true)
        urlBar.progressBar.hideProgressBar()
    }

    func webController(_ controller: WebController, didUpdateCanGoBack canGoBack: Bool) {
        urlBar.canGoBack = canGoBack
        browserToolbar.canGoBack = canGoBack
    }

    func webController(_ controller: WebController, didUpdateCanGoForward canGoForward: Bool) {
        urlBar.canGoForward = canGoForward
        browserToolbar.canGoForward = canGoForward
    }

    func webController(_ controller: WebController, didUpdateEstimatedProgress estimatedProgress: Double) {
        // Don't update progress if the home view is visible. This prevents the centered URL bar
        // from catching the global progress events.
        guard homeView == nil else { return }

        if estimatedProgress == 0.1 {
            urlBar.progressBar.animateHidden(false, duration: UIConstants.layout.progressVisibilityAnimationDuration)
            urlBar.progressBar.animateGradient()
            return
        }

        urlBar.progressBar.setProgress(Float(estimatedProgress), animated: true)
    }

    func webController(_ controller: WebController, scrollViewWillBeginDragging scrollView: UIScrollView) {
        lastScrollOffset = scrollView.contentOffset
        lastScrollTranslation = scrollView.panGestureRecognizer.translation(in: scrollView)
    }

    func webController(_ controller: WebController, scrollViewDidEndDragging scrollView: UIScrollView) {
        snapToolbars(scrollView: scrollView)
    }

    func webController(_ controller: WebController, scrollViewDidScroll scrollView: UIScrollView) {
        let translation = scrollView.panGestureRecognizer.translation(in: scrollView)
        let isDragging = scrollView.panGestureRecognizer.state != .possible

        // This will be 0 if we're moving but not dragging (i.e., gliding after dragging).
        let dragDelta = translation.y - lastScrollTranslation.y

        // This will match dragDelta unless the URL bar is transitioning.
        let offsetDelta = scrollView.contentOffset.y - lastScrollOffset.y

        lastScrollOffset = scrollView.contentOffset
        lastScrollTranslation = translation

        guard scrollBarState != .animating, !scrollView.isZooming else { return }

        guard scrollView.contentOffset.y + scrollView.frame.height < scrollView.contentSize.height && (scrollView.contentOffset.y > 0 || scrollBarOffsetAlpha > 0) else {
            // We're overscrolling, so don't do anything.
            return
        }

        if !isDragging && offsetDelta < 0 {
            // We're gliding up after dragging, so fully show the toolbars.
            showToolbars()
            return
        }

        let pageExtendsBeyondScrollView = scrollView.frame.height + (UIConstants.layout.browserToolbarHeight + view.safeAreaInsets.bottom) + UIConstants.layout.urlBarHeight < scrollView.contentSize.height
        let toolbarsHiddenAtTopOfPage = scrollView.contentOffset.y <= 0 && scrollBarOffsetAlpha > 0

        guard isDragging, (dragDelta < 0 && pageExtendsBeyondScrollView) || toolbarsHiddenAtTopOfPage || scrollBarState == .transitioning else { return }

        let lastOffsetAlpha = scrollBarOffsetAlpha
        scrollBarOffsetAlpha = (0 ... 1).clamp(scrollBarOffsetAlpha - dragDelta / UIConstants.layout.urlBarHeight)
        switch scrollBarOffsetAlpha {
        case 0:
            scrollBarState = .expanded
        case 1:
            scrollBarState = .collapsed
        default:
            scrollBarState = .transitioning
        }

        self.urlBar.collapseUrlBar(expandAlpha: max(0, (1 - scrollBarOffsetAlpha * 2)), collapseAlpha: max(0, -(1 - scrollBarOffsetAlpha * 2)))
        self.urlBarTopConstraint.update(offset: -scrollBarOffsetAlpha * (UIConstants.layout.urlBarHeight - UIConstants.layout.collapsedUrlBarHeight))
        self.toolbarBottomConstraint.update(offset: scrollBarOffsetAlpha * (UIConstants.layout.browserToolbarHeight + view.safeAreaInsets.bottom))
        scrollView.bounds.origin.y += (lastOffsetAlpha - scrollBarOffsetAlpha) * UIConstants.layout.urlBarHeight

        lastScrollOffset = scrollView.contentOffset
    }

    func webControllerShouldScrollToTop(_ controller: WebController) -> Bool {
        guard scrollBarOffsetAlpha == 0 else {
            showToolbars()
            return false
        }

        return true
    }

    func webController(_ controller: WebController, stateDidChange state: BrowserState) {}

    func webController(_ controller: WebController, didUpdateTrackingProtectionStatus trackingStatus: TrackingProtectionStatus) {
        trackingProtectionStatus = trackingStatus
    }

    private func showToolbars() {
        let scrollView = webViewController.scrollView

        scrollBarState = .animating
        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration, delay: 0, options: .allowUserInteraction, animations: {
            self.urlBar.collapseUrlBar(expandAlpha: 1, collapseAlpha: 0)
            self.urlBarTopConstraint.update(offset: 0)
            self.toolbarBottomConstraint.update(inset: 0)
            scrollView.bounds.origin.y += self.scrollBarOffsetAlpha * UIConstants.layout.urlBarHeight
            self.scrollBarOffsetAlpha = 0
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.scrollBarState = .expanded
        })
    }

    private func hideToolbars() {
        let scrollView = webViewController.scrollView

        scrollBarState = .animating
        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration, delay: 0, options: .allowUserInteraction, animations: {
            self.urlBar.collapseUrlBar(expandAlpha: 0, collapseAlpha: 1)
            self.urlBarTopConstraint.update(offset: -UIConstants.layout.urlBarHeight + UIConstants.layout.collapsedUrlBarHeight)
            self.toolbarBottomConstraint.update(offset: UIConstants.layout.browserToolbarHeight)
            scrollView.bounds.origin.y += (self.scrollBarOffsetAlpha - 1) * UIConstants.layout.urlBarHeight
            self.scrollBarOffsetAlpha = 1
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.scrollBarState = .collapsed
        })
    }

    private func snapToolbars(scrollView: UIScrollView) {
        guard scrollBarState == .transitioning else { return }

        if scrollBarOffsetAlpha < 0.05 || scrollView.contentOffset.y < UIConstants.layout.urlBarHeight {
            showToolbars()
        } else {
            hideToolbars()
        }
    }
}

extension BrowserViewController: KeyboardHelperDelegate {

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        UIView.animate(withDuration: state.animationDuration) {
            self.homeViewBottomConstraint.update(offset: -state.intersectionHeightForView(view: self.view))
            self.view.layoutIfNeeded()
        }
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        UIView.animate(withDuration: state.animationDuration) {
            self.homeViewBottomConstraint.update(offset: 0)
            self.view.layoutIfNeeded()
        }
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidHideWithState state: KeyboardState) { }
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) { }
}

protocol WhatsNewDelegate {
    func shouldShowWhatsNew() -> Bool
    func didShowWhatsNew() -> Void
}

extension BrowserViewController: WhatsNewDelegate {
    func shouldShowWhatsNew() -> Bool {
        let counter = UserDefaults.standard.integer(forKey: AppDelegate.prefWhatsNewCounter)
        return counter != 0
    }
    
    func didShowWhatsNew() {
        UserDefaults.standard.set(AppInfo.shortVersion, forKey: AppDelegate.prefWhatsNewDone)
        UserDefaults.standard.removeObject(forKey: AppDelegate.prefWhatsNewCounter)
    }
}

extension BrowserViewController: TrackingProtectionSummaryDelegate {
    func trackingProtectionSummaryControllerDidTapClose(_ controller: TrackingProtectionSummaryViewController) {
        hideDrawer()
    }

    func trackingProtectionSummaryControllerDidToggleTrackingProtection(_ enabled: Bool) {
        if enabled {
            webViewController.enableTrackingProtection()
        } else {
            webViewController.disableTrackingProtection()
        }


        let telemetryEvent = TelemetryEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.change, object: TelemetryEventObject.trackingProtectionToggle)
        telemetryEvent.addExtra(key: "to", value: enabled)
        Telemetry.default.recordEvent(telemetryEvent)

        webViewController.reload()
        hideDrawer()
    }
}

