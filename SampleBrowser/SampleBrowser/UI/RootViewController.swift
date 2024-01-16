// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// Holds toolbar, search bar, search and browser VCs
class RootViewController: UIViewController,
                          ToolbarDelegate,
                          NavigationDelegate,
                          SearchBarDelegate,
                          MenuDelegate {
    private lazy var toolbar: BrowserToolbar = .build { _ in }
    private lazy var searchBar: BrowserSearchBar =  .build { _ in }
    private lazy var statusBarFiller: UIView =  .build { view in
        view.backgroundColor = .white
    }

    private var browserVC: BrowserViewController

    // MARK: - Init

    init(engineProvider: EngineProvider) {
        self.browserVC = BrowserViewController(engineProvider: engineProvider)
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
    }

    private func configureBrowserView() {
        browserVC.view.translatesAutoresizingMaskIntoConstraints = false
        add(browserVC)

        NSLayoutConstraint.activate([
            browserVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            browserVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        browserVC.navigationDelegate = self
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

        searchBar.configure(searchBarDelegate: self,
                            menuDelegate: self)
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
//        browserVC.goBack()
    }

    func forwardButtonClicked() {
        // TODO: FXIOS-7823 Integrate WebEngine in SampleBrowser
//        browserVC.goForward()
    }

    func reloadButtonClicked() {
        // TODO: FXIOS-7823 Integrate WebEngine in SampleBrowser
//        browserVC.reload()
    }

    func stopButtonClicked() {
        // TODO: FXIOS-7823 Integrate WebEngine in SampleBrowser
//        browserVC.stop()
    }

    // MARK: - NavigationDelegate

    func onNavigationStateChange(canGoBack: Bool?, canGoForward: Bool?) {
        toolbar.updateBackForwardButtons(canGoBack: canGoBack, canGoForward: canGoForward)
    }

    func browserIsLoading(isLoading: Bool) {
        // TODO: Laurie
        toolbar.updateReloadStopButton(isLoading: isLoading)
    }

    // MARK: - SearchBarDelegate

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

    // MARK: - MenuDelegate

    func didClickMenu() {
        // Not implementing Settings for now, will see later on if this is needed or not
    }
}
