// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

struct FxHomePocketCollectionCellUX {
    static let numberOfItemsInColumn = 3
    static let discoverMoreMaxFontSize: CGFloat = 26 // Title 3 xxxLarge
    static let numberOfItemsInSection = 11
    static let fractionalWidthiPhonePortrait: CGFloat = 29/30
    static let fractionalWidthiPhoneLanscape: CGFloat = 7/15
}

class FxHomePocketCollectionCell: UICollectionViewCell, ReusableCell {

    // MARK: - Properties
    var viewModel: FxHomePocketViewModel?

    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewCompositionalLayout(section: layoutSection)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(FxHomeHorizontalCell.self, forCellWithReuseIdentifier: FxHomeHorizontalCell.cellIdentifier)
        collectionView.register(FxHomePocketDiscoverMoreCell.self, forCellWithReuseIdentifier: FxHomePocketDiscoverMoreCell.cellIdentifier)

        return collectionView
    }()

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
        collectionView.addGestureRecognizer(longPressRecognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Helpers

    func reloadLayout() {
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout(section: layoutSection)
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
    }

    // MARK: - Private

    private func setupLayout() {
        contentView.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    private var layoutSection: NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(FxHomeHorizontalCellUX.cellHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: FxHomePocketViewModel.widthDimension,
            heightDimension: .estimated(FxHomeHorizontalCellUX.cellHeight)
        )

        let subItems = Array(repeating: item, count: FxHomePocketCollectionCellUX.numberOfItemsInColumn)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: subItems)
        group.interItemSpacing = FxHomeHorizontalCellUX.interItemSpacing
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0,
                                                      bottom: 0, trailing: FxHomeHorizontalCellUX.interGroupSpacing)

        let section = NSCollectionLayoutSection(group: group)

        section.orthogonalScrollingBehavior = .continuous
        return section
    }

    private lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    @objc fileprivate func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }

        let point = longPressGestureRecognizer.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point),
              let viewModel = viewModel, let onLongPressTileAction = viewModel.onLongPressTileAction
        else { return }

        let parentIndexPath = IndexPath(row: indexPath.row, section: viewModel.pocketShownInSection)
        onLongPressTileAction(parentIndexPath)
    }
}


// MARK: - UICollectionViewDataSource
extension FxHomePocketCollectionCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.numberOfCells ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let viewModel = viewModel else { return UICollectionViewCell() }

        if viewModel.isStoryCell(index: indexPath.row) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FxHomeHorizontalCell.cellIdentifier, for: indexPath) as! FxHomeHorizontalCell
            let pocketStory = viewModel.pocketStories[indexPath.row]
            let cellViewModel = FxHomeHorizontalCellViewModel(titleText: pocketStory.title, descriptionText: pocketStory.domain, tag: indexPath.item, hasFavicon: false)
            cell.configure(viewModel: cellViewModel)
            cell.setFallBackFaviconVisibility(isHidden: true)
            cell.heroImage.sd_setImage(with: pocketStory.imageURL)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FxHomePocketDiscoverMoreCell.cellIdentifier, for: indexPath) as! FxHomePocketDiscoverMoreCell
            cell.itemTitle.text = .PocketMoreStoriesText
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate
extension FxHomePocketCollectionCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewModel = viewModel, let showSiteWithURLHandler = viewModel.onTapTileAction else { return }

        if viewModel.isStoryCell(index: indexPath.row) {
            viewModel.recordTapOnStory(index: indexPath.row)

            let siteUrl = viewModel.pocketStories[indexPath.row].url
            showSiteWithURLHandler(siteUrl)

        } else {
            showSiteWithURLHandler(Pocket.MoreStoriesURL)
        }
    }
}


// MARK: - FxHomePocketDiscoverMoreCell
/// A cell to be placed at the last position in the Pocket section
class FxHomePocketDiscoverMoreCell: UICollectionViewCell, ReusableCell {

    let itemTitle: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .title3,
                                                                       maxSize: FxHomePocketCollectionCellUX.discoverMoreMaxFontSize)
        label.numberOfLines = 0
        label.textAlignment = .center
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: .zero)

        applyTheme()
        setupObservers()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        itemTitle.text = nil
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotifications), name: .DisplayThemeChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Helpers

    private func setupLayout() {
        contentView.layer.cornerRadius = FxHomeHorizontalCellUX.generalCornerRadius
        contentView.layer.shadowRadius = FxHomeHorizontalCellUX.stackViewShadowRadius
        contentView.layer.shadowOffset = CGSize(width: 0, height: FxHomeHorizontalCellUX.stackViewShadowOffset)
        contentView.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        contentView.layer.shadowOpacity = 0.12

        contentView.addSubviews(itemTitle)
        NSLayoutConstraint.activate([
            itemTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            itemTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            itemTitle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    @objc private func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default: break
        }
    }
}

extension FxHomePocketDiscoverMoreCell: NotificationThemeable {
    func applyTheme() {
        if LegacyThemeManager.instance.currentName == .dark {
            itemTitle.textColor = UIColor.Photon.LightGrey10
        } else {
            itemTitle.textColor = UIColor.Photon.DarkGrey90
        }

        contentView.backgroundColor = UIColor.theme.homePanel.recentlySavedBookmarkCellBackground
    }
}
