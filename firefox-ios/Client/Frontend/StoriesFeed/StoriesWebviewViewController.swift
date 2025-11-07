// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebKit
import WebEngine
import Common

class StoriesWebviewViewController: UIViewController,
                                    WKNavigationDelegate,
                                    WKUIDelegate,
                                    Themeable {
    private struct UX {
        static let navigationTitleStackViewSpacing: CGFloat = 4
        static let shieldImageSize = CGSize(width: 14, height: 14)
    }

    // MARK: - Themeable Properties
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol

    // MARK: - Private Properties
    private let profile: Profile
    private var webView: WKWebView?

    // MARK: - UI Properties
    private let navigationTitleStackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = UX.navigationTitleStackViewSpacing
    }

    private lazy var domainLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Bold.body.scaledFont()
        label.numberOfLines = 1
    }

    private let shieldImageView: UIImageView = .build { imageView in
        imageView.image = UIImage.templateImageNamed(StandardImageIdentifiers.Small.shieldCheckmarkFill)
    }

    private lazy var reloadToolbarButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.arrowCounterClockwise),
            style: .plain,
            target: self,
            action: #selector(didTapReload)
        )
        /// FXIOS-14029 Update to .FirefoxHomepage.Pocket.StoriesWebview.ReloadPageAccessibilityLabel once we have
        /// translations in v146, reuse .TabLocationReloadAccessibilityLabel since it is the same string
        button.accessibilityLabel = .TabLocationReloadAccessibilityLabel
        button.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.StoriesWebview.reloadButton
        return button
    }()

    init(profile: Profile,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.profile = profile
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Wait for layout to finish before setting up navigation stack to avoid truncation flicker in the domain label
        if navigationItem.titleView == nil {
            setupNavigationTitle()
        }
    }

    func configure(url: URL) {
        let tabConfigurationProvider = TabConfigurationProvider(prefs: profile.prefs)
        let tabConfiguration = tabConfigurationProvider.configuration(isPrivate: false).webViewConfiguration
        let webView = WKWebView(frame: .zero, configuration: tabConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))
        self.webView = webView

        domainLabel.text = webView.url?.normalizedHost
    }

    // MARK: Selectors
    @objc
    func didTapReload() {
        webView?.reload()
    }

    // MARK: Helper functions
    private func setupUI() {
        guard let webView else { return }
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        navigationItem.rightBarButtonItem = reloadToolbarButton
    }

    private func setupNavigationTitle() {
        navigationTitleStackView.addArrangedSubview(shieldImageView)
        navigationTitleStackView.addArrangedSubview(domainLabel)

        NSLayoutConstraint.activate([
            shieldImageView.widthAnchor.constraint(equalToConstant: UX.shieldImageSize.width),
            shieldImageView.heightAnchor.constraint(equalToConstant: UX.shieldImageSize.height)
        ])

        navigationItem.titleView = navigationTitleStackView
    }

    private func applyNavigationBarTheme(theme: Theme) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = theme.colors.layer1
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
    }

    // MARK: - WKNavigationDelegate
    @MainActor
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
    ) {
        decisionHandler(.allow)
        return
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        // Update domain label when navigation finishes (in the same window)
        domainLabel.text = webView.url?.normalizedHost

        shieldImageView.image = if webView.hasOnlySecureContent {
            UIImage.templateImageNamed(StandardImageIdentifiers.Small.shieldCheckmarkFill)
        } else {
            UIImage(named: StandardImageIdentifiers.Small.shieldSlashFillMulticolor)
        }
    }

    // MARK: - WKUIDelegate
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        // Update domain label when opening a link that would normally open in another webview
        domainLabel.text = navigationAction.request.url?.normalizedHost

        // If the page uses `window.open()` or `[target="_blank"]`, continue to open the page in the current webview
        // since there is no concept of tab management in the stories experience
        webView.load(navigationAction.request)
        return nil
    }

    // MARK: - Themeable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        applyNavigationBarTheme(theme: theme)
        domainLabel.textColor = theme.colors.textPrimary
        shieldImageView.tintColor = theme.colors.iconSecondary
    }
}
