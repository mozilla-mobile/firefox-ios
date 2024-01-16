// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import WebEngine

protocol NavigationDelegate: AnyObject {
    func onNavigationStateChange(canGoBack: Bool?, canGoForward: Bool?)
}

// Holds different type of browser views, communicating through protocols with them
class BrowserViewController: UIViewController, EngineSessionDelegate {
    weak var navigationDelegate: NavigationDelegate?
    private lazy var progressView: UIProgressView = .build { _ in }
    private var engineSession: EngineSession!
    private var engineView: EngineView!

    // MARK: - Init

    init(engineProvider: EngineProvider) {
        engineSession = engineProvider.session
        engineView = engineProvider.view
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

    // MARK: - Search

    func loadUrlOrSearch(_ searchTerm: SearchTerm) {
        guard searchTerm.isValidUrl, let url = URL(string: searchTerm.searchTerm) else {
            search(searchTerm)
            return
        }

        engineSession.load(url: url.absoluteString)
    }

    private func search(_ searchTerm: SearchTerm) {
        guard let url = searchTerm.encodedURL else { return }

        engineSession.load(url: url.absoluteString)
    }

    // MARK: - EngineSessionDelegate

    func onScrollChange(scrollX: Int, scrollY: Int) {
        // Handle view port with FXIOS-8086
    }

    func onLongPress(touchPoint: CGPoint) {
        // Handle preview with FXIOS-8178
    }

    func onTitleChange(title: String) {
        // Handle onTitle and onURL changes with FXIOS-8179
    }

    func onLoadUrl() {
        // Handle onTitle and onURL changes with FXIOS-8179
    }

    func onProgress(progress: Int) {
        progressView.setProgress(Float(progress), animated: true)
    }

    func onNavigationStateChange(canGoBack: Bool?, canGoForward: Bool?) {
        navigationDelegate?.onNavigationStateChange(canGoBack: canGoBack,
                                                    canGoForward: canGoForward)
    }
}
