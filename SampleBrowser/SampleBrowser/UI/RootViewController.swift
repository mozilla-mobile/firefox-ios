// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

// Holds toolbar, search bar, search and browser VCs
class RootViewController: UIViewController,
                          ToolbarDelegate,
                          NavigationDelegate,
                          SearchBarDelegate,
                          SearchSuggestionDelegate,
                          MenuDelegate,
                          SettingsDelegate,
                          FindInPageBarDelegate {
    private lazy var toolbar: BrowserToolbar = .build { _ in }
    private lazy var searchBar: BrowserSearchBar =  .build { _ in }
    private lazy var statusBarFiller: UIView =  .build { view in
        view.backgroundColor = .white
    }

    private var browserVC: BrowserViewController
    private var searchVC: SearchViewController
    private var findInPageBar: FindInPageBar?

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
        browserVC.loadUrlOrSearch(SearchTerm(term: term))
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

    func onURLChange(url: String) {
        searchBar.setSearchBarText(url)
    }

    func onFindInPage(selected: String) {
        showFindInPage()
    }

    func onFindInPage(currentResult: Int) {
        findInPageBar?.currentResult = currentResult
    }

    func onFindInPage(totalResults: Int) {
        findInPageBar?.totalResults = totalResults
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
        let settingsVC = SettingsViewController()
        settingsVC.delegate = self
        present(settingsVC, animated: true)
    }

    // MARK: - SearchViewDelegate

    func tapOnSuggestion(term: String) {
        searchBar.setSearchBarText(term)
        browse(to: term)
    }

    // MARK: - SettingsDelegate

    func switchToStrictTrackingProtection() {
        browserVC.switchToStrictTrackingProtection()
    }

    func switchToStandardTrackingProtection() {
        browserVC.switchToStandardTrackingProtection()
    }

    func toggleNoImageMode() {
        browserVC.toggleNoImageMode()
    }

    func scrollToTop() {
        browserVC.scrollToTop()
    }

    func showFindInPage() {
        let findInPageBar = FindInPageBar()
        findInPageBar.translatesAutoresizingMaskIntoConstraints = false
        findInPageBar.delegate = self
        self.findInPageBar = findInPageBar

        view.addSubview(findInPageBar)

        NSLayoutConstraint.activate([
            findInPageBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            findInPageBar.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            findInPageBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            findInPageBar.heightAnchor.constraint(equalToConstant: 46)
        ])
    }

    // MARK: - FindInPageBarDelegate

    func findInPage(_ findInPage: FindInPageBar, textChanged text: String) {
        browserVC.findInPage(text: text, function: .find)
    }

    func findInPage(_ findInPage: FindInPageBar, findPreviousWithText text: String) {
        browserVC.findInPage(text: text, function: .findPrevious)
    }

    func findInPage(_ findInPage: FindInPageBar, findNextWithText text: String) {
        browserVC.findInPage(text: text, function: .findNext)
    }

    func findInPageDidPressClose(_ findInPage: FindInPageBar) {
        browserVC.findInPageDone()
        findInPageBar?.endEditing(true)
        findInPageBar?.removeFromSuperview()
        findInPageBar = nil
    }
}
