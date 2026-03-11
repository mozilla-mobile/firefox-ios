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
        static let progressBarHeight: CGFloat = 2
    }

    private let url: URL
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?

    private var estimatedProgressObserver: NSKeyValueObservation?
    private var isLoading = false

    private lazy var progressBar: GradientProgressBar = .build { bar in
        bar.isHidden = true
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

        observeEstimatedProgress()
        webView.load(URLRequest(url: url))
    }

    private func setupViews() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: TermsOfUse.CloseButton,
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )

        view.addSubview(progressBar)
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            progressBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: UX.progressBarHeight),
    
            webView.topAnchor.constraint(equalTo: progressBar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func applyTheme() {
        let theme = currentTheme()
        view.backgroundColor = theme.colors.layer1
        applyProgressBarTheme(theme: theme)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    private func currentTheme() -> Theme {
        themeManager.getCurrentTheme(for: currentWindowUUID)
    }

    private func applyProgressBarTheme(theme: Theme) {
        let gradientStartColor = theme.colors.borderAccent
        let gradientMiddleColor = theme.colors.iconAccentPink
        let gradientEndColor = theme.colors.iconAccentYellow

        progressBar.setGradientColors(
            startColor: gradientStartColor,
            middleColor: gradientMiddleColor,
            endColor: gradientEndColor
        )
    }

    private func observeEstimatedProgress() {
        estimatedProgressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, change in
            let observedProgress = change.newValue ?? 0.0

            ensureMainThread { [weak self] in
                guard let self, self.isLoading else { return }
                let currentProgress = Double(self.progressBar.progress)
                let progress = max(currentProgress, observedProgress)

                guard 0.0...1.0 ~= progress else { return }
                self.updateProgressBar(progress: progress)
            }
        }
    }

    private func updateProgressBar(progress: Double) {
        let maximumProgress: Double = isLoading ? 0.9 : 1.0
        let displayedProgress = min(max(0.0, progress), maximumProgress)
        guard displayedProgress >= Double(progressBar.progress) else { return }

        progressBar.isHidden = false
        progressBar.setProgress(Float(displayedProgress), animated: true)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation?) {
        isLoading = true
        progressBar.isHidden = false
        progressBar.setProgress(0, animated: false)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        isLoading = false
        updateProgressBar(progress: 1.0)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation?, withError error: Error) {
        let nsError = error as NSError
        if nsError.code == CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue {
            ErrorPageHelper(certStore: nil).loadPage(nsError, forUrl: url, inWebView: webView)
        }
    }
}
