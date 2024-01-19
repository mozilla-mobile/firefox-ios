// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// Holds toolbar, search bar, search and browser VCs
class RootViewController: UIViewController,
                          ToolbarDelegate,
                          NavigationDelegate,
                          SearchBarDelegate,
                          SearchSuggestionDelegate,
                          MenuDelegate {
    private lazy var toolbar: BrowserToolbar = .build { _ in }
    private lazy var searchBar: BrowserSearchBar =  .build { _ in }
    private lazy var statusBarFiller: UIView =  .build { view in
        view.backgroundColor = .white
    }

    private var browserVC: BrowserViewController
    private var searchVC: SearchViewController

    // MARK: - Init

    init(engineProvider: EngineProvider) {
        self.browserVC = BrowserViewController(engineProvider: engineProvider)
        self.searchVC = SearchViewController()
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
        configureSearchView()
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

    private func configureSearchView() {
        searchVC.searchViewDelegate = self
        searchVC.view.translatesAutoresizingMaskIntoConstraints = false
    }

    private func addSearchView() {
        guard searchVC.parent == nil else { return }
        add(searchVC)

        NSLayoutConstraint.activate([
            searchVC.view.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            searchVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchVC.view.bottomAnchor.constraint(equalTo: toolbar.topAnchor)
        ])
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
        browserVC.loadUrlOrSearch(SearchTerm(searchTerm: term))
        searchVC.remove()
    }

    // MARK: - BrowserToolbarDelegate

    func backButtonClicked() {
        browserVC.goBack()
    }

    func forwardButtonClicked() {
        browserVC.goForward()
    }

    func reloadButtonClicked() {
        browserVC.reload()
    }

    func stopButtonClicked() {
        browserVC.stop()
    }

    // MARK: - NavigationDelegate

    func onLoadingStateChange(loading: Bool) {
        toolbar.updateReloadStopButton(loading: loading)
    }

    func onNavigationStateChange(canGoBack: Bool, canGoForward: Bool) {
        toolbar.updateBackForwardButtons(canGoBack: canGoBack, canGoForward: canGoForward)
    }

    // MARK: - SearchBarDelegate

    func searchSuggestions(searchTerm: String) {
        guard !searchTerm.isEmpty else {
            searchVC.viewModel.resetSearch()
            searchVC.openSuggestions()
            return
        }

        addSearchView()
        searchVC.requestSearch(term: searchTerm)
    }

    func openSuggestions(searchTerm: String) {
        addSearchView()
        searchVC.openSuggestions()
    }

    func openBrowser(searchTerm: String) {
        guard let searchText = searchBar.getSearchBarText(), !searchText.isEmpty else { return }
        browse(to: searchText)
    }

    // MARK: - MenuDelegate

    func didClickMenu() {
        // Not implementing Settings for now, will see later on if this is needed or not
    }

    // MARK: - SearchViewDelegate

    func tapOnSuggestion(term: String) {
        searchBar.setSearchBarText(term)
        browse(to: term)
    }
}
