/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Telemetry
import LocalAuthentication
import StoreKit
import Intents

class BrowserViewController: UIViewController {
    let appSplashController: AppSplashController

    private var context = LAContext()
    private let mainContainerView = UIView(frame: .zero)
    let darkView = UIView()
    
    private let webViewController = WebViewController(userAgent: UserAgent.shared)
    private let webViewContainer = UIView()
    
    var modalDelegate: ModalDelegate?

    fileprivate var keyboardState: KeyboardState?
    fileprivate let browserToolbar = BrowserToolbar()
    fileprivate var homeView: HomeView?
    fileprivate let overlayView = OverlayView()
    fileprivate let searchEngineManager = SearchEngineManager(prefs: UserDefaults.standard)
    fileprivate let urlBarContainer = URLBarContainer()
    fileprivate var urlBar: URLBar!
    fileprivate var topURLBarConstraints = [Constraint]()
    fileprivate let requestHandler = RequestHandler()
    fileprivate var findInPageBar: FindInPageBar?
    fileprivate var fillerView: UIView?
    fileprivate let alertStackView = UIStackView() // All content that appears above the footer should be added to this view. (Find In Page/SnackBars)

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

    private var trackingProtectionStatus: TrackingProtectionStatus = .on(TPPageStats()) {
        didSet {
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
    var tipManager: TipManager?
    
    static let userDefaultsTrackersBlockedKey = "lifetimeTrackersBlocked"
    static let userDefaultsShareTrackerStatsKeyOLD = "shareTrackerStats"
    static let userDefaultsShareTrackerStatsKeyNEW = "shareTrackerStatsNew"

    init(appSplashController: AppSplashController, tipManager: TipManager = TipManager.shared) {
        self.appSplashController = appSplashController
        self.tipManager = tipManager
        
        super.init(nibName: nil, bundle: nil)
        KeyboardHelper.defaultHelper.addDelegate(delegate: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("BrowserViewController hasn't implemented init?(coder:)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupBiometrics()
        view.addSubview(mainContainerView)
        
        darkView.isHidden = true
        darkView.backgroundColor = UIConstants.colors.background
        darkView.alpha = 0.4
        view.addSubview(darkView)
        darkView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        mainContainerView.snp.makeConstraints { make in
            make.top.bottom.leading.width.equalToSuperview()
        }

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
        
        view.addSubview(alertStackView)
        alertStackView.axis = .vertical
        alertStackView.alignment = .center

        // true if device is an iPad or is an iPhone in landscape mode
        showsToolsetInURLBar = (UIDevice.current.userInterfaceIdiom == .pad && (UIScreen.main.bounds.width == view.frame.size.width || view.frame.size.width > view.frame.size.height)) || (UIDevice.current.userInterfaceIdiom == .phone && view.frame.size.width > view.frame.size.height)
        
        containWebView()
        createHomeView()
        createURLBar()
        updateViewConstraints()
        
        // Listen for request desktop site notifications
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: UIConstants.strings.requestDesktopNotification), object: nil, queue: nil)  { _ in
            self.webViewController.requestDesktop()
        }
        
        let dropInteraction = UIDropInteraction(delegate: self)
        view.addInteraction(dropInteraction)
      
        // Listen for find in page actvitiy notifications
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: UIConstants.strings.findInPageNotification), object: nil, queue: nil)  { _ in
            self.updateFindInPageVisibility(visible: true, text: "")
        }

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
        
        if let homeViewToolset = homeView?.toolbar.toolset {
            homeViewToolset.setHighlightWhatsNew(shouldHighlight: homeViewToolset.shouldShowWhatsNew())
            homeView?.toolbar.layoutIfNeeded()
        }
        browserToolbar.toolset.setHighlightWhatsNew(shouldHighlight: browserToolbar.toolset.shouldShowWhatsNew())
        browserToolbar.layoutIfNeeded()
        
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Prevent the keyboard from showing up until after the user has viewed the Intro.
        let userHasSeenIntro = UserDefaults.standard.integer(forKey: AppDelegate.prefIntroDone) == AppDelegate.prefIntroVersion
        
        if userHasSeenIntro && !urlBar.inBrowsingMode {
            urlBar.activateTextField()
        }
        
        super.viewDidAppear(animated)
    }
    
    private func setupBiometrics() {
        // Register for foreground notification to check biometric authentication
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { notification in
            var biometricError: NSError?

            // Check if user is already in a cleared session, or doesn't have biometrics enabled in settings
            if  !Settings.getToggle(SettingsToggle.biometricLogin) || !AppDelegate.needsAuthenticated || self.webViewContainer.isHidden {
                self.appSplashController.toggleSplashView(hide: true)
                return
            }
            AppDelegate.needsAuthenticated = false

            self.context = LAContext()
            self.context.localizedReason = String(format: UIConstants.strings.authenticationReason, AppInfo.productName)
            self.context.localizedCancelTitle = UIConstants.strings.newSessionFromBiometricFailure

            if self.context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: &biometricError) {
                self.context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: self.context.localizedReason) {
                    [unowned self] (success, _) in
                    DispatchQueue.main.async {
                        if success {
                            self.showToolbars()
                            self.appSplashController.toggleSplashView(hide: true)
                        } else {
                            // Clear the browser session, as the user failed to authenticate
                            self.resetBrowser(hidePreviousSession: true)
                            self.appSplashController.toggleSplashView(hide: true)
                        }
                    }
                }
            } else {
                // Ran into an error with biometrics, so disable them and clear the browser:
                Settings.set(false, forToggle: SettingsToggle.biometricLogin)
                self.resetBrowser()
                self.appSplashController.toggleSplashView(hide: true)
            }
        }
    }
    
    // These functions are used to handle displaying and hiding the keyboard after the splash view is animated
    public func activateUrlBarOnHomeView() {
        // If the home view is not displayed, nor the overlayView hidden do not activate the text field:
        guard homeView != nil || !overlayView.isHidden else { return }
        urlBar.activateTextField()
    }
    
    public func deactivateUrlBarOnHomeView() {
        urlBar.dismissTextField()
    }

    private func containWebView() {
        addChild(webViewController)
        webViewContainer.addSubview(webViewController.view)
        webViewController.didMove(toParent: self)

        webViewController.view.snp.makeConstraints { make in
            make.edges.equalTo(webViewContainer.snp.edges)
        }
    }
    
    public func exitFullScreenVideo() {
        let js = "document.getElementsByTagName('video')[0].webkitExitFullScreen()"
        webViewController.evaluate(js, completion: nil)
    }

    private func createHomeView() {
        let homeView: HomeView
        if canShowTips() && shouldShowTips() {
            homeView = HomeView(tipManager: tipManager)
        }
        else {
            homeView = HomeView()
        }
        homeView.delegate = self
        homeView.toolbar.toolset.delegate = self
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

        let dragInteraction = UIDragInteraction(delegate: self)
        urlBar.addInteraction(dragInteraction)
        
        urlBar.snp.makeConstraints { make in
            urlBarTopConstraint = make.top.equalTo(mainContainerView.safeAreaLayoutGuide.snp.top).constraint
            topURLBarConstraints = [
                urlBarTopConstraint,
                make.leading.trailing.bottom.equalTo(urlBarContainer).constraint
            ]

            // Initial centered constraints, which will effectively be deactivated when
            // the top constraints are active because of their reduced priorities.
            make.centerX.equalToSuperview().priority(.required)
            make.leading.equalTo(mainContainerView.safeAreaLayoutGuide).priority(.medium)
            make.trailing.equalTo(mainContainerView.safeAreaLayoutGuide).priority(.medium)
            make.top.equalTo(homeView).priority(500)
        }
        topURLBarConstraints.forEach { $0.deactivate() }
    }

    private func buildTrackingProtectionMenu(info: TPPageStats?) -> PhotonActionSheet {
        var actions = [[PhotonActionSheetItem]]()
        if info != nil {
            let titleItem = PhotonActionSheetItem(title: UIConstants.strings.trackingProtectionLabel, iconString: "tracking_protection", isEnabled: true, accessory: .Switch)
            actions.append([titleItem])
        } else {
            let titleItem = PhotonActionSheetItem(title: UIConstants.strings.trackingProtectionLabel, iconString: "tracking_protection_off", isEnabled: false, accessory: .Switch)
            actions.append([titleItem])
        }
        let totalCount = PhotonActionSheetItem(title: UIConstants.strings.trackersBlocked, accessory: .Text, accessoryText: String(info?.total ?? 0), bold: true)
        let adCount = PhotonActionSheetItem(title: UIConstants.strings.adTrackerLabel, accessory: .Text, accessoryText: String(info?.adCount ?? 0))
        let analyticCount = PhotonActionSheetItem(title: UIConstants.strings.analyticTrackerLabel, accessory: .Text, accessoryText: String(info?.analyticCount ?? 0))
        let socialCount = PhotonActionSheetItem(title: UIConstants.strings.socialTrackerLabel, accessory: .Text, accessoryText: String(info?.socialCount ?? 0))
        let contentCount = PhotonActionSheetItem(title: UIConstants.strings.contentTrackerLabel, accessory: .Text, accessoryText: String(info?.contentCount ?? 0))
        actions.append([totalCount, adCount, analyticCount, socialCount, contentCount])
        return PhotonActionSheet(actions: actions, style: .overCurrentContext)
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
        alertStackView.snp.remakeConstraints { make in
            make.centerX.equalTo(self.view)
            make.width.equalTo(self.view.snp.width)
            
            if let keyboardHeight = keyboardState?.intersectionHeightForView(view: self.view), keyboardHeight > 0 {
                make.bottom.equalTo(self.view).offset(-keyboardHeight)
            } else if !browserToolbar.isHidden {
                // is an iPhone
                make.bottom.equalTo(self.browserToolbar.snp.top).priority(.low)
                make.bottom.lessThanOrEqualTo(self.view.safeAreaLayoutGuide.snp.bottom).priority(.required)
            } else {
                // is an iPad
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            }
        }
    }
    
    func updateFindInPageVisibility(visible: Bool, text: String = "") {
        if visible {
            if findInPageBar == nil {
                Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.open, object: TelemetryEventObject.findInPageBar)
                
                urlBar.dismiss()
                let findInPageBar = FindInPageBar()
                self.findInPageBar = findInPageBar
                let fillerView = UIView()
                self.fillerView = fillerView
                fillerView.backgroundColor = UIConstants.Photon.Grey70
                findInPageBar.text = text
                findInPageBar.delegate = self
                
                alertStackView.addArrangedSubview(findInPageBar)
                mainContainerView.insertSubview(fillerView, belowSubview: browserToolbar)

                updateViewConstraints()
                
                UIView.animate(withDuration: 2.0, animations: {
                    findInPageBar.snp.makeConstraints { make in
                        make.height.equalTo(UIConstants.ToolbarHeight)
                        make.leading.trailing.equalTo(self.alertStackView)
                        make.bottom.equalTo(self.alertStackView.snp.bottom)
                    }
                }) { (_) in
                    fillerView.snp.makeConstraints { make in
                        make.top.equalTo(self.alertStackView.snp.bottom)
                        make.bottom.equalTo(self.view)
                        make.leading.trailing.equalTo(self.alertStackView)
                    }
                }
            }
            
            self.findInPageBar?.becomeFirstResponder()
        } else if let findInPageBar = self.findInPageBar {
            findInPageBar.endEditing(true)
            webViewController.evaluate("__firefox__.findDone()", completion: nil)
            findInPageBar.removeFromSuperview()
            fillerView?.removeFromSuperview()
            self.findInPageBar = nil
            self.fillerView = nil
            updateViewConstraints()
        }
    }

    func resetBrowser(hidePreviousSession: Bool = false) {
        
        UserDefaults.standard.set(nil, forKey: "searchedHistory")
        
        // Used when biometrics fail and the previous session should be obscured
        if hidePreviousSession {
            clearBrowser()
            urlBar.activateTextField()
            return
        }
        
        // Screenshot the browser, showing the screenshot on top.
        let screenshotView = view.snapshotView(afterScreenUpdates: true) ?? UIView()
        
        mainContainerView.addSubview(screenshotView)
        screenshotView.snp.makeConstraints { make in
            make.edges.equalTo(mainContainerView)
        }

        clearBrowser()

        UIView.animate(withDuration: UIConstants.layout.deleteAnimationDuration, animations: {
            screenshotView.snp.remakeConstraints { make in
                make.centerX.equalTo(self.mainContainerView)
                make.top.equalTo(self.mainContainerView.snp.bottom)
                make.size.equalTo(self.mainContainerView).multipliedBy(0.9)
            }
            screenshotView.alpha = 0
            self.mainContainerView.layoutIfNeeded()
        }, completion: { _ in
            self.urlBar.activateTextField()
            Toast(text: UIConstants.strings.eraseMessage).show()
            screenshotView.removeFromSuperview()
        })

        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.eraseButton)
        
        if #available(iOS 12.0, *) {
            userActivity = SiriShortcuts().getActivity(for: .eraseAndOpen)
            let interaction = INInteraction(intent: eraseIntent, response: nil)
            interaction.donate { (error) in
                if let error = error { print(error.localizedDescription) }
            }
        }
    }
    
    private func clearBrowser() {
        // Helper function for resetBrowser that handles all the logic of actually clearing user data and the browsing session
        overlayView.currentURL = ""
        webViewController.reset()
        webViewContainer.isHidden = true
        browserToolbar.isHidden = true
        urlBar.removeFromSuperview()
        urlBarContainer.alpha = 0
        createHomeView()
        createURLBar()
        
        // Clear the cache and cookies, starting a new session.
        WebCacheUtils.reset()
        requestReviewIfNecessary()
        mainContainerView.layoutIfNeeded()
    }
    
    func requestReviewIfNecessary() {
        if AppInfo.isTesting() { return }
        let currentLaunchCount = UserDefaults.standard.integer(forKey: UIConstants.strings.userDefaultsLaunchCountKey)
        let threshold = UserDefaults.standard.integer(forKey: UIConstants.strings.userDefaultsLaunchThresholdKey)

        if threshold == 0 {
            UserDefaults.standard.set(14, forKey: UIConstants.strings.userDefaultsLaunchThresholdKey)
            return
        }

        // Make sure the request isn't within 90 days of last request
        let minimumDaysBetweenReviewRequest = 90
        let daysSinceLastRequest: Int
        if let previousRequest = UserDefaults.standard.object(forKey: UIConstants.strings.userDefaultsLastReviewRequestDate) as? Date {
            daysSinceLastRequest = Calendar.current.dateComponents([.day], from: previousRequest, to: Date()).day ?? 0
        } else {
            // No previous request date found, meaning we've never asked for a review
            daysSinceLastRequest = minimumDaysBetweenReviewRequest
        }

        if currentLaunchCount <= threshold ||  daysSinceLastRequest < minimumDaysBetweenReviewRequest {
            return
        }

        UserDefaults.standard.set(Date(), forKey: UIConstants.strings.userDefaultsLastReviewRequestDate)

        // Increment the threshold by 50 so the user is not constantly pestered with review requests
        switch threshold {
            case 14:
                UserDefaults.standard.set(64, forKey: UIConstants.strings.userDefaultsLaunchThresholdKey)
            case 64:
                UserDefaults.standard.set(114, forKey: UIConstants.strings.userDefaultsLaunchThresholdKey)
            default:
                break
        }
        
        SKStoreReviewController.requestReview()
    }

    fileprivate func showSettings(shouldScrollToSiri: Bool = false) {
        guard let modalDelegate = modalDelegate else { return }
        
        urlBar.shouldPresent = false
        
        let settingsViewController = SettingsViewController(searchEngineManager: searchEngineManager, whatsNew: browserToolbar.toolset, shouldScrollToSiri: shouldScrollToSiri)
        let settingsNavController = UINavigationController(rootViewController: settingsViewController)
        settingsNavController.modalPresentationStyle = .formSheet
        
        modalDelegate.presentModal(viewController: settingsNavController, animated: true)

        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.settingsButton)
    }
    
    @available(iOS 12.0, *)
    private func showSiriFavoriteSettings() {
        guard let modalDelegate = modalDelegate else { return }
        
        urlBar.shouldPresent = false
        let siriFavoriteViewController = SiriFavoriteViewController()
        let siriFavoriteNavController = UINavigationController(rootViewController: siriFavoriteViewController)
        siriFavoriteNavController.modalPresentationStyle = .formSheet
        
        modalDelegate.presentModal(viewController: siriFavoriteNavController, animated: true)
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
        if urlBar.url == nil {
            urlBar.url = url
        }
        guard #available(iOS 12.0, *), let savedUrl = UserDefaults.standard.value(forKey: "favoriteUrl") as? String else { return }
        if let currentDomain = url.baseDomain, let savedDomain = URL(string: savedUrl)?.baseDomain, currentDomain == savedDomain {
            userActivity = SiriShortcuts().getActivity(for: .openURL)
        }
    }

    func openOverylay(text: String) {
        urlBar.activateTextField()
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

            self.browserToolbar.animateHidden(self.homeView != nil || self.showsToolsetInURLBar, duration: coordinator.transitionDuration, completion: {
                self.updateViewConstraints()
            })
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
        urlBar.activateTextField()
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
        if urlBar.isEditing {
            urlBarContainer.color = .editing
        } else if case .on = trackingProtectionStatus {
            urlBarContainer.color = .bright
        } else {
            urlBarContainer.color = .dark
        }
    }
    
    private func toggleToolbarBackground() {
        switch trackingProtectionStatus {
        case .off:
            browserToolbar.color = .dark
        case .on:
            browserToolbar.color = .bright
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

    func canShowTips() -> Bool {
        return NSLocale.current.identifier == "en_US" && !AppInfo.isKlar
    }

    var showTrackerSemaphore = DispatchSemaphore(value: 1)
    func flipCoinForShowTrackerButton(percent: Int = 50, userDefaults:UserDefaults = UserDefaults.standard) {
        showTrackerSemaphore.wait()

        var shouldShowTipsToUser = userDefaults.object(forKey: BrowserViewController.userDefaultsShareTrackerStatsKeyNEW) as! Bool?

        if shouldShowTipsToUser == nil {
            // Check to see if the user was previously opted into the experiment
            shouldShowTipsToUser = userDefaults.object(forKey: BrowserViewController.userDefaultsShareTrackerStatsKeyOLD) as! Bool?

            if shouldShowTipsToUser != nil {
                // Remove the old flag
                userDefaults.removeObject(forKey: BrowserViewController.userDefaultsShareTrackerStatsKeyOLD)
            }

            if shouldShowTipsToUser == true {
                // User has already been opted into the experiment, continue showing the share button
                userDefaults.set(true, forKey: BrowserViewController.userDefaultsShareTrackerStatsKeyNEW)
            } else {
                // User has not been put into a bucket for determining if it should be shown
                // 50% chance they get put into the group that sees the share button
                // arc4random_uniform(100) returns an integer 0 through 99 (inclusive)
                if arc4random_uniform(100) < percent {
                    userDefaults.set(true, forKey: BrowserViewController.userDefaultsShareTrackerStatsKeyNEW)
                } else {
                    userDefaults.set(false, forKey: BrowserViewController.userDefaultsShareTrackerStatsKeyNEW)
                }
            }
        }

        showTrackerSemaphore.signal()
    }

    func shouldShowTips(percent: Int = 50, userDefaults:UserDefaults = UserDefaults.standard) -> Bool {
        flipCoinForShowTrackerButton(percent:percent, userDefaults:userDefaults)
        let shouldShowTipsToUser = userDefaults.object(forKey: BrowserViewController.userDefaultsShareTrackerStatsKeyNEW) as! Bool?
        return shouldShowTipsToUser == true
    }
    
    private func getNumberOfLifetimeTrackersBlocked(userDefaults: UserDefaults = UserDefaults.standard) -> Int {
        return userDefaults.integer(forKey: BrowserViewController.userDefaultsTrackersBlockedKey)
    }
    
    private func setNumberOfLifetimeTrackersBlocked(numberOfTrackers: Int) {
        UserDefaults.standard.set(numberOfTrackers, forKey: BrowserViewController.userDefaultsTrackersBlockedKey)
    }
}

extension BrowserViewController: UIDragInteractionDelegate, UIDropInteractionDelegate {
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        guard let url = urlBar.url, let itemProvider = NSItemProvider(contentsOf: url) else { return [] }
        let dragItem = UIDragItem(itemProvider: itemProvider)
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.drag, object: TelemetryEventObject.searchBar)
        return [dragItem]
    }

    func dragInteraction(_ interaction: UIDragInteraction, previewForLifting item: UIDragItem, session: UIDragSession) -> UITargetedDragPreview? {
        let params = UIDragPreviewParameters()
        params.backgroundColor = UIColor.clear
        return UITargetedDragPreview(view: urlBar.draggableUrlTextView, parameters: params)
    }
 
    func dragInteraction(_ interaction: UIDragInteraction, sessionDidMove session: UIDragSession) {
        for item in session.items {
            item.previewProvider = {
                guard let url = self.urlBar.url else {
                    return UIDragPreview(view: UIView())
                }
                return UIDragPreview(for: url)
            }
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: URL.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        _ = session.loadObjects(ofClass: URL.self) { urls in

            guard let url = urls.first else {
                return
            }
            
            self.ensureBrowsingMode()
            self.urlBar.fillUrlBar(text: url.absoluteString)
            self.submit(url: url)
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.drop, object: TelemetryEventObject.searchBar)
        }
    }
}

extension BrowserViewController: FindInPageBarDelegate {
    func findInPage(_ findInPage: FindInPageBar, didTextChange text: String) {
        find(text, function: "find")
    }
    
    func findInPage(_ findInPage: FindInPageBar, didFindNextWithText text: String) {
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.findNext)
        findInPageBar?.endEditing(true)
        find(text, function: "findNext")
    }
    
    func findInPage(_ findInPage: FindInPageBar, didFindPreviousWithText text: String) {
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.findPrev)
        findInPageBar?.endEditing(true)
        find(text, function: "findPrevious")
    }
    
    func findInPageDidPressClose(_ findInPage: FindInPageBar) {
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.close, object: TelemetryEventObject.findInPageBar)
        updateFindInPageVisibility(visible: false)
    }
    
    fileprivate func find(_ text: String, function: String) {
        let escaped = text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        webViewController.evaluate("__firefox__.\(function)(\"\(escaped)\")", completion: nil)
    }
}

extension BrowserViewController: URLBarDelegate {
    
    func urlBar(_ urlBar: URLBar, didAddCustomURL url: URL) {
        // Add the URL to the autocomplete list:
        let autocompleteSource = CustomCompletionSource()
        
        switch autocompleteSource.add(suggestion: url.absoluteString) {
        case .error(.duplicateDomain):
            break
        case .error(let error):
            guard !error.message.isEmpty else { return }
            Toast(text: error.message).show()
        case .success:
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.change, object: TelemetryEventObject.customDomain)
            Toast(text: UIConstants.strings.autocompleteCustomURLAdded).show()
        }
    }
    
    func urlBar(_ urlBar: URLBar, didEnterText text: String) {
        // Hide find in page if the home view is displayed
        let isOnHomeView = homeView != nil
        overlayView.setSearchQuery(query: text, animated: true, hideFindInPage: isOnHomeView)
    }

    func urlBarDidPressScrollTop(_: URLBar, tap: UITapGestureRecognizer) {
        guard !urlBar.isEditing else { return }

        switch scrollBarState {
        case .expanded:
            let y = tap.location(in: urlBar).y
            
            // If the tap is greater than this threshold, the user wants to type in the URL bar
            if y >= 10 {
                urlBar.activateTextField()
                return
            }
            
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
        
        SearchHistoryUtils.pushSearchToStack(with: text)
        SearchHistoryUtils.isFromURLBar = true
        
        var url = URIFixup.getURL(entry: text)
        if url == nil {
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.typeQuery, object: TelemetryEventObject.searchBar)
            Telemetry.default.recordSearch(location: .actionBar, searchEngine: searchEngineManager.activeEngine.getNameOrCustom())
            url = searchEngineManager.activeEngine.urlForQuery(text)
        } else {
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.typeURL, object: TelemetryEventObject.searchBar)
        }
        if let urlBarURL = url {
            submit(url: urlBarURL)
            urlBar.url = urlBarURL
        }
        
        if let urlText = urlBar.url?.absoluteString {
            overlayView.currentURL = urlText
        }
        
        urlBar.dismiss()
    }

    func urlBarDidDismiss(_ urlBar: URLBar) {
        overlayView.dismiss()
        toggleURLBarBackground(isBright: !webViewController.isLoading)
    }

    func urlBarDidPressDelete(_ urlBar: URLBar) {
        updateFindInPageVisibility(visible: false)
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
            self.updateFindInPageVisibility(visible: false)
            self.view.layoutIfNeeded()
        }
    }

    func urlBarDidDeactivate(_ urlBar: URLBar) {
        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration) {
            self.urlBarContainer.alpha = 0
            self.view.layoutIfNeeded()
        }
    }

    func urlBarDidTapShield(_ urlBar: URLBar) {
        Telemetry.default.recordEvent(TelemetryEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.open, object: TelemetryEventObject.trackingProtectionDrawer))
        
        switch trackingProtectionStatus {
        case .on(let info):
            let menuOn = buildTrackingProtectionMenu(info: info)
            presentPhotonActionSheet(menuOn, from: urlBar.shieldIcon)
        case .off:
            let menuOff = buildTrackingProtectionMenu(info: nil)
            presentPhotonActionSheet(menuOff, from: urlBar.shieldIcon)
        }
    }
    
    func urlBarDidLongPress(_ urlBar: URLBar) {
        let customURLItem = PhotonActionSheetItem(title: UIConstants.strings.customURLMenuButton, iconString: "icon_link") { action in
            urlBar.addCustomURL()
            UserDefaults.standard.set(false, forKey: TipManager.TipKey.autocompleteTip)
        }
        var actions = [PhotonActionSheetItem]()
        if let clipboardString = UIPasteboard.general.string {
            let pasteAndGoItem = PhotonActionSheetItem(title: UIConstants.strings.urlPasteAndGo, iconString: "icon_paste_and_go") { action in
                urlBar.pasteAndGo(clipboardString: clipboardString)
            }
            actions.append(pasteAndGoItem)
            let pasteItem = PhotonActionSheetItem(title: UIConstants.strings.urlPaste, iconString: "icon_paste") { action in
                urlBar.paste(clipboardString: clipboardString)
            }
            actions.append(pasteItem)
        }
        let copyItem = PhotonActionSheetItem(title: UIConstants.strings.copyAddressButton, iconString: "icon_link") { action in
            urlBar.copyToClipboard()
            Toast(text: UIConstants.strings.copyURLToast).show()
        }
        actions.append(copyItem)
        let urlContextMenu = PhotonActionSheet(actions: [[customURLItem], actions], style: .overCurrentContext)
        presentPhotonActionSheet(urlContextMenu, from: urlBar)
    }
    
    func urlBarDidPressPageActions(_ urlBar: URLBar) {
        guard let url = urlBar.url else { return }
        let utils = OpenUtils(url: url, webViewController: webViewController)
        let items = PageActionSheetItems(url: url)
        let sharePageItem = PhotonActionSheetItem(title: UIConstants.strings.sharePage, iconString: "icon_openwith_active") { action in
            let shareVC = utils.buildShareViewController(url: url)
            shareVC.becomeFirstResponder()
            self.present(shareVC, animated: true, completion: nil)
        }
        var shareItems = [sharePageItem]
        if items.canOpenInFirefox {
            shareItems.append(items.openInFireFoxItem)
        }
        if items.canOpenInChrome {
            shareItems.append(items.openInChromeItem)
        }
        shareItems.append(items.openInSafariItem)
        let copyItem = PhotonActionSheetItem(title: UIConstants.strings.copyAddress, iconString: "icon_link") { action in
            urlBar.copyToClipboard()
            Toast(text: UIConstants.strings.copyURLToast).show()
        }
        shareItems.append(copyItem)
        
        let actionItems = [items.findInPageItem, items.requestDesktopItem]
        let pageActionsMenu = PhotonActionSheet(title: UIConstants.strings.pageActionsTitle, actions: [shareItems, actionItems], style: .overCurrentContext)
        presentPhotonActionSheet(pageActionsMenu, from: urlBar.pageActionsButton)
    }
}

extension BrowserViewController: PhotonActionSheetDelegate {
    func presentPhotonActionSheet(_ actionSheet: PhotonActionSheet, from sender: UIView) {
        actionSheet.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .pad ? .popover : .overCurrentContext
        actionSheet.delegate = self
        darkView.isHidden = false
        if let popoverVC = actionSheet.popoverPresentationController, actionSheet.modalPresentationStyle == .popover {
            popoverVC.delegate = self
            popoverVC.sourceView = sender
            popoverVC.sourceRect = CGRect(x: sender.frame.width/2, y: sender.frame.size.height * 0.75, width: 1, height: 1)
            popoverVC.permittedArrowDirections = .up
            popoverVC.backgroundColor = UIConstants.colors.background
        }
        present(actionSheet, animated: true, completion: nil)
    }
    func photonActionSheetDidDismiss() {
        darkView.isHidden = true
    }
    func photonActionSheetDidToggleProtection(enabled: Bool) {
        enabled ? webViewController.enableTrackingProtection() : webViewController.disableTrackingProtection()
        
        let telemetryEvent = TelemetryEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.change, object: TelemetryEventObject.trackingProtectionToggle)
        telemetryEvent.addExtra(key: "to", value: enabled)
        Telemetry.default.recordEvent(telemetryEvent)
        UserDefaults.standard.set(false, forKey: TipManager.TipKey.sitesNotWorkingTip)
        
        webViewController.reload()
    }
}

extension BrowserViewController: BrowserToolsetDelegate {
    func browserToolsetDidLongPressReload(_ browserToolbar: BrowserToolset) {
        // Request desktop site
        urlBar.dismiss()
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Request Desktop Site", style: .default, handler: { (action) in
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.requestDesktop)
            self.webViewController.requestDesktop()
        }))
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))

        // Must handle iPad interface separately, as it does not implement action sheets
        let iPadAlert = alert.popoverPresentationController
        iPadAlert?.sourceView = browserToolbar.stopReloadButton
        iPadAlert?.sourceRect = browserToolbar.stopReloadButton.bounds
        
        present(alert, animated: true)
    }
    
    func browserToolsetDidPressBack(_ browserToolset: BrowserToolset) {
        SearchHistoryUtils.goBack()
        webViewController.goBack()
    }

    func browserToolsetDidPressForward(_ browserToolset: BrowserToolset) {
        SearchHistoryUtils.goForward()
        webViewController.goForward()
    }

    func browserToolsetDidPressReload(_ browserToolset: BrowserToolset) {
        webViewController.reload()
    }

    func browserToolsetDidPressStop(_ browserToolset: BrowserToolset) {
        webViewController.stop()
    }

    func browserToolsetDidPressSettings(_ browserToolbar: BrowserToolset) {
        updateFindInPageVisibility(visible: false)
        showSettings()
    }
}

extension BrowserViewController: HomeViewDelegate {
    
    func shareTrackerStatsButtonTapped() {
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.share, object: TelemetryEventObject.trackerStatsShareButton)
        
        let numberOfTrackersBlocked = getNumberOfLifetimeTrackersBlocked()
        let appStoreUrl = URL(string:String(format: "https://mzl.la/2GZBav0"))
        // Add space after shareTrackerStatsText to add URL in sentence
        let shareTrackerStatsText = "%@, the privacy browser from Mozilla, has already blocked %@ trackers for me. Fewer ads and trackers following me around means faster browsing! Get Focus for yourself here"
        let text = String(format: shareTrackerStatsText + " ", AppInfo.productName, String(numberOfTrackersBlocked))
        let shareController = UIActivityViewController(activityItems: [text, appStoreUrl as Any], applicationActivities: nil)
        present(shareController, animated: true)
    }
    
    func tipTapped() {
        guard let tip = tipManager?.currentTip, tip.showVc else { return }
        switch tip.identifier {
        case TipManager.TipKey.biometricTip:
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.biometricTip)
            showSettings()
        case TipManager.TipKey.siriEraseTip:
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.siriEraseTip)
            showSettings(shouldScrollToSiri: true)
        case TipManager.TipKey.siriFavoriteTip:
            if #available(iOS 12.0, *) {
                Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.show, object: TelemetryEventObject.siriFavoriteTip)
                showSiriFavoriteSettings()
            }
        default:
            break
        }
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
            Telemetry.default.recordSearch(location: .actionBar, searchEngine: searchEngineManager.activeEngine.getNameOrCustom())
            submit(url: url)
            urlBar.url = url
        }

        urlBar.dismiss()
    }
    
    func overlayView(_ overlayView: OverlayView, didSearchOnPage query: String) {
        updateFindInPageVisibility(visible: true, text: query)
        self.find(query, function: "find")
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
            Telemetry.default.recordSearch(location: .actionBar, searchEngine: searchEngineManager.activeEngine.getNameOrCustom())
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
    func webControllerDidStartProvisionalNavigation(_ controller: WebController) {
        urlBar.dismiss()
        updateFindInPageVisibility(visible: false)
    }
    
    func webController(_ controller: WebController, didUpdateFindInPageResults currentResult: Int?, totalResults: Int?) {
        if let total = totalResults {
            findInPageBar?.totalResults = total
        }
        
        if let current = currentResult {
            findInPageBar?.currentResult = current
        }
    }
    
    func webControllerDidStartNavigation(_ controller: WebController) {
        if (!SearchHistoryUtils.isFromURLBar && !SearchHistoryUtils.isNavigating) {
            SearchHistoryUtils.pushSearchToStack(with: (urlBar.url?.absoluteString)!)
        }
        SearchHistoryUtils.isNavigating = false
        SearchHistoryUtils.isFromURLBar = false
        urlBar.isLoading = true
        browserToolbar.color = .loading
        toggleURLBarBackground(isBright: false)
        showToolbars()
        
        if webViewController.url?.absoluteString != "about:blank" {
            urlBar.url = webViewController.url
        }
    }

    func webControllerDidFinishNavigation(_ controller: WebController) {
        if webViewController.url?.absoluteString != "about:blank" {
            urlBar.url = webViewController.url
        }
        urlBar.isLoading = false
        toggleToolbarBackground()
        toggleURLBarBackground(isBright: !urlBar.isEditing)
        urlBar.progressBar.hideProgressBar()
    }

    func webController(_ controller: WebController, didFailNavigationWithError error: Error) {
        urlBar.url = webViewController.url
        urlBar.isLoading = false
        toggleURLBarBackground(isBright: true)
        toggleToolbarBackground()
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

        urlBar.progressBar.alpha = 1
        urlBar.progressBar.isHidden = false
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
        updateViewConstraints()
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
        // Calculate the number of trackers blocked and add that to lifetime total
        if case .on(let info) = trackingStatus,
           case .on(let oldInfo) = trackingProtectionStatus {
            let differenceSinceLastUpdate = max(0, info.total - oldInfo.total)
            let numberOfTrackersBlocked = getNumberOfLifetimeTrackersBlocked()
            setNumberOfLifetimeTrackersBlocked(numberOfTrackers: numberOfTrackersBlocked + differenceSinceLastUpdate)
        }
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
            self.toolbarBottomConstraint.update(offset: UIConstants.layout.browserToolbarHeight + self.view.safeAreaInsets.bottom)
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
        keyboardState = state
        self.updateViewConstraints()
        UIView.animate(withDuration: state.animationDuration) {
            self.homeViewBottomConstraint.update(offset: -state.intersectionHeightForView(view: self.view))
            self.view.layoutIfNeeded()
        }
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        keyboardState = state
        self.updateViewConstraints()
        UIView.animate(withDuration: state.animationDuration) {
            self.homeViewBottomConstraint.update(offset: 0)
            self.view.layoutIfNeeded()
        }
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidHideWithState state: KeyboardState) { }
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) { }
}

extension BrowserViewController: UIPopoverPresentationControllerDelegate {
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        darkView.isHidden = true
    }
}

@available(iOS 12.0, *)
extension BrowserViewController {
    public var eraseIntent: EraseIntent {
        let intent = EraseIntent()
        intent.suggestedInvocationPhrase = "Erase"
        return intent
    }
}

protocol WhatsNewDelegate {
    func shouldShowWhatsNew() -> Bool
    func didShowWhatsNew() -> Void
}

