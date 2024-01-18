// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol SearchSuggestionDelegate: AnyObject {
    func tapOnSuggestion(term: String)
    func openBrowser(searchTerm: String)
}

class SearchViewController: UIViewController, SuggestionViewControllerDelegate {
    weak var searchViewDelegate: SearchSuggestionDelegate?
    private var suggestionVC: SuggestionViewController
    let viewModel = SearchViewModel()

    // MARK: - Init

    init() {
        self.suggestionVC = SuggestionViewController()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSuggestionView()
    }

    private func configureSuggestionView() {
        suggestionVC.view.translatesAutoresizingMaskIntoConstraints = false
        add(suggestionVC)

        NSLayoutConstraint.activate([
            suggestionVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            suggestionVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            suggestionVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        suggestionVC.configure(dataSource: SuggestionDataSource(), delegate: self)
    }

    // MARK: - Search

    func requestSearch(term: String) {
        viewModel.requestSearch(searchTerm: term, completion: { [weak self] error in
            if let error = error, let self = self {
                UIAlertController.showError(errorMessage: error.message, controller: self)
                return
            }

            guard let searchSuggestions = self?.viewModel.searchModel?.suggestions,
                  !searchSuggestions.isEmpty else { return }

            self?.suggestionVC.updateUI(for: searchSuggestions)
        })
    }

    func openSuggestions() {
        suggestionVC.updateUI(for: self.viewModel.searchModel?.suggestions ?? [String]())
    }

    private func toggleSuggestionView(isShown: Bool) {
        suggestionVC.view.isHidden = !isShown
    }

    // MARK: - SuggestionViewControllerDelegate

    func tapOnSuggestion(term: String) {
        searchViewDelegate?.tapOnSuggestion(term: term)
    }
}
