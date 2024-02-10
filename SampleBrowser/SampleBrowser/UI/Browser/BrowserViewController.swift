// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import WebEngine

protocol NavigationDelegate: AnyObject {
    func onURLChange(url: String)
    func onLoadingStateChange(loading: Bool)
    func onNavigationStateChange(canGoBack: Bool, canGoForward: Bool)
}

// Holds different type of browser views, communicating through protocols with them
class BrowserViewController: UIViewController, EngineSessionDelegate {
    weak var navigationDelegate: NavigationDelegate?
    private lazy var progressView: UIProgressView = .build { _ in }
    private var engineSession: EngineSession!
    private var engineView: EngineView
    private let urlFormatter: URLFormatter

    // MARK: - Init

    init(engineProvider: EngineProvider,
         urlFormatter: URLFormatter = DefaultURLFormatter()) {
        self.engineSession = engineProvider.session
        self.engineView = engineProvider.view
        self.urlFormatter = urlFormatter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        setupProgressBar()

        setupBrowserView(engineView)
        engineSession.delegate = self
    }

    private func setupBrowserView(_ engineView: EngineView) {
        engineView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(engineView)

        NSLayoutConstraint.activate([
            engineView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            engineView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            engineView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            engineView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        engineView.render(session: engineSession)
    }

    private func setupProgressBar() {
        view.addSubview(progressView)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 3)
        ])
        progressView.progressTintColor = .orange
        progressView.backgroundColor = .white
    }

    private func updateProgressView(loading: Bool) {
        progressView.isHidden = !loading
    }

    // MARK: - Browser actions

    func goBack() {
        engineSession.goBack()
    }

    func goForward() {
        engineSession.goForward()
    }

    func reload() {
        engineSession.reload()
    }

    func stop() {
        engineSession.stopLoading()
    }

    func scrollToTop() {
        engineSession.scrollToTop()
    }

    // MARK: - Search

    func loadUrlOrSearch(_ searchTerm: SearchTerm) {
        if let url = urlFormatter.getURL(entry: searchTerm.term) {
            // Search the entered URL
            engineSession.load(url: url.absoluteString)
        } else {
            // Search term with Search Engine Bing
            engineSession.load(url: searchTerm.urlWithSearchTerm)
        }
    }

    // MARK: - EngineSessionDelegate general

    func onScrollChange(scrollX: Int, scrollY: Int) {
        // Handle view port with FXIOS-8086
    }

    func onLongPress(touchPoint: CGPoint) {
        // Handle preview with FXIOS-8178
    }

    func onTitleChange(title: String) {
        // If the Client needs to save a title like saving it inside some tab storage then it would do it here
    }

    func onLocationChange(url: String) {
        navigationDelegate?.onURLChange(url: url)
    }

    func onLoadingStateChange(loading: Bool) {
        navigationDelegate?.onLoadingStateChange(loading: loading)
        updateProgressView(loading: loading)
    }

    func onProgress(progress: Double) {
        progressView.setProgress(Float(progress), animated: true)
    }

    func onNavigationStateChange(canGoBack: Bool, canGoForward: Bool) {
        navigationDelegate?.onNavigationStateChange(canGoBack: canGoBack,
                                                    canGoForward: canGoForward)
    }

    // MARK: - EngineSessionDelegate Menu items

    func findInPage(with selection: String) {
        // FXIOS-8087: Handle find in page in WebEngine
    }

    func search(with selection: String) {
        loadUrlOrSearch(SearchTerm(term: selection))
    }
}
