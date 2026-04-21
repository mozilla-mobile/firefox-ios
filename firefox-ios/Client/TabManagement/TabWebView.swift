// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import WebKit

protocol TabWebViewDelegate: AnyObject {
    @MainActor
    func tabWebView(_ tabWebView: TabWebView, didSelectFindInPageForSelection selection: String)
    @MainActor
    func tabWebViewSearchWithFirefox(
        _ tabWebViewSearchWithFirefox: TabWebView,
        didSelectSearchWithFirefoxForSelection selection: String
    )
    @MainActor
    func tabWebViewShouldShowAccessoryView(_ tabWebView: TabWebView) -> Bool
}

class TabWebView: WKWebView, MenuHelperWebViewInterface, ThemeApplicable, LegacyFeatureFlaggable {
    lazy var accessoryView: AccessoryViewProvider = .build(nil, {
        AccessoryViewProvider(windowUUID: self.windowUUID)
    })
    private var logger: Logger = DefaultLogger.shared
    private weak var delegate: TabWebViewDelegate?
    let windowUUID: WindowUUID
    private var pullRefresh: PullRefreshView?
    private var theme: Theme?
    private var uiTestLeakView: UIView? // Used for automation

    deinit {
        // TODO: FXIOS-13097 This is a work around until we can leverage isolated deinits
        guard Thread.isMainThread else {
            assertionFailure("TabWebView not deallocated on the main thread.")
            return
        }

        MainActor.assumeIsolated {
            // Note: this has no effect in production. This view is only
            // created during automation testing as a sentinel UI element.
            uiTestLeakView?.removeFromSuperview()
        }
    }

    override var hasOnlySecureContent: Bool {
        // TODO: - FXIOS-11721 Understand how it should be showed the lock icon for a local PDF
        // When PDF is shown we display the online URL for a local PDF so secure content should be true
        if let url, url.isFileURL, url.lastPathComponent.hasSuffix(".pdf") {
            return true
        }
        return super.hasOnlySecureContent
    }

    override var inputAccessoryView: UIView? {
        guard delegate?.tabWebViewShouldShowAccessoryView(self) ?? true else { return nil }

        return accessoryView
    }

    func configure(delegate: TabWebViewDelegate,
                   navigationDelegate: WKNavigationDelegate?) {
        self.delegate = delegate
        self.navigationDelegate = navigationDelegate

        accessoryView.previousClosure = { [weak self] in
            guard let self else { return }
            FormAutofillHelper.focusPreviousInputField(tabWebView: self,
                                                       logger: self.logger)
        }

        accessoryView.nextClosure = { [weak self] in
            guard let self else { return }
            FormAutofillHelper.focusNextInputField(tabWebView: self,
                                                   logger: self.logger)
        }

        accessoryView.doneClosure = { [weak self] in
            guard let self else { return }
            FormAutofillHelper.blurActiveElement(tabWebView: self, logger: self.logger)
            self.endEditing(true)
        }
    }

    init(frame: CGRect, configuration: WKWebViewConfiguration, windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        super.init(frame: frame, configuration: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func removeAllUserScripts() {
        configuration.userContentController.removeAllUserScripts()
        configuration.userContentController.removeAllScriptMessageHandlers()
    }

    func menuHelperFindInPage() {
        ensureMainThread {
            self.evaluateJavascriptInDefaultContentWorld("getSelection().toString()") { result, _ in
                let selection = result as? String ?? ""
                self.delegate?.tabWebView(self, didSelectFindInPageForSelection: selection)
            }
        }
    }

    func menuHelperSearchWith() {
        ensureMainThread {
            self.evaluateJavascriptInDefaultContentWorld("getSelection().toString()") { result, _ in
                let selection = result as? String ?? ""
                self.delegate?.tabWebViewSearchWithFirefox(self, didSelectSearchWithFirefoxForSelection: selection)
            }
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

    // swiftlint:disable unneeded_override
#if compiler(>=6)
    override func evaluateJavaScript(
        _ javaScriptString: String,
        completionHandler: (
            @MainActor (Any?, (any Error)?) -> Void
        )? = nil
    ) {
        super.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
#else
    /// Override evaluateJavascript - should not be called directly on TabWebViews any longer
    /// We should only be calling evaluateJavascriptInDefaultContentWorld in the future
    @available(*,
                unavailable,
                message: "Do not call evaluateJavaScript directly on TabWebViews, should only be called on super class")
    override func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        super.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
#endif
    // swiftlint:enable unneeded_override

    // MARK: - PullRefresh

    func addPullRefresh(onReload: @escaping () -> Void) {
        guard !scrollView.isZooming else { return }
        guard pullRefresh == nil else {
            pullRefresh?.startObservingContentScroll()
            return
        }
        let refresh = PullRefreshView(parentScrollView: scrollView,
                                      isPortraitOrientation: UIWindow.isPortrait) {
            onReload()
        }
        scrollView.addSubview(refresh)
        refresh.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            refresh.leadingAnchor.constraint(equalTo: leadingAnchor),
            refresh.trailingAnchor.constraint(equalTo: trailingAnchor),
            refresh.bottomAnchor.constraint(equalTo: scrollView.topAnchor),
            refresh.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            refresh.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        refresh.startObservingContentScroll()
        pullRefresh = refresh
        guard let theme else { return }
        refresh.applyTheme(theme: theme)
    }

    func removePullRefresh() {
        pullRefresh?.stopObservingContentScroll()
        pullRefresh?.removeFromSuperview()
        pullRefresh = nil
    }

    func setPullRefreshVisibility(isVisible: Bool) {
        pullRefresh?.isHidden = !isVisible
    }

    // MARK: - ThemeApplicable

    /// Updates the `background-color` of the webview to match
    /// the theme if the webview is showing "about:blank" (nil).
    func applyTheme(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.layer1
        pullRefresh?.applyTheme(theme: theme)
        if url == nil {
            let backgroundColor = theme.colors.layer1.hexString
            evaluateJavascriptInDefaultContentWorld("document.documentElement.style.backgroundColor = '\(backgroundColor)';")
        }
    }

    // MARK: - Automation Support

    /// No effect in production. This function creates a sentinel UI element which
    /// can be detected by our automated tests if the TabWebView is leaked after a
    /// tab is closed.
    func addUITestMemoryLeakDetectionUIElement() {
        guard AppConstants.isRunningUITests, let keyWindow = UIWindow.keyWindow else { return }

        class TABWEBVIEW_LEAK_DETECTED: UIButton { }

        guard let root = keyWindow.rootViewController else { fatalError() }
        let uiTestScreen = UIScreen.main.bounds
        let viewFrame = CGRect(x: uiTestScreen.width / 2.0,
                               y: uiTestScreen.height / 2.0,
                               width: 5,
                               height: 5)
        let leakIdentifierView = TABWEBVIEW_LEAK_DETECTED(frame: viewFrame)
        leakIdentifierView.backgroundColor = UIColor.white
        leakIdentifierView.accessibilityIdentifier = AccessibilityIdentifiers.Browser.WebView.automationTestLeakIndicator
        leakIdentifierView.isAccessibilityElement = true
        leakIdentifierView.isUserInteractionEnabled = true
        leakIdentifierView.accessibilityTraits = [.button]
        root.view.addSubview(leakIdentifierView)
        uiTestLeakView = leakIdentifierView
    }
}
