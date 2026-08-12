// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit
import WebEngine
import WebKit

/// The HTML rendered by `DebugHTMLPageViewController`. Edit `html` to change what
/// the debug page shows; no bundle resource or rebuild of the JS assets is needed.
enum DebugHTMLPageContent {
    static let html = """
    <!DOCTYPE html>
    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
        <style>
          :root { color-scheme: light dark; }
          body {
            font: -apple-system-body;
            font-family: -apple-system, system-ui, sans-serif;
            margin: 0;
            padding: 16px;
          }
          h1 { font-size: 1.5rem; }
          code {
            background: rgba(127, 127, 127, 0.2);
            border-radius: 4px;
            padding: 2px 4px;
          }
          iframe { width: 100%; height: 300px; }
        </style>
      </head>
      <body>
        <h1>Debug HTML Page</h1>
        <p>
          This page is defined as a Swift string in
          <code>DebugHTMLPageViewController.swift</code>. Edit
          <code>DebugHTMLPageContent.html</code> to change it.
        </p>
        <iframe src="readermode://app/page?url=https://en.wikipedia.org/wiki/Pergamon_Museum"></iframe>
        <button onclick="document.getElementById('output').textContent = 'Tapped!'">
          Tap me
        </button>
        <p id="output"></p>
      </body>
    </html>
    """
}

/// Serves `DebugHTMLPageContent.html` at `internal://local/debug/html-page`.
///
/// The page is served over the `internal://` scheme rather than through
/// `loadHTMLString` so that it has a real origin: sub-resources, `fetch`/`XHR` and
/// iframes (including custom-scheme ones such as `readermode://`) resolve the same
/// way they would on a page loaded in a tab. An `about:blank` document, which is
/// what `loadHTMLString(_:baseURL: nil)` produces, has an opaque origin and gets
/// those requests blocked.
final class DebugHTMLPageHandler: InternalSchemeResponse {
    static let path = "debug/html-page"
    static var url: URL? { URL(string: "\(InternalURL.baseUrl)/\(path)") }

    func response(forRequest request: URLRequest, useOldErrorPage: Bool = false) -> (URLResponse, Data)? {
        guard let url = request.url,
              let data = DebugHTMLPageContent.html.data(using: .utf8)
        else { return nil }

        return (InternalSchemeHandler.response(forUrl: url), data)
    }
}

/// Debug-only screen that renders `DebugHTMLPageContent.html` in its own `WKWebView`,
/// configured like a browser tab's web view so the page's network requests, custom
/// schemes and iframes behave as they would during normal browsing.
class DebugHTMLPageViewController: UIViewController, Themeable {
    private let profile: Profile
    private weak var tabManager: TabManager?

    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol

    private lazy var webView: WKWebView = .build()

    init(profile: Profile,
         tabManager: TabManager?,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.profile = profile
        self.tabManager = tabManager
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
        title = "Debug HTML Page"
        webView = makeWebView()
        setupWebView()
        loadDebugPage()

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    private func makeWebView() -> WKWebView {
        let parameters = WKWebViewParameters(
            blockPopups: profile.prefs.boolForKey(PrefsKeys.KeyBlockPopups) ?? true,
            isPrivate: false,
            autoPlay: AutoplayAccessors.getMediaTypesRequiringUserActionForPlayback(profile.prefs),
            schemeHandler: InternalSchemeHandler()
        )
        let configuration = DefaultWKEngineConfigurationProvider()
            .createConfiguration(parameters: parameters)
            .webViewConfiguration

        // Register the reader mode scheme handler alongside the `internal://` one, so
        // `readermode://` resources resolve here too. The handler itself still honours
        // the `customReaderModeScheme` feature flag.
        if configuration.urlSchemeHandler(forURLScheme: ReaderModeSchemeHandler.scheme) == nil {
            configuration.setURLSchemeHandler(
                ReaderModeSchemeHandler(profile: profile, tabManager: tabManager),
                forURLScheme: ReaderModeSchemeHandler.scheme
            )
        }

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.allowsLinkPreview = false

        // This is not shown full-screen, use mobile UA
        webView.customUserAgent = UserAgent.mobileUserAgent()

        // Allow Safari Web Inspector (requires toggle in Settings > Safari > Advanced).
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        return webView
    }

    private func setupWebView() {
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadDebugPage() {
        InternalSchemeHandler.responders[DebugHTMLPageHandler.path] = DebugHTMLPageHandler()
        guard let url = DebugHTMLPageHandler.url else { return }
        webView.load(PrivilegedRequest(url: url) as URLRequest)
    }

    // MARK: - Themeable

    func applyTheme() {
        view.backgroundColor = themeManager.getCurrentTheme(for: windowUUID).colors.layer1
    }
}

extension DebugHTMLPageViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation?,
                 withError error: any Error) {
        DefaultLogger.shared.log("Debug HTML page failed to load: \(error)",
                                 level: .warning,
                                 category: .webview)
    }
}
