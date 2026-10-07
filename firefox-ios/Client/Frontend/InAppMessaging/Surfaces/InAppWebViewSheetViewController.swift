// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import WebKit

protocol InAppWebViewSheetDelegate: AnyObject {
    func inAppWebViewSheetDidDismiss(_ sheet: InAppWebViewSheetViewController)
}

final class InAppWebViewSheetViewController: UIViewController, Themeable {
    private struct UX {
        static let grabberTopPadding: CGFloat = 8
        static let grabberWidth: CGFloat = 36
        static let grabberHeight: CGFloat = 5
        static let grabberCornerRadius: CGFloat = 2.5
        static let webViewTopPadding: CGFloat = 20
    }

    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    weak var delegate: InAppWebViewSheetDelegate?
    let message: InAppMessage

    private lazy var webView: WKWebView = .build()

    private lazy var grabberView: UIView = .build { view in
        view.layer.cornerRadius = UX.grabberCornerRadius
    }

    private lazy var activityIndicator: UIActivityIndicatorView = .build { indicator in
        indicator.hidesWhenStopped = true
        indicator.style = .medium
    }

    init(
        message: InAppMessage,
        windowUUID: WindowUUID,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.message = message
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
        setupLayout()
        loadContent()
        listenForThemeChange(view)
        applyTheme()
    }

    private func setupLayout() {
        view.addSubview(grabberView)
        view.addSubview(webView)
        view.addSubview(activityIndicator)

        webView.navigationDelegate = self

        NSLayoutConstraint.activate([
            grabberView.topAnchor.constraint(equalTo: view.topAnchor, constant: UX.grabberTopPadding),
            grabberView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grabberView.widthAnchor.constraint(equalToConstant: UX.grabberWidth),
            grabberView.heightAnchor.constraint(equalToConstant: UX.grabberHeight),

            webView.topAnchor.constraint(equalTo: grabberView.bottomAnchor, constant: UX.webViewTopPadding),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func loadContent() {
        guard let urlString = message.content.webviewURL,
              let url = URL(string: urlString)
        else { return }

        activityIndicator.startAnimating()
        webView.load(URLRequest(url: url))
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        grabberView.backgroundColor = theme.colors.borderPrimary
        webView.isOpaque = false
        webView.backgroundColor = theme.colors.layer1
    }
}

extension InAppWebViewSheetViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        activityIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation, withError error: Error) {
        activityIndicator.stopAnimating()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url {
            await MainActor.run {
                UIApplication.shared.open(url)
            }
            return .cancel
        }
        return .allow
    }
}
