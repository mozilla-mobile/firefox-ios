// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import WebKit
import Common
import Shared
import ComponentLibrary

class ToULinkViewController: UIViewController, Themeable {

    private let url: URL
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?

    private var webView: WKWebView!

    // MARK: - Init

    init(url: URL,
         windowUUID: UUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.url = url
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
        
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(view)
        setupWebView()
        setupHeaderBar()
        applyTheme()
    }

    // MARK: - Setup

    private func setupHeaderBar() {
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.backgroundColor = currentTheme().colors.layer1

        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        backButton.setTitle("Back", for: .normal)
        backButton.tintColor = currentTheme().colors.actionPrimary
        backButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false

        header.addSubview(backButton)
        view.addSubview(header)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 44),

            backButton.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: header.centerYAnchor)
        ])
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(
            InternalSchemeHandler(shouldUseOldErrorPage: true),
            forURLScheme: InternalURL.scheme
        )
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        webView.load(URLRequest(url: url))
    }

    // MARK: - Theming

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true, completion: nil)
    }

    private func currentTheme() -> Theme {
        themeManager.getCurrentTheme(for: currentWindowUUID)
    }
}

// MARK: - WKNavigationDelegate

extension ToULinkViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation?, withError error: any Error) {
        let error = error as NSError
        if error.code == CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue {
            ErrorPageHelper(certStore: nil).loadPage(error, forUrl: url, inWebView: webView)
        }
    }
}
