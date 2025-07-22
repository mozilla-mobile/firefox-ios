// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Localizations
import Shared
import WebKit

final class TermsOfUseLinkViewController: UIViewController, Themeable, WKNavigationDelegate {
    private struct UX {
        static let headerHeight: CGFloat = 44
        static let backButtonLeading: CGFloat = 8
        static let webViewTopInset: CGFloat = 44
        static let backArrowImage = UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.chevronLeft)
    }

    private let url: URL
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?

    private lazy var header: UIView = {
        let view = UIView()
        view.backgroundColor = currentTheme().colors.layer1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UX.backArrowImage, for: .normal)
        button.setTitle(TermsOfUse.BackButton, for: .normal)
        button.tintColor = currentTheme().colors.actionPrimary
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(InternalSchemeHandler(shouldUseOldErrorPage: true), forURLScheme: InternalURL.scheme)
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()

    init(
        url: URL,
        windowUUID: UUID,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.url = url
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(view)
        setupViews()
        applyTheme()
        webView.load(URLRequest(url: url))
    }

    private func setupViews() {
        view.addSubview(header)
        header.addSubview(backButton)
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: UX.headerHeight),

            backButton.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: UX.backButtonLeading),
            backButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            webView.topAnchor.constraint(equalTo: view.topAnchor, constant: UX.webViewTopInset),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func applyTheme() {
        view.backgroundColor = currentTheme().colors.layer1
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    private func currentTheme() -> Theme {
        themeManager.getCurrentTheme(for: currentWindowUUID)
    }

    // MARK: WebKit Navigation Delegate

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation?, withError error: Error) {
        let nsError = error as NSError
        if nsError.code == CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue {
            ErrorPageHelper(certStore: nil).loadPage(nsError, forUrl: url, inWebView: webView)
        }
    }
}
