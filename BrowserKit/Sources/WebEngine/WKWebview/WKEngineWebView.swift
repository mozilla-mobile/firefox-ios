// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit

protocol WKEngineWebViewDelegate: AnyObject {
    func tabWebView(_ webView: WKEngineWebView, findInPageSelection: String)
    func tabWebView(_ webView: WKEngineWebView, searchSelection: String)
    func tabWebViewInputAccessoryView(_ webView: WKEngineWebView) -> EngineInputAccessoryView

    func webViewPropertyChanged(_ property: WKEngineWebViewProperty)
    func webViewNeedsReload()
}

/// Abstraction on top of the `WKWebView`
protocol WKEngineWebView: UIView {
    var navigationDelegate: WKNavigationDelegate? { get set }
    var uiDelegate: WKUIDelegate? { get set }
    var delegate: WKEngineWebViewDelegate? { get set }

    var estimatedProgress: Double { get }
    var url: URL? { get }
    var title: String? { get }
    var canGoBack: Bool { get }
    var canGoForward: Bool { get }
    var hasOnlySecureContent: Bool { get }

    var allowsBackForwardNavigationGestures: Bool { get set }
    var allowsLinkPreview: Bool { get set }
    var backgroundColor: UIColor? { get set }
    var interactionState: Any? { get set }
    var engineScrollView: WKScrollView? { get }
    var engineConfiguration: WKEngineConfiguration { get }

    @available(iOS 16.0, *)
    var isFindInteractionEnabled: Bool { get set }
    @available(iOS 16.0, *)
    var findInteraction: UIFindInteraction? { get }
    @available(iOS 16.4, *)
    var isInspectable: Bool { get set }

    init?(frame: CGRect, configurationProvider: WKEngineConfigurationProvider, parameters: WKWebViewParameters)

    @discardableResult
    func load(_ request: URLRequest) -> WKNavigation?

    @discardableResult
    func loadFileURL(_ URL: URL,
                     allowingReadAccessTo readAccessURL: URL) -> WKNavigation?

    @discardableResult
    func reloadFromOrigin() -> WKNavigation?

    func stopLoading()

    func goBack() -> WKNavigation?

    func goForward() -> WKNavigation?

    @discardableResult
    func go(to item: WKBackForwardListItem) -> WKNavigation?

    func currentBackForwardListItem() -> WKBackForwardListItem?

    func backList() -> [WKBackForwardListItem]

    func forwardList() -> [WKBackForwardListItem]

    func evaluateJavaScript(
        _ javaScript: String,
        in frame: WKFrameInfo?,
        in contentWorld: WKContentWorld,
        completionHandler: (@MainActor @Sendable (Result<Any, Error>) -> Void)?
    )

    func close()
}

extension WKEngineWebView {
    func evaluateJavaScript(
        _ javaScript: String,
        in frame: WKFrameInfo? = nil,
        in contentWorld: WKContentWorld,
        completionHandler: (@MainActor @Sendable (Result<Any, Error>) -> Void)? = nil
    ) {
        evaluateJavaScript(javaScript,
                           in: frame,
                           in: contentWorld,
                           completionHandler: completionHandler)
    }

    /// Evaluates Javascript in a .defaultClient sandboxed content world
    /// - Parameter javascript: String representing javascript to be evaluated
    func evaluateJavascriptInDefaultContentWorld(_ javascript: String) {
        evaluateJavaScript(javascript,
                           in: nil,
                           in: .defaultClient,
                           completionHandler: { _ in })
    }

    /// Evaluates Javascript in a .defaultClient sandboxed content world
    /// - Parameters:
    ///   - javascript: String representing javascript to be evaluated.
    ///   - frame: An object that contains information about a frame on a webpage.
    ///   - completion: Tuple containing optional data and an optional error.
    func evaluateJavascriptInDefaultContentWorld(
        _ javascript: String,
        _ frame: WKFrameInfo? = nil, _ completion: @escaping (Any?, Error?) -> Void
    ) {
        evaluateJavaScript(javascript, in: frame, in: .defaultClient) { result in
            switch result {
            case .success(let value):
                completion(value, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
}

final class DefaultWKEngineWebView: WKWebView,
                                    UIScrollViewDelegate,
                                    WKEngineWebView,
                                    MenuHelperWebViewInterface,
                                    ThemeApplicable {
    var engineScrollView: WKScrollView?
    var engineConfiguration: WKEngineConfiguration
    weak var delegate: WKEngineWebViewDelegate?

    private let pullRefreshViewType: EnginePullRefreshViewType
    private var pullRefreshView: EnginePullRefreshView?
    private var pullRefreshViewHeightConstraint: NSLayoutConstraint?
    private var pullRefreshViewWidthConstraint: NSLayoutConstraint?
    private var observedTokens = [NSKeyValueObservation]()

    override var inputAccessoryView: UIView? {
        if let delegatePreference = delegate?.tabWebViewInputAccessoryView(self) {
            switch delegatePreference {
            case .default: break
            case .none: return nil
            }
        }
        return super.inputAccessoryView
    }

    func backList() -> [WKBackForwardListItem] {
        return backForwardList.backList
    }

    func forwardList() -> [WKBackForwardListItem] {
        return backForwardList.forwardList
    }

    func currentBackForwardListItem() -> WKBackForwardListItem? {
        return backForwardList.currentItem
    }

    required init?(frame: CGRect,
                   configurationProvider: WKEngineConfigurationProvider,
                   parameters: WKWebViewParameters) {
        let configuration = configurationProvider.createConfiguration(parameters: parameters)
        self.engineConfiguration = configuration
        pullRefreshViewType = parameters.pullRefreshType
        super.init(frame: frame, configuration: configuration.webViewConfiguration)

        engineScrollView = scrollView
        scrollView.delegate = self
        setupObservers()
        setupPullRefresh()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        close()
    }

    func close() {
        removeObservers()
        removeAllUserScripts()
        engineScrollView = nil
        scrollView.delegate = nil
        navigationDelegate = nil
        uiDelegate = nil
        delegate = nil
    }

    private func setupObservers() {
        let loadingToken = observe(\.isLoading, options: [.new]) { [weak self] _, change in
            guard let isLoading = change.newValue else { return }
            self?.handleWebsiteLoadingChanged(isLoading)
            self?.delegate?.webViewPropertyChanged(.loading(isLoading))
        }

        let progressObserver = observe(\.estimatedProgress, options: [.new]) { [weak self] _, change in
            guard let progress = change.newValue else { return }
            self?.delegate?.webViewPropertyChanged(.estimatedProgress(progress))
        }

        let urlObserver = observe(\.url, options: [.new]) { [weak self] _, change in
            guard let url = change.newValue else { return }
            self?.delegate?.webViewPropertyChanged(.URL(url))
        }

        let titleObserver = observe(\.title, options: [.new]) { [weak self] _, change in
            guard let title = change.newValue as? String else { return }
            self?.delegate?.webViewPropertyChanged(.title(title))
        }

        let canGoBackObserver = observe(\.canGoBack, options: [.new]) { [weak self] _, change in
            guard let canGoBack = change.newValue else { return }
            self?.delegate?.webViewPropertyChanged(.canGoBack(canGoBack))
        }

        let canGoForwardObserver = observe(\.canGoForward, options: [.new]) { [weak self] _, change in
            guard let canGoForward = change.newValue else { return }
            self?.delegate?.webViewPropertyChanged(.canGoForward(canGoForward))
        }

        let hasOnlySecureBrowserObserver = observe(\.hasOnlySecureContent, options: [.new]) { [weak self] _, change in
            guard let hasOnlySecureContent = change.newValue else { return }
            self?.delegate?.webViewPropertyChanged(.hasOnlySecureContent(hasOnlySecureContent))
        }

        let contentSizeObserver = scrollView.observe(\.contentSize, options: [.new]) { [weak self] _, change in
            guard let newSize = change.newValue else { return }
            self?.pullRefreshViewHeightConstraint?.constant = newSize.height
            self?.pullRefreshViewWidthConstraint?.constant = newSize.width
            self?.delegate?.webViewPropertyChanged(.contentSize(newSize))
        }

        observedTokens.append(
            contentsOf: [
                loadingToken,
                progressObserver,
                urlObserver,
                titleObserver,
                canGoBackObserver,
                canGoForwardObserver,
                hasOnlySecureBrowserObserver,
                contentSizeObserver
            ]
        )

        // Observe fullscreen state, there are four states but we are reacting to `.enteringFullscreen`
        // and `.exitingFullscreen` only. When the view is on fullscreen is removed from the view hierarchy
        // so we add it back for `.exitingFullscreen`
        if #available(iOS 16.0, *) {
            let fullscreenObserver = observe(\.fullscreenState, options: [.new]) {  [weak self] object, change in
                guard object.fullscreenState == .enteringFullscreen ||
                        object.fullscreenState == .exitingFullscreen else { return }

                self?.delegate?.webViewPropertyChanged(.isFullScreen(object.fullscreenState == .enteringFullscreen))
            }
            observedTokens.append(fullscreenObserver)
        }
    }

    private func removeObservers() {
        observedTokens.forEach {
            $0.invalidate()
        }
        observedTokens.removeAll()
    }

    private func setupPullRefresh() {
        guard !scrollView.isZooming, pullRefreshView == nil else { return }
        let refresh = pullRefreshViewType.init()
        pullRefreshView = refresh
        refresh.configure(with: scrollView) { [weak self] in
            self?.delegate?.webViewNeedsReload()
        }
        guard pullRefreshViewType != UIRefreshControl.self else { return }
        scrollView.addSubview(refresh)
        refresh.translatesAutoresizingMaskIntoConstraints = false
        pullRefreshViewHeightConstraint = refresh.heightAnchor.constraint(equalToConstant: scrollView.frame.height)
        pullRefreshViewHeightConstraint?.isActive = true
        pullRefreshViewWidthConstraint = refresh.widthAnchor.constraint(equalToConstant: scrollView.frame.width)
        pullRefreshViewWidthConstraint?.isActive = true
        NSLayoutConstraint.activate([
            refresh.leadingAnchor.constraint(equalTo: leadingAnchor),
            refresh.trailingAnchor.constraint(equalTo: trailingAnchor),
            refresh.bottomAnchor.constraint(equalTo: scrollView.topAnchor),
        ])
    }

    private func removePullRefresh() {
        pullRefreshView?.removeFromSuperview()
        pullRefreshViewWidthConstraint = nil
        pullRefreshViewHeightConstraint = nil
        pullRefreshView = nil
    }

    private func handleWebsiteLoadingChanged(_ isLoading: Bool) {
        guard let refreshControl = pullRefreshView as? UIRefreshControl else {
            if isLoading {
                removePullRefresh()
            } else {
                setupPullRefresh()
            }
            return
        }
        if isLoading {
            refreshControl.beginRefreshing()
        } else {
            refreshControl.endRefreshing()
        }
    }

    func removeAllUserScripts() {
        configuration.userContentController.removeAllUserScripts()
        configuration.userContentController.removeAllScriptMessageHandlers()
    }

    func menuHelperFindInPage() {
        evaluateJavascriptInDefaultContentWorld("getSelection().toString()") { result, _ in
            let selection = result as? String ?? ""
            self.delegate?.tabWebView(self, findInPageSelection: selection)
        }
    }

    func menuHelperSearchWith() {
        evaluateJavascriptInDefaultContentWorld("getSelection().toString()") { result, _ in
            let selection = result as? String ?? ""
            self.delegate?.tabWebView(self, searchSelection: selection)
        }
    }

    override internal func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // The find-in-page selection menu only appears if the webview is the first responder.
        // Do not becomeFirstResponder on a mouse event.
        if let event = event, event.allTouches?.contains(where: { $0.type != .indirectPointer }) ?? false {
            becomeFirstResponder()
        }
        return super.hitTest(point, with: event)
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        removePullRefresh()
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        setupPullRefresh()
    }

    // MARK: - ThemeApplicable

    /// Updates the `background-color` of the webview to match
    /// the theme if the webview is showing "about:blank" (nil).
    func applyTheme(theme: any Common.Theme) {
        if let pullRefreshView = pullRefreshView as? ThemeApplicable {
            pullRefreshView.applyTheme(theme: theme)
        }
        if url == nil {
            let backgroundColor = theme.colors.layer1.hexString
            evaluateJavascriptInDefaultContentWorld("document.documentElement.style.backgroundColor = '\(backgroundColor)';")
        }
    }
}
