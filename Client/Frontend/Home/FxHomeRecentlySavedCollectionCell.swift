// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Storage

struct RecentlySavedCollectionCellUX {
    static let bookmarkItemsLimit: UInt = 5
    static let readingListItemsLimit: Int = 5
    static let cellWidth: CGFloat = 150
    static let cellHeight: CGFloat = 110
    static let generalSpacing: CGFloat = 8
    static let iPadGeneralSpacing: CGFloat = 8
}

/// A cell serving as a collectionView to hold its associated recently saved cells.
class FxHomeRecentlySavedCollectionCell: UICollectionViewCell, ReusableCell {
    
    // MARK: - Properties
    
    weak var homePanelDelegate: HomePanelDelegate?
    weak var libraryPanelDelegate: LibraryPanelDelegate?

    var viewModel: FirefoxHomeRecentlySavedViewModel!
    
    // UI
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: compositionalLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(RecentlySavedCell.self,
                                forCellWithReuseIdentifier: RecentlySavedCell.cellIdentifier)
        
        return collectionView
    }()

    private lazy var compositionalLayout: UICollectionViewCompositionalLayout = {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(RecentlySavedCollectionCellUX.cellWidth),
            heightDimension: .estimated(RecentlySavedCollectionCellUX.cellHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(RecentlySavedCollectionCellUX.cellWidth),
            heightDimension: .fractionalHeight(1)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        section.interGroupSpacing = isIPad ? RecentlySavedCollectionCellUX.iPadGeneralSpacing: RecentlySavedCollectionCellUX.generalSpacing
        section.orthogonalScrollingBehavior = .continuous

        return UICollectionViewCompositionalLayout(section: section)
    }()
    
    // MARK: - Inits
    
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
}

extension FxHomeRecentlySavedCollectionCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.recentItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecentlySavedCell.cellIdentifier, for: indexPath) as! RecentlySavedCell
        cell.tag = indexPath.row

        if let item = viewModel.recentItems[safe: indexPath.row] {
            let site = Site(url: item.url, title: item.title, bookmarked: true)
            cell.itemTitle.text = site.title
            viewModel.getHeroImage(forSite: site) { image in
                guard cell.tag == indexPath.row else { return }
                cell.heroImage.image = image
            }
        }
        
        return cell
    }
}

extension FxHomeRecentlySavedCollectionCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = viewModel.recentItems[safe: indexPath.row] as? BookmarkItem {
            guard let url = URIFixup.getURL(item.url) else { return }
            
            homePanelDelegate?.homePanel(didSelectURL: url, visitType: .bookmark, isGoogleTopSite: false)
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .recentlySavedBookmarkItemAction,
                                         extras: TelemetryWrapper.getOriginExtras(isZeroSearch: viewModel.isZeroSearch))
        } else if let item = viewModel.recentItems[safe: indexPath.row] as? ReadingListItem,
                  let url = URL(string: item.url),
                  let encodedUrl = url.encodeReaderModeURL(WebServer.sharedInstance.baseReaderModeURL()) {
            
            let visitType = VisitType.bookmark
            libraryPanelDelegate?.libraryPanel(didSelectURL: encodedUrl, visitType: visitType)
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .recentlySavedReadingListAction,
                                         extras: TelemetryWrapper.getOriginExtras(isZeroSearch: viewModel.isZeroSearch))
        }
        
    }
}

private struct RecentlySavedCellUX {
    static let generalCornerRadius: CGFloat = 12
    // TODO: Limiting font size to AX2 until we use compositional layout in all Firefox HomePage. Should be AX5.
    static let bookmarkTitleMaxFontSize: CGFloat = 26 // Style caption1 - AX2
    static let generalSpacing: CGFloat = 8
    static let heroImageHeight: CGFloat = 92
    static let heroImageWidth: CGFloat = 110
    static let recentlySavedCellShadowRadius: CGFloat = 4
    static let recentlySavedCellShadowOffset: CGFloat = 2
}

/// A cell used in FxHomeScreen's Recently Saved section. It holds bookmarks and reading list items.
class RecentlySavedCell: UICollectionViewCell, ReusableCell, NotificationThemeable {
    
    // MARK: - UI Elements
    let heroImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = RecentlySavedCellUX.generalCornerRadius
        imageView.backgroundColor = .systemBackground
    }

    let itemTitle: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption1,
                                                                   maxSize: RecentlySavedCellUX.bookmarkTitleMaxFontSize)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
    }
    
    // MARK: - Inits
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        setupLayout()
        setupNotifications()
        applyTheme()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        heroImage.image = nil
        itemTitle.text = nil
        applyTheme()
    }
    
    // MARK: - Helpers
    
    private func setupLayout() {
        contentView.layer.cornerRadius = RecentlySavedCellUX.generalCornerRadius
        contentView.layer.shadowRadius = RecentlySavedCellUX.recentlySavedCellShadowRadius
        contentView.layer.shadowOffset = CGSize(width: 0, height: RecentlySavedCellUX.recentlySavedCellShadowOffset)
        contentView.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        contentView.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
        
        contentView.addSubviews(heroImage, itemTitle)
        
        NSLayoutConstraint.activate([
            heroImage.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            heroImage.heightAnchor.constraint(equalToConstant: RecentlySavedCellUX.heroImageHeight),
            heroImage.widthAnchor.constraint(equalToConstant: RecentlySavedCellUX.heroImageWidth),
            
            itemTitle.topAnchor.constraint(equalTo: heroImage.bottomAnchor, constant: RecentlySavedCellUX.generalSpacing),
            itemTitle.leadingAnchor.constraint(equalTo: heroImage.leadingAnchor),
            itemTitle.trailingAnchor.constraint(equalTo: heroImage.trailingAnchor)
        ])
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotifications), name: .DisplayThemeChanged, object: nil)
    }
    
    @objc private func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default:
            break
        }
    }
    
    func applyTheme() {
        if LegacyThemeManager.instance.currentName == .dark {
            itemTitle.textColor = UIColor.Photon.LightGrey10
        } else {
            itemTitle.textColor = UIColor.Photon.DarkGrey90
        }
    }
    
}
