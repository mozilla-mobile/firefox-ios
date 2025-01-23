// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

// MARK: - UISearchBarDelegate
extension HistoryPanel: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text, !searchText.isEmpty else { return }

        // Do search and show
        performSearch(term: searchText)
        searchBar.resignFirstResponder()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.isSearchInProgress = !searchText.isEmpty

        guard let searchText = searchBar.text, !searchText.isEmpty else {
            handleEmptySearch()
            return
        }

        // Do cancelable search
        performSearch(term: searchText)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        bottomStackView.isHidden = true
        searchBar.resignFirstResponder()
    }

    func startSearchState() {
        updatePanelState(newState: .history(state: .search))
        bottomStackView.isHidden = false
        searchbar.becomeFirstResponder()
    }

    func exitSearchState() {
        viewModel.isSearchInProgress = false
        applySnapshot()
        self.searchbar.text = ""
        self.searchbar.resignFirstResponder()
        bottomStackView.isHidden = true
    }

    func performSearch(term: String) {
        viewModel.performSearch(term: term.lowercased()) { _ in
            self.applySearchSnapshot()
        }
    }

    func applySearchSnapshot() {
        // Create search results snapshot and apply
        var snapshot = NSDiffableDataSourceSnapshot<HistoryPanelSections, AnyHashable>()
        snapshot.appendSections([HistoryPanelSections.searchResults])
        snapshot.appendItems(self.viewModel.searchResultSites)
        self.diffableDataSource?.apply(snapshot, animatingDifferences: false)
        self.updateEmptyPanelState()
    }

    private func handleEmptySearch() {
        viewModel.searchResultSites.removeAll()
        applySnapshot()
        updateEmptyPanelState()
    }
}

// MARK: - KeyboardHelperDelegate
extension HistoryPanel: KeyboardHelperDelegate {
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        keyboardState = state
        updateLayoutForKeyboard()
        UIView.animate(
            withDuration: state.animationDuration,
            delay: 0,
            options: [UIView.AnimationOptions(rawValue: UInt(state.animationCurve.rawValue << 16))],
            animations: {
                self.bottomStackView.layoutIfNeeded()
            })
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        keyboardState = nil
        updateLayoutForKeyboard()
        UIView.animate(
            withDuration: state.animationDuration,
            delay: 0,
            options: [UIView.AnimationOptions(rawValue: UInt(state.animationCurve.rawValue << 16))],
            animations: {
                self.bottomStackView.layoutIfNeeded()
            })
    }
}
