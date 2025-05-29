// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import WebEngine

protocol NavigationDelegate: AnyObject {
    func onURLChange(url: String)
    func onLoadingStateChange(loading: Bool)
    func onNavigationStateChange(canGoBack: Bool, canGoForward: Bool)
    func showErrorPage(page: ErrorPageViewController)
}

// Holds different type of browser views, communicating through protocols with them
class BrowserViewController: UIViewController,
                             EngineSessionDelegate {
    weak var navigationDelegate: NavigationDelegate?
    private lazy var progressView: UIProgressView = .build { _ in }
    private var engineProvider: EngineProvider
    private var engineSession: EngineSession
    private var engineView: EngineView
    private let urlFormatter: URLFormatter
    private var gradientLayer: CAGradientLayer?

    // MARK: - Init

    init(engineProvider: EngineProvider,
         urlFormatter: URLFormatter = DefaultURLFormatter()) {
        self.engineProvider = engineProvider
        self.engineSession = engineProvider.session
        self.engineView = engineProvider.view
        self.urlFormatter = urlFormatter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle

    override func loadView() {
        view = engineView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        setupProgressBar()
        engineSession.delegate = self
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setGradientBackground()
    }

    private func setGradientBackground() {
        self.gradientLayer?.removeFromSuperlayer()
        let colorTop =  UIColor.orange.cgColor
        let colorBottom = UIColor.purple.cgColor

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorTop, colorBottom]
        gradientLayer.locations = [0.0, 0.6]
        gradientLayer.frame = self.view.bounds
        self.gradientLayer = gradientLayer
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupBrowserView(_ engineView: EngineView) {
        engineView.render(session: engineSession)
        view.bringSubviewToFront(progressView)
    }

    private func setupProgressBar() {
        view.addSubview(progressView)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 3)
        ])
        progressView.progressTintColor = .orange
        progressView.backgroundColor = .white
    }

    private func updateProgressView(loading: Bool) {
        progressView.isHidden = !loading
    }

    // MARK: - Browser actions

    func goBack() {
        engineSession.goBack()
    }

    func goForward() {
        engineSession.goForward()
    }

    func reload() {
        engineSession.reload()
    }

    func stop() {
        engineSession.stopLoading()
    }

    func scrollToTop() {
        engineSession.scrollToTop()
    }

    func switchToStandardTrackingProtection() {
        engineSession.switchToStandardTrackingProtection()
    }

    func switchToStrictTrackingProtection() {
        engineSession.switchToStrictTrackingProtection()
    }

    func disableTrackingProtection() {
        engineSession.disableTrackingProtection()
    }

    func toggleNoImageMode() {
        engineSession.toggleNoImageMode()
    }

    func increaseZoom() {
        engineSession.updatePageZoom(.increase)
    }

    func decreaseZoom() {
        engineSession.updatePageZoom(.decrease)
    }

    func setZoom(_ value: CGFloat) {
        engineSession.updatePageZoom(.set(value))
    }

    func resetZoom() {
        engineSession.updatePageZoom(.reset)
    }

    func showFindInPage() {
        engineSession.showFindInPage()
    }

    func requestMediaCapturePermission() -> Bool {
        return true
    }

    // MARK: - Search

    func loadUrlOrSearch(_ searchTerm: SearchTerm) {
        setupBrowserView(engineView)

        if let url = urlFormatter.getURL(entry: searchTerm.term) {
            // Search the entered URL
            let context = BrowsingContext(type: .internalNavigation, url: url)
            if let browserURL = BrowserURL(browsingContext: context) {
                engineSession.load(browserURL: browserURL)
                return
            }
        }

        if let url = URL(string: searchTerm.urlWithSearchTerm) {
            // Search term with Search Engine Bing
            let context = BrowsingContext(type: .internalNavigation, url: url)
            if let browserURL = BrowserURL(browsingContext: context) {
                engineSession.load(browserURL: browserURL)
            }
        }
    }

    // MARK: - EngineSessionDelegate general

    func onScrollChange(scrollX: Int, scrollY: Int) {
        // Handle view port with FXIOS-8086
    }

    func onLongPress(touchPoint: CGPoint) {
        // Handle preview with FXIOS-8178
    }

    func onTitleChange(title: String) {
        // If the Client needs to save a title like saving it inside some tab storage then it would do it here
    }

    func onHasOnlySecureContentChanged(secure: Bool) {
        // If the client needs to show a Secure lock icon etc.
    }

    func onLocationChange(url: String) {
        navigationDelegate?.onURLChange(url: url)
    }

    func onLoadingStateChange(loading: Bool) {
        navigationDelegate?.onLoadingStateChange(loading: loading)
        updateProgressView(loading: loading)
    }

    func onProgress(progress: Double) {
        progressView.setProgress(Float(progress), animated: true)
    }

    func onHideProgressBar() {
        progressView.isHidden = true
    }

    func onNavigationStateChange(canGoBack: Bool, canGoForward: Bool) {
        navigationDelegate?.onNavigationStateChange(canGoBack: canGoBack,
                                                    canGoForward: canGoForward)
    }

    func didLoad(pageMetadata: EnginePageMetadata) {
        // Page metadata can be used to fetch page favicons.
        // We currently do not handle favicons in SampleBrowser, so this is empty.
    }

    func onErrorPageRequest(error: NSError) {
        let errorPage = ErrorPageViewController()
        let message = "Error \(String(error.code)) happened on domain \(error.domain): \(error.localizedDescription)"
        errorPage.configure(errorMessage: message)

        navigationDelegate?.showErrorPage(page: errorPage)
    }

    func onProvideContextualMenu(linkURL: URL?) -> UIContextMenuConfiguration? {
        guard let url = linkURL else { return nil }

        let previewProvider: UIContextMenuContentPreviewProvider = {
            let previewVC = BrowserViewController(engineProvider: self.engineProvider)

            let context = BrowsingContext(type: .internalNavigation, url: url)
            if let browserURL = BrowserURL(browsingContext: context) {
                previewVC.engineSession.load(browserURL: browserURL)
            }

            return previewVC
        }

        let actionProvider: UIContextMenuActionProvider = { menuElements in
            var actions = [UIAction]()

            actions.append(UIAction(
                title: "Open Link",
                image: nil,
                identifier: UIAction.Identifier("linkContextMenu.openLink")
            ) { [weak self] _ in
                let context = BrowsingContext(type: .internalNavigation, url: url)
                if let browserURL = BrowserURL(browsingContext: context) {
                    self?.engineSession.load(browserURL: browserURL)
                }
            })

            return UIMenu(title: url.absoluteString, children: actions)
        }
        // Basic menu for testing purposes in the Sample Browser.
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: previewProvider,
                                          actionProvider: actionProvider)
    }

    func onWillDisplayAccessoryView() -> EngineInputAccessoryView {
        return .default
    }

    func onRequestOpenNewSession(_ session: EngineSession) {
        engineSession = session
        engineView.render(session: session)
    }

    // MARK: - Ads Handling

    func adsSearchProviderModels() -> [WebEngine.EngineSearchProviderModel] {
        return DefaultAdsTrackerDefinitions.searchProviders
    }

    // MARK: - EngineSessionDelegate Menu items

    func findInPage(with selection: String) {
        engineSession.showFindInPage(withSearchText: selection)
    }

    func search(with selection: String) {
        loadUrlOrSearch(SearchTerm(term: selection))
    }
}
