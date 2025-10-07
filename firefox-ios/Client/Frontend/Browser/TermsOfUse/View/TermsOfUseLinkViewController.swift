// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Localizations
import Shared
import WebKit
import Redux

final class TermsOfUseLinkViewController: UIViewController,
                                          Themeable,
                                          WKNavigationDelegate {
    weak var coordinator: TermsOfUseCoordinatorDelegate?

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
    var themeListenerCancellable: Any?

    private lazy var header: UIView = .build { view in
        view.backgroundColor = self.currentTheme().colors.layer1
    }

    private lazy var backButton: UIButton = .build { button in
        button.setImage(UX.backArrowImage.withRenderingMode(.alwaysTemplate), for: .normal)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.adjustsImageSizeForAccessibilityContentSizeCategory = true
        button.imageView?.contentMode = .scaleAspectFit
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.setTitle(TermsOfUse.BackButton, for: .normal)
        button.setTitleColor(self.currentTheme().colors.actionPrimary, for: .normal)
        button.tintColor = self.currentTheme().colors.actionPrimary
        button.addTarget(self, action: #selector(self.closeTapped), for: .touchUpInside)
    }

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
        setupViews()

        listenForThemeChanges(withNotificationCenter: notificationCenter)
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
