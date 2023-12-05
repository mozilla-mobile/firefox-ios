// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol BrowserSearchBarDelegate: AnyObject {
    func searchSuggestions(searchTerm: String)
    func openBrowser(searchTerm: String)
    func openSuggestions(searchTerm: String)
}

protocol BrowserMenuDelegate: AnyObject {
    func didClickMenu()
}

class BrowserSearchBar: UIView, UISearchBarDelegate {
    private weak var browserDelegate: BrowserSearchBarDelegate?
    private weak var browserMenuDelegate: BrowserMenuDelegate?

    private lazy var searchBar: UISearchBar = .build { bar in
        bar.searchBarStyle = .minimal
        bar.backgroundColor = .systemBackground
    }

    private lazy var menuButton: UIButton = .build { [self] button in
        let image = UIImage(named: "Menu")?.withTintColor(UIColor(named: "AccentColor")!)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(didClickMenu), for: .touchUpInside)
        button.backgroundColor = .systemBackground
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSearchBar()
        setupMenuButton()
        backgroundColor = searchBar.backgroundColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(browserDelegate: BrowserSearchBarDelegate,
                   browserMenuDelegate: BrowserMenuDelegate) {
        self.searchBar.delegate = self
        self.browserDelegate = browserDelegate
        self.browserMenuDelegate = browserMenuDelegate
    }

    func setSearchBarText(_ text: String?) {
        searchBar.text = text?.lowercased()
    }

    func getSearchBarText() -> String? {
        return searchBar.lowercased
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        searchBar.becomeFirstResponder()
        return super.becomeFirstResponder()
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        searchBar.resignFirstResponder()
        return super.resignFirstResponder()
    }

    // MARK: - Private

    @objc
    private func didClickMenu() {
        browserMenuDelegate?.didClickMenu()
    }

    private func setupSearchBar() {
        addSubview(searchBar)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: topAnchor),
            searchBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            searchBar.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    private func setupMenuButton() {
        addSubview(menuButton)

        NSLayoutConstraint.activate([
            menuButton.topAnchor.constraint(equalTo: topAnchor),
            menuButton.trailingAnchor.constraint(equalTo: searchBar.leadingAnchor),
            menuButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 4),
            menuButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - UISearchBarDelegate

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.lowercased, !searchText.isEmpty else { return }

        browserDelegate?.openBrowser(searchTerm: searchText)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let searchText = searchBar.lowercased else { return }
        searchBar.text = searchText

        browserDelegate?.searchSuggestions(searchTerm: searchText)
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        browserDelegate?.openSuggestions(searchTerm: searchBar.lowercased ?? "")
    }
}
