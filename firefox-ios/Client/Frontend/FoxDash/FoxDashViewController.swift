// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit
import WebKit

/// Full screen host for the bundled Fox Dash game, with a single native close button.
final class FoxDashViewController: UIViewController, WKNavigationDelegate {
    private enum UX {
        static let closeButtonSize: CGFloat = 44
        static let closeButtonInset: CGFloat = 8
        static let closeButtonBackgroundAlpha: CGFloat = 0.45
    }

    private let themeProvider: FoxDashThemeProviding
    private let bundle: Bundle
    private let onClose: () -> Void

    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.userContentController.addUserScript(
            WKUserScript(
                source: "window.__FOX_DASH_THEME__ = \"\(themeProvider.themeID)\";",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
        )
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        #if targetEnvironment(simulator)
        // Allow Safari Web Inspector only when running in simulator.
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif
        return webView
    }()

    private lazy var closeButton: UIButton = .build { [weak self] button in
        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage(named: StandardImageIdentifiers.Large.cross)?
            .withRenderingMode(.alwaysTemplate)
        configuration.baseForegroundColor = .white
        configuration.baseBackgroundColor = UIColor.black.withAlphaComponent(UX.closeButtonBackgroundAlpha)
        configuration.cornerStyle = .capsule
        button.configuration = configuration
        button.accessibilityLabel = .CloseButtonTitle
        button.accessibilityIdentifier = AccessibilityIdentifiers.FoxDash.closeButton
        button.addAction(UIAction { _ in self?.onClose() }, for: .touchUpInside)
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    init(
        themeProvider: FoxDashThemeProviding = FoxDashThemeProvider(),
        bundle: Bundle = .main,
        onClose: @escaping () -> Void
    ) {
        self.themeProvider = themeProvider
        self.bundle = bundle
        self.onClose = onClose
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(webView)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: UX.closeButtonInset
            ),
            closeButton.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: UX.closeButtonInset
            )
        ])

        guard let indexURL = bundle.url(forResource: "index", withExtension: "html", subdirectory: "FoxDash") else {
            return
        }
        webView.loadFileURL(indexURL, allowingReadAccessTo: indexURL.deletingLastPathComponent())
    }

    // MARK: - WKNavigationDelegate

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
    ) {
        let isLocal = navigationAction.request.url?.isFileURL ?? false
        decisionHandler(isLocal ? .allow : .cancel)
    }
}
