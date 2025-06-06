// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class MenuCollectionView: UITableViewCell,
                                UICollectionViewDelegate,
                                UICollectionViewDataSource,
                                UICollectionViewDelegateFlowLayout,
                                ReusableCell,
                                ThemeApplicable {
    private struct UX {
        static let minimumLineSpacing: CGFloat = 16
    }

    private var collectionView: UICollectionView
    private var menuData: [MenuSection]
    private var theme: Theme?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = UX.minimumLineSpacing

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false

        menuData = []
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        setupCollectionView()
        setupUI()
    }

    private func setupUI() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: self.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }

    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(
            MenuSquareCell.self,
            forCellWithReuseIdentifier: MenuSquareCell.cellIdentifier
        )
    }

    func setupAccessibilityIdentifiers(menuA11yId: String, menuA11yLabel: String) {
        collectionView.accessibilityIdentifier = menuA11yId
        collectionView.accessibilityLabel = menuA11yLabel
    }

    // MARK: - UICollectionView Methods
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        guard let section = menuData.first(where: { $0.isHorizontalTabsSection }) else { return 0 }
        return section.options.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MenuSquareCell.cellIdentifier,
            for: indexPath
        ) as? MenuSquareCell else {
            return UICollectionViewCell()
        }

        guard let section = menuData.first(where: { $0.isHorizontalTabsSection }) else { return UICollectionViewCell() }
        cell.configureCellWith(model: section.options[indexPath.row])
        if let theme { cell.applyTheme(theme: theme) }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        guard let section = menuData.first(where: { $0.isHorizontalTabsSection }),
              let action = section.options[indexPath.row].action else { return }
        action()
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let section = menuData.first(where: { $0.isHorizontalTabsSection }) else { return .zero }
        let itemCount = section.options.count
        let width = (collectionView.bounds.width - CGFloat(itemCount - 1) * UX.minimumLineSpacing) / CGFloat(itemCount)
        let height = collectionView.bounds.height
        return CGSize(width: width, height: height)
    }

    func reloadCollectionView(with data: [MenuSection]) {
        menuData = data
        collectionView.reloadData()
    }

    // MARK: - Theme Applicable
    func applyTheme(theme: Theme) {
        self.theme = theme
        backgroundColor = .clear
        collectionView.backgroundColor = .clear
    }
}
