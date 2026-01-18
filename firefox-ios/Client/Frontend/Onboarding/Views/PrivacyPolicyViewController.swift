// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import WebKit
import Common
import Shared
import Network

class PrivacyPolicyViewController: UIViewController, Themeable {
    private var webView: WKWebView!
    private var url: URL
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    private var pathMonitor: NWPathMonitor?
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?

    init(
        url: URL,
        windowUUID: WindowUUID,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        themeManager: ThemeManager = AppContainer.shared.resolve()
    ) {
        self.url = url
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
        startNetworkMonitoring()
    }

    func setupView() {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(InternalSchemeHandler(shouldUseOldErrorPage: true), forURLScheme: InternalURL.scheme)
        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self

        view.backgroundColor = .systemBackground
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Theming
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        if #available(iOS 26.0, *) {
            navigationItem.rightBarButtonItem?.tintColor = theme.colors.textOnLight
        } else {
            navigationItem.rightBarButtonItem?.tintColor = theme.colors.actionPrimary
        }
    }

    private func startNetworkMonitoring() {
        pathMonitor = NWPathMonitor()
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self.checkRealConnectivity { hasInternet in
                        if hasInternet {
                            if self.webView.url == nil || !self.webView.isLoading {
                                self.webView.load(URLRequest(url: self.url))
                            }
                        } else {
                            self.showOfflineError()
                        }
                    }
                } else {
                    self.showOfflineError()
                }
            }
        }

        pathMonitor?.start(queue: DispatchQueue.global(qos: .background))
    }

    private func checkRealConnectivity(completion: @escaping (Bool) -> Void) {
        guard let checkURL = URL(string: "https://connectivitycheck.gstatic.com/generate_204") else {
            completion(false)
            return
        }

        var request = URLRequest(url: checkURL)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5.0
        request.cachePolicy = .reloadIgnoringLocalCacheData

        URLSession.shared.dataTask(with: request) { _, response, error in
            let hasInternet = (error == nil) && (response as? HTTPURLResponse)?.statusCode == 204
            DispatchQueue.main.async {
                completion(hasInternet)
            }
        }.resume()
    }

    private func showOfflineError() {
        let offlineError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: [NSLocalizedDescriptionKey: String.FxANoInternetConnection])
        handleError(webView: webView, error: offlineError)
    }

    func handleError(webView: WKWebView, error: Error) {
        let nsError = error as NSError
        ErrorPageHelper(certStore: nil).loadPage(nsError, forUrl: url, inWebView: webView)
    }

    deinit {
        pathMonitor?.cancel()
    }
}

extension PrivacyPolicyViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation?, withError error: Error) {
        handleError(webView: webView, error: error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleError(webView: webView, error: error)
    }
}
