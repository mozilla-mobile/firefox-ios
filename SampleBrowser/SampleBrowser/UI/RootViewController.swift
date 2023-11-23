// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// Holds toolbar, search bar, search and browser VCs
class RootViewController: UIViewController,
                          BrowserToolbarDelegate,
                          BrowserReloadStopDelegate,
                          BrowserSearchBarDelegate,
                          BrowserMenuDelegate {
    private lazy var toolbar: BrowserToolbar = .build { _ in }
    private lazy var searchBar: BrowserSearchBar =  .build { _ in }
    private lazy var statusBarFiller: UIView =  .build { view in
        view.backgroundColor = .white
    }

    private var browserVC: BrowserViewController

    // Note: For easier debugging, we might need to load
    // same URL again and for this use the following homepage url
    private var homepage = ""

    // MARK: - Init

    init() {
        self.browserVC = BrowserViewController()
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureBrowserView()
        configureSearchbar()
        configureToolbar()

        if !homepage.isEmpty {
            browse(to: homepage)
        }
    }

    private func configureBrowserView() {
        browserVC.view.translatesAutoresizingMaskIntoConstraints = false
        add(browserVC)

        NSLayoutConstraint.activate([
            browserVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            browserVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        browserVC.reloadStopDelegate = self
    }

    private func configureSearchbar() {
        view.addSubview(statusBarFiller)
        view.addSubview(searchBar)

        NSLayoutConstraint.activate([
            statusBarFiller.topAnchor.constraint(equalTo: view.topAnchor),
            statusBarFiller.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBarFiller.bottomAnchor.constraint(equalTo: searchBar.topAnchor),
            statusBarFiller.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.bottomAnchor.constraint(equalTo: browserVC.view.topAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        searchBar.configure(browserDelegate: self,
                            browserMenuDelegate: self)
        searchBar.becomeFirstResponder()
    }

    private func configureToolbar() {
        view.addSubview(toolbar)

        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.topAnchor.constraint(equalTo: browserVC.view.bottomAnchor)
        ])

        toolbar.toolbarDelegate = self
    }

    // MARK: - Private

    private func browse(to term: String) {
        searchBar.resignFirstResponder()
        browserVC.loadUrlOrSearch(term)
    }

    // MARK: - BrowserToolbarDelegate

    func backButtonClicked() {
        // TODO: FXIOS-7823 Integrate WebEngine in SampleBrowser
//        browserVC.currentBrowser.goBack()
    }

    func forwardButtonClicked() {
        // TODO: FXIOS-7823 Integrate WebEngine in SampleBrowser
//        browserVC.currentBrowser.goForward()
    }

    func reloadButtonClicked() {
        // TODO: FXIOS-7823 Integrate WebEngine in SampleBrowser
//        browserVC.currentBrowser.reload()
    }

    func stopButtonClicked() {
        // TODO: FXIOS-7823 Integrate WebEngine in SampleBrowser
//        browserVC.currentBrowser.stop()
    }

    // MARK: - BrowserReloadStopDelegate

    func browserIsLoading(isLoading: Bool) {
        toolbar.updateReloadStopButton(isLoading: isLoading)

        // Update back and forward buttons when we're done loading
        if !isLoading {
            // TODO: FXIOS-7823 Integrate WebEngine in SampleBrowser
//            toolbar.updateBackForwardButtons(canGoBack: browserVC.currentBrowser.canGoBack,
//                                             canGoForward: browserVC.currentBrowser.canGoForward)
        }
    }

// MARK: - BrowserSearchBarDelegate

    func searchSuggestions(searchTerm: String) {
        guard !searchTerm.isEmpty else {
            return
        }
    }

    func openSuggestions(searchTerm: String) {
    }

    func openBrowser(searchTerm: String) {
        guard let searchText = searchBar.getSearchBarText(), !searchText.isEmpty else { return }
        browse(to: searchText)
    }

    // MARK: - BrowserMenuDelegate

    func didClickMenu() {
        // Not implementing Settings for now, will see later on if this is needed or not
    }
}
