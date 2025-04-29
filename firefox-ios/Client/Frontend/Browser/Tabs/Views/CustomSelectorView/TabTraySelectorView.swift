// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

protocol TabTraySelectorDelegate: AnyObject {
    func didSelectSection(panelType: TabTrayPanelType)
}

// MARK: - UX Constants
struct TabTraySelectorUX {
    static let cellSpacing: CGFloat = 4
    static let cellHorizontalPadding: CGFloat = 12
    static let cellVerticalPadding: CGFloat = 8
    static let estimatedCellWidth: CGFloat = 100
    static let cornerRadius: CGFloat = 12
    static let verticalInsets: CGFloat = 4
}

final class TabTraySelectorView: UIView,
                                 UICollectionViewDelegateFlowLayout,
                                 UICollectionViewDataSource,
                                 UIScrollViewDelegate,
                                 ThemeApplicable {
    weak var delegate: TabTraySelectorDelegate?

    private var theme: Theme
    private var selectedIndex: Int

    var items: [String] = [] {
        didSet {
            collectionView.reloadData()
            scrollToCenter()
        }
    }

    // MARK: - Layout & Views
    private lazy var layout: CenterSnappingFlowLayout = {
        let layout = CenterSnappingFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = TabTraySelectorUX.cellSpacing
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(TabTraySelectorCell.self, forCellWithReuseIdentifier: TabTraySelectorCell.cellIdentifier)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = .fast
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        return collectionView
    }()

    // MARK: - Init
    init(selectedIndex: Int,
         theme: Theme) {
        self.selectedIndex = selectedIndex
        self.theme = theme
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor, constant: -TabTraySelectorUX.verticalInsets),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: TabTraySelectorUX.verticalInsets),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        applyTheme(theme: theme)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let estimatedCellWidth = TabTraySelectorUX.estimatedCellWidth
        let horizontalInset = (bounds.width - estimatedCellWidth) / 2

        collectionView.contentInset = UIEdgeInsets(
            top: 0,
            left: horizontalInset,
            bottom: 0,
            right: horizontalInset
        )
        collectionView.contentOffset.x = -horizontalInset
    }

    // MARK: - Public Methods
    func scrollToCenter() {
        // Force it to always be centered on the center item,
        // temporary until this component is replaced with a simpler one
        let indexPath = IndexPath(item: 1, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }

    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TabTraySelectorCell.cellIdentifier,
                                                            for: indexPath) as? TabTraySelectorCell else {
            return UICollectionViewCell()
        }
        cell.configure(title: items[indexPath.item],
                       selected: indexPath.item == selectedIndex,
                       theme: theme,
                       position: indexPath.item,
                       total: indexPath.count)
        return cell
    }

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectNewSection(newIndex: indexPath.item)
    }

    func selectNewSection(newIndex: Int) {
        guard selectedIndex != newIndex else { return }
        selectedIndex = newIndex
        collectionView.reloadData()
        scrollToCenter()

        var panelType: TabTrayPanelType = .tabs
        if selectedIndex == 0 {
            panelType = .privateTabs
        } else if selectedIndex == 1 {
            panelType = .tabs
        } else if selectedIndex == 2 {
            panelType = .syncedTabs
        }
        delegate?.didSelectSection(panelType: panelType)
    }

    // MARK: - Themeable
    func applyTheme(theme: Theme) {
        self.theme = theme
        collectionView.backgroundColor = theme.colors.layer1
        backgroundColor = theme.colors.layer1
    }
}
