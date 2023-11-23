// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol BrowserReloadStopDelegate: AnyObject {
    func browserIsLoading(isLoading: Bool)
}

// Holds different type of browser views, communicating through protocols with them
class BrowserViewController: UIViewController, BrowserDelegate {
    weak var reloadStopDelegate: BrowserReloadStopDelegate?
    private lazy var progressView: UIProgressView = .build { _ in }
    // TODO: FXIOS-7823 Integrate WebEngine in SampleBrowser
    // var currentBrowser: WebEngine!

    // MARK: - Init

    init() {
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
        // TODO: FXIOS-7823 Integrate WebEngine in SampleBrowser
//        setupBrowserView(TODO)
//        currentBrowser.browserDelegate = self
    }

    private func setupBrowserView(_ viewController: UIViewController) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        add(viewController)

        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
//        currentBrowser = viewController
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
    }

    // MARK: - Search

    func loadUrlOrSearch(_ searchTerm: String) {
        // TODO: FXIOS-7823 Integrate WebEngine in SampleBrowser
//        currentBrowser.loadUrlOrSearch(searchTerm)
    }

    // MARK: - BrowserDelegate

    func setProgressBarStatus(status: ProgressBarStatus) {
        progressView.progress = Float(status.progress)
        progressView.isHidden = status.isHidden

        reloadStopDelegate?.browserIsLoading(isLoading: !status.isHidden)
    }
}
