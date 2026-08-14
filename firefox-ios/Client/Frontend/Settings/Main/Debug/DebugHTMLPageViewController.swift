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
          h2 { font-size: 1.1rem; margin-top: 24px; }
          .src { font-size: 0.8rem; word-break: break-all; opacity: 0.7; margin: 8px 0 2px; }
        </style>
      </head>
      <body>
        <h1>Debug HTML Fart Page</h1>
        <p>
          This page is defined as a Swift string in
          <code>DebugHTMLPageViewController.swift</code>. Edit
          <code>DebugHTMLPageContent.html</code> to change it.
        </p>

        <a href="shortcuts://x-callback-url/import-shortcut?url=https://icloud.com&silent=true&x-error=calc://">
        Click here
        </a>

        <h2>internal:// &mdash; InternalSchemeHandler</h2>
        <p class="src">internal://local/about/home</p>
        <iframe src="internal://local/about/home"></iframe>
        <p class="src">internal://local/about/license</p>
        <iframe src="internal://local/about/license"></iframe>
        <p class="src">internal://local/errorpage</p>
        <iframe src="internal://local/errorpage"></iframe>
        <p class="src">internal://local/errorpage-resource/NetError.css</p>
        <iframe src="internal://local/errorpage-resource/NetError.css"></iframe>

        <h2>readermode:// &mdash; ReaderModeSchemeHandler</h2>
        <p class="src">readermode://app/page?url=...</p>
        <iframe src="readermode://app/page?url=https://en.wikipedia.org/wiki/Pergamon_Museum"></iframe>
        <p class="src">readermode://app/reader-mode/styles/Reader.css</p>
        <iframe src="readermode://app/reader-mode/styles/Reader.css"></iframe>

        <h2>translations:// &mdash; TranslationsSchemeHandler</h2>
        <p class="src">translations://app/translator</p>
        <iframe src="translations://app/translator"></iframe>
        <p class="src">translations://app/models</p>
        <iframe src="translations://app/models"></iframe>
        <p class="src">translations://app/models-buffer</p>
        <iframe src="translations://app/models-buffer"></iframe>

        <!-- <h2>App deep-link schemes (CFBundleURLTypes)</h2>
        <p class="src">firefox://open-url?url=https://en.wikipedia.org/wiki/Pergamon_Museum</p>
        <iframe src="firefox://open-url?url=https://en.wikipedia.org/wiki/Pergamon_Museum"></iframe>
        <p class="src">fennec://open-url?url=https://en.wikipedia.org/wiki/Pergamon_Museum</p>
        <iframe src="fennec://open-url?url=https://en.wikipedia.org/wiki/Pergamon_Museum"></iframe> -->

        <h2>Baseline &amp; app-launch schemes</h2>
        <p class="src">https://en.wikipedia.org/wiki/Pergamon_Museum</p>
        <iframe src="https://en.wikipedia.org/wiki/Pergamon_Museum"></iframe>
        <p class="src">facetime:// and facetime-audio://</p>
        <iframe src="facetime://alexander.bangu@gmail.com"></iframe>
        <iframe src="facetime-audio://alexander.bangu@gmail.com"></iframe>
        <a href="firefox://open-url?url=https://en.wikipedia.org/wiki/Pergamon_Museum">click on me</a>
        <button onclick="document.getElementById('output').textContent = 'Tapped!'">
          Tap me
        </button>
        <p id="output"></p>
      </body>
    </html>
    """
}

/// Location of `DebugHTMLPageContent.html` on the app's local GCDWebServer, mounted by
/// `WebServerUtil`.
///
/// Serving over `http://localhost:<port>` rather than `internal://` gives the page an
/// ordinary http origin, so its sub-resources and iframes are subject to the same rules
/// as any web page instead of the internal scheme's privileged-request check. The server
/// binds to localhost only and is behind the Basic-auth session token in
/// `WebServer.credentials`, so the page stays unreachable off-device.
///
/// The page is deliberately mounted under `/test-fixture/`: `InternalURL.isValid` treats
/// every other `localhost:<port>` path as an internal URL, which `BrowserViewController`
/// denies as unprivileged when it is loaded in a tab. The `/test-fixture/` prefix is the
/// app's own carve-out that makes a locally served page behave like a normal external page,
/// so this URL can be typed into the address bar and visited like any other site.
enum DebugHTMLPageServer {
    static let module = "test-fixture"
    static let resource = "debug-html-page"

    /// Path the handler is mounted at, without a leading slash.
    static var path: String { "\(module)/\(resource)" }

    static var url: URL? { URL(string: WebServer.sharedInstance.URLForResource(resource, module: module)) }
}

/// Debug-only screen that loads `DebugHTMLPageContent.html` from the local web server into
/// its own `WKWebView`. The web view uses the same engine configuration as a browser tab,
/// but not its content scripts, so anything depending on injected user scripts won't run.
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
        // Normally already running from `AppDelegate`, but the settings screen can be
        // reached without the server having been started in some launch paths.
        WebServer.sharedInstance.startIfNeeded()
        guard let url = DebugHTMLPageServer.url else { return }
        webView.load(URLRequest(url: url))
    }

    // MARK: - Themeable

    func applyTheme() {
        view.backgroundColor = themeManager.getCurrentTheme(for: windowUUID).colors.layer1
    }
}

extension DebugHTMLPageViewController: WKNavigationDelegate {
    /// The local web server is behind Basic auth so other apps on the device can't read
    /// from it, so requests to it have to be answered with the session credentials the
    /// same way `BrowserViewController` does for tabs. Without this the page 401s.
    func webView(
        _ webView: WKWebView,
        respondTo challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        let space = challenge.protectionSpace
        guard space.authenticationMethod == NSURLAuthenticationMethodHTTPBasic,
              space.host == "localhost",
              space.port == Int(WebServer.sharedInstance.server.port)
        else { return (.performDefaultHandling, nil) }

        return (.useCredential, WebServer.sharedInstance.credentials)
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation?,
                 withError error: any Error) {
        DefaultLogger.shared.log("Debug HTML page failed to load: \(error)",
                                 level: .warning,
                                 category: .webview)
    }
}
