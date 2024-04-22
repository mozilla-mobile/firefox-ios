// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

struct SearchBarViewModel {
    let placeholder: String
}

protocol SearchBarDelegate: AnyObject {
    func searchSuggestions(searchTerm: String)
    func openBrowser(searchTerm: String)
    func openSuggestions(searchTerm: String)
}

protocol MenuDelegate: AnyObject {
    func didTapMenu()
}

class BrowserSearchBar: UIView, UISearchBarDelegate {
    private weak var searchBarDelegate: SearchBarDelegate?
    private weak var menuDelegate: MenuDelegate?

    private lazy var searchBar: UISearchBar = .build { bar in
        bar.searchBarStyle = .minimal
        bar.backgroundColor = .systemBackground
    }

    private lazy var menuButton: UIButton = .build { [self] button in
        let image = UIImage(named: "Menu")?.withTintColor(UIColor(named: "AccentColor")!)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(didTapMenu), for: .touchUpInside)
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

    func configure(searchBarDelegate: SearchBarDelegate,
                   menuDelegate: MenuDelegate) {
        self.searchBar.delegate = self
        self.searchBarDelegate = searchBarDelegate
        self.menuDelegate = menuDelegate
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
    private func didTapMenu() {
        menuDelegate?.didTapMenu()
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

        searchBarDelegate?.openBrowser(searchTerm: searchText)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let searchText = searchBar.lowercased else { return }
        searchBar.text = searchText

        searchBarDelegate?.searchSuggestions(searchTerm: searchText)
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBarDelegate?.openSuggestions(searchTerm: searchBar.lowercased ?? "")
    }
}
