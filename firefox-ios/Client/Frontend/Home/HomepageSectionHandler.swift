// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// Protocol for each section in Firefox Home page view controller
// to handle click and cell setup
protocol HomepageSectionHandler {
    func configure(_ collectionView: UICollectionView,
                   at indexPath: IndexPath) -> UICollectionViewCell

    func configure(_ cell: UICollectionViewCell,
                   at indexPath: IndexPath) -> UICollectionViewCell

    @MainActor
    func didSelectItem(at indexPath: IndexPath,
                       homePanelDelegate: HomePanelDelegate?,
                       libraryPanelDelegate: LibraryPanelDelegate?)

    func handleLongPress(with collectionView: UICollectionView, indexPath: IndexPath)
}

extension HomepageSectionHandler {
    // Default configure use the FirefoxHomeSectionType cellIdentifier, when there's only one cell type in that section
    func configure(_ collectionView: UICollectionView, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let viewModel = self as? HomepageViewModelProtocol else { return UICollectionViewCell() }

        let identifier = viewModel.sectionType.cellIdentifier
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        return configure(cell, at: indexPath)
    }

    func didSelectItem(at indexPath: IndexPath,
                       homePanelDelegate: HomePanelDelegate?,
                       libraryPanelDelegate: LibraryPanelDelegate?) {
        // Action on cell is sometimes handled with a button, or gesture recognizers with closures
    }

    func handleLongPress(with collectionView: UICollectionView, indexPath: IndexPath) {
        // Not all sections have long press
    }
}
