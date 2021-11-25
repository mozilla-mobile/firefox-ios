/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

class FxHomeHistoryHighlightsCollectionCell: UICollectionViewCell, ReusableCell {

    // MARK: - Properties
    var profile: Profile?
    var viewModel: FxHomeHistoryHightlightsVM?

    lazy var collectionView: UICollectionView = {
        let layout = FxHomeHistoryHighlightsCollectionCell.createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isScrollEnabled = true
        collectionView.alwaysBounceVertical = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.clipsToBounds = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(HistoryHighlightsCell.self, forCellWithReuseIdentifier: HistoryHighlightsCell.cellIdentifier)

        return collectionView
    }()

    // MARK: - Inits

    convenience init(frame: CGRect,
                     with profile: Profile,
                     and viewModel: FxHomeHistoryHightlightsVM) {
        self.init(frame: frame)
        setupLayout()

    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Helpers
    private func setupLayout() {
        contentView.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    public static func createLayout() -> UICollectionViewCompositionalLayout {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(65)))

        let groupWidth: NSCollectionLayoutDimension
        if UIScreen.main.traitCollection.horizontalSizeClass == .compact {
            groupWidth = NSCollectionLayoutDimension.fractionalWidth(1)
        } else {
            groupWidth = NSCollectionLayoutDimension.fractionalWidth(1/3)
        }

        let verticalGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(widthDimension: groupWidth,
                                               heightDimension: .estimated(65)),
            subitems: [item, item, item])

        let section = NSCollectionLayoutSection(group: verticalGroup)
        section.orthogonalScrollingBehavior = .continuous
        return UICollectionViewCompositionalLayout(section: section)
    }
}

extension FxHomeHistoryHighlightsCollectionCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let count = viewModel?.historyItems.count else {
            return 0
        }

        // If there are 3 or less tabs, we can return the standard count, as we don't need
        // to display filler cells. However, if there's more items, filler cells needs to be accounted
        // for so sections are always a multiple of 3 (since there's 3 cells per column).
        let numberOfItemsPerColumn = 3
        if count <= numberOfItemsPerColumn {
            return count
        } else {
            let numberOfColumns = ceil(Double(count) / Double(numberOfItemsPerColumn))
            // return the numberOfItemsInSection accounting for filler cells
            return Int(numberOfColumns) * numberOfItemsPerColumn
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HistoryHighlightsCell.cellIdentifier, for: indexPath) as! HistoryHighlightsCell
        let hideBottomLine = isBottomCell(indexPath: indexPath,
                                          totalItems: viewModel?.historyItems.count)
        let cornersToRound = determineCornerToRound(indexPath: indexPath,
                                                    totalItems: viewModel?.historyItems.count)

        // TODO: `item` can be either single groups or search groups. We must differentiate
        // here and then update accordingly.
        if let item = viewModel?.historyItems[safe: indexPath.row] {

            let itemURL = item.url?.absoluteString ?? ""
            let site = Site(url: itemURL, title: item.displayTitle, bookmarked: true)

            let cellOptions = RecentlyVisitedCellOptions(title: site.title,
                                                         shouldHideBottomLine: hideBottomLine,
                                                         with: cornersToRound,
                                                         and: nil,
                                                         andIsFillerCell: false)

            cell.updateCell(with: cellOptions)

        } else {
            let cellOptions = RecentlyVisitedCellOptions(shouldHideBottomLine: hideBottomLine,
                                                         with: cornersToRound,
                                                         andIsFillerCell: true)

            cell.updateCell(with: cellOptions)
        }

        return cell
    }

    // MARK: - Cell helper functions

    private func isBottomCell(indexPath: IndexPath, totalItems: Int?) -> Bool {
        guard let totalItems = totalItems else { return false }

        // One cell
        if totalItems == 1
            // Two cells AND index is bottom cell of the veritcal group
            || (totalItems == 2 && indexPath.row == 1)
            || (totalItems == 3 && indexPath.row == 2)
            // More than two cells AND is a bottom cell in the column
            || ((totalItems > 3 && totalItems <= 6) && ([2, 5].contains(indexPath.row)))
            || ((totalItems >= 7 && totalItems <= 9) && ([2, 5, 8].contains(indexPath.row))) {
            return true
        }

        return false
    }

    private func determineCornerToRound(indexPath: IndexPath, totalItems: Int?) -> UIRectCorner {
        guard let totalItems = totalItems else { return [] }
        var cornersToRound = UIRectCorner()

        if isTopLeftCell(index: indexPath.row, totalItems: totalItems) { cornersToRound.insert(.topLeft) }
        if isTopRightCell(index: indexPath.row, totalItems: totalItems) { cornersToRound.insert(.topRight) }
        if isBottomLeftCell(index: indexPath.row, totalItems: totalItems) { cornersToRound.insert(.bottomLeft) }
        if isBottomRightCell(index: indexPath.row, totalItems: totalItems) { cornersToRound.insert(.bottomRight) }

        return cornersToRound
    }

    private func isTopLeftCell(index: Int, totalItems: Int) -> Bool {
        if index == 0 { return true }

        return false
    }

    private func isTopRightCell(index: Int, totalItems: Int) -> Bool {
        if totalItems > 6 && index == 6 { return true }
        if totalItems > 3 && totalItems < 7 && index == 3 { return true }
        if totalItems <= 3 && index == 0 { return true }

        return false
    }

    private func isBottomLeftCell(index: Int, totalItems: Int) -> Bool {
        if totalItems >= 3 && index == 2 { return true }
        if totalItems == 2 && index == 1 { return true }
        if totalItems == 1 && index == 0 { return true }

        return false
    }

    private func isBottomRightCell(index: Int, totalItems: Int) -> Bool {
        if totalItems > 6 && index == 8 { return true }
        if totalItems > 3 && totalItems < 7 && index == 5 { return true }
        if totalItems == 3 && index == 2 { return true }
        if totalItems == 2 && index == 1 { return true }
        if totalItems == 1 && index == 0 { return true }

        return false
    }
}

extension FxHomeHistoryHighlightsCollectionCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        if let tab = viewModel.jumpableTabs[safe: indexPath.row] {
//            viewModel.switchTo(tab)
//        }
        print("section: \(indexPath.section) row: \(indexPath.row)")
    }
}
