/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

struct JumpBackInCollectionCellUX {
    static let cellHeight: CGFloat = 100
    static let verticalCellSpacing: CGFloat = 8
    static let iPadHorizontalSpacing: CGFloat = 48
    static let iPadCellSpacing: CGFloat = 16
    static let generalSpacing: CGFloat = 8
    static let sectionInsetSpacing: CGFloat = 4
}

struct JumpBackInLayoutVariables {
    let columns: CGFloat
    let scrollDirection: UICollectionView.ScrollDirection
    let maxItemsToDisplay: Int
}

class FxHomeJumpBackInCollectionCell: UICollectionViewCell {

    // MARK: - Properties
    var profile: Profile!
    var viewModel: FirefoxHomeJumpBackInViewModel!
    lazy var siteImageHelper = SiteImageHelper(profile: profile)

    var layoutVariables: JumpBackInLayoutVariables {
        let horizontalVariables = JumpBackInLayoutVariables(columns: 2, scrollDirection: .horizontal, maxItemsToDisplay: 4)
        let verticalVariables = JumpBackInLayoutVariables(columns: 1, scrollDirection: .vertical, maxItemsToDisplay: 2)

        let deviceIsiPad = UIDevice.current.userInterfaceIdiom == .pad
        let deviceIsInLandscapeMode = UIWindow.isLandscape
        let horizontalSizeClassIsCompact = traitCollection.horizontalSizeClass == .compact

        if deviceIsiPad {
            if horizontalSizeClassIsCompact { return verticalVariables }
            return horizontalVariables

        } else {
            if deviceIsInLandscapeMode { return horizontalVariables }
            return verticalVariables
        }
    }

    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = layoutVariables.scrollDirection
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(JumpBackInCell.self, forCellWithReuseIdentifier: JumpBackInCell.cellIdentifier)

        return collectionView
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

extension FxHomeJumpBackInCollectionCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.updateDataAnd(layoutVariables)
        return viewModel.jumpList.itemsToDisplay
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JumpBackInCell.cellIdentifier, for: indexPath) as! JumpBackInCell
        cell.heroImage.image = nil
        cell.faviconImage.image = nil
        
        if indexPath.row == (viewModel.jumpList.itemsToDisplay - 1),
           let group = viewModel.jumpList.group {
            configureCellForGroups(group: group, cell: cell)
        } else {
            configureCellForTab(item: viewModel.jumpList.tabs[indexPath.row], cell: cell)
        }

        return cell
    }
    
    private func configureCellForGroups(group: ASGroup<Tab>, cell: JumpBackInCell) {
        let firstGroupItem = group.groupedItems.first
        let site = Site(url: firstGroupItem?.lastKnownUrl?.absoluteString ?? "", title: firstGroupItem?.lastTitle ?? "")
        let heroImageCacheKey = NSString(string: site.url)
        
        if let cachedImage = SiteImageHelper.cache.object(forKey: heroImageCacheKey) {
            cell.heroImage.image = cachedImage
        } else {
            siteImageHelper.fetchImageFor(site: site, imageType: .heroImage, shouldFallback: true) { image in
                cell.heroImage.image = image
            }
        }

        cell.itemTitle.text = group.searchTerm.localizedCapitalized
        cell.itemDetails.text = String(format: .FirefoxHomeJumpBackInSectionGroupSiteCount, group.groupedItems.count)
        cell.faviconImage.image = UIImage(imageLiteralResourceName: "recently_closed").withRenderingMode(.alwaysTemplate)
        cell.siteNameLabel.text = String.localizedStringWithFormat(.FirefoxHomeJumpBackInSectionGroupSiteCount, group.groupedItems.count)
    }
    
    private func configureCellForTab(item: Tab, cell: JumpBackInCell) {
        let itemURL = item.lastKnownUrl?.absoluteString ?? ""
        let site = Site(url: itemURL, title: item.displayTitle)
        
        cell.itemTitle.text = site.title
        cell.siteNameLabel.text = site.tileURL.shortDisplayString.capitalized
        
        profile.favicons.getFaviconImage(forSite: site).uponQueue(.main, block: { result in
            guard let image = result.successValue else { return }
            cell.faviconImage.image = image
            cell.setNeedsLayout()
        })
        
        let heroImageCacheKey = NSString(string: site.url)
        if let cachedImage = SiteImageHelper.cache.object(forKey: heroImageCacheKey) {
            cell.heroImage.image = cachedImage
        } else {
            siteImageHelper.fetchImageFor(site: site, imageType: .heroImage, shouldFallback: true) { image in
                cell.heroImage.image = image
            }
        }
    }
    
}

extension FxHomeJumpBackInCollectionCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == viewModel.jumpList.itemsToDisplay - 1,
           let group = viewModel.jumpList.group {
            viewModel.switchTo(group: group)

        } else {
            let tab = viewModel.jumpList.tabs[indexPath.row]
            viewModel.switchTo(tab: tab)
        }
    }
}

extension FxHomeJumpBackInCollectionCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        var itemWidth: CGFloat
        let totalHorizontalSpacing = collectionView.bounds.width
        let columns = layoutVariables.columns
        if columns == 2 {
            itemWidth = (totalHorizontalSpacing - JumpBackInCollectionCellUX.iPadHorizontalSpacing) / columns
        } else {
            itemWidth = totalHorizontalSpacing / columns
        }
        let itemSize = CGSize(width: itemWidth, height: JumpBackInCollectionCellUX.cellHeight)

        return itemSize
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return JumpBackInCollectionCellUX.verticalCellSpacing
        }

        return JumpBackInCollectionCellUX.iPadCellSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: JumpBackInCollectionCellUX.generalSpacing,
                            left: JumpBackInCollectionCellUX.sectionInsetSpacing,
                            bottom: JumpBackInCollectionCellUX.generalSpacing,
                            right: JumpBackInCollectionCellUX.sectionInsetSpacing)
    }
}

private struct JumpBackInCellUX {
    static let generalCornerRadius: CGFloat = 12
    static let titleFontSize: CGFloat = 17
    static let siteFontSize: CGFloat = 15
    static let detailsFontSize: CGFloat = 12
    static let labelsWrapperSpacing: CGFloat = 4
    static let stackViewSpacing: CGFloat = 8
    static let stackViewShadowRadius: CGFloat = 4
    static let stackViewShadowOffset: CGFloat = 2
    static let heroImageWidth: CGFloat = 108
    static let heroImageHeight: CGFloat = 80
}

// MARK: - JumpBackInCell
/// A cell used in FxHomeScreen's Jump Back In section.
class JumpBackInCell: UICollectionViewCell {

    // MARK: - Properties
    static let cellIdentifier = "jumpBackInCell"

    // UI
    let heroImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = JumpBackInCellUX.generalCornerRadius
        imageView.backgroundColor = .systemBackground
    }

    let itemTitle: UILabel = .build { label in
        label.adjustsFontSizeToFitWidth = false
        label.font = UIFont.systemFont(ofSize: JumpBackInCellUX.titleFontSize)
        label.numberOfLines = 2
    }

    let itemDetails: UILabel = .build { label in
        label.adjustsFontSizeToFitWidth = false
        label.font = UIFont.systemFont(ofSize: JumpBackInCellUX.detailsFontSize)
    }
    
    let faviconImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = JumpBackInCellUX.generalCornerRadius
    }
    
    let siteNameLabel: UILabel = .build { label in
        label.adjustsFontSizeToFitWidth = false
        label.font = UIFont.systemFont(ofSize: JumpBackInCellUX.siteFontSize)
        label.textColor = .label
    }

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: .zero)

        applyTheme()
        setupObservers()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Helpers
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotifications), name: .DisplayThemeChanged, object: nil)
    }

    private func setupLayout() {
        contentView.layer.cornerRadius = JumpBackInCellUX.generalCornerRadius
        contentView.layer.shadowRadius = JumpBackInCellUX.stackViewShadowRadius
        contentView.layer.shadowOffset = CGSize(width: 0, height: JumpBackInCellUX.stackViewShadowOffset)
        contentView.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        contentView.layer.shadowOpacity = 0.12

        contentView.addSubviews(heroImage, itemTitle, faviconImage, siteNameLabel)

        NSLayoutConstraint.activate([
            heroImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            heroImage.heightAnchor.constraint(equalToConstant: JumpBackInCellUX.heroImageHeight),
            heroImage.widthAnchor.constraint(equalToConstant: JumpBackInCellUX.heroImageWidth),
            heroImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            itemTitle.topAnchor.constraint(equalTo: heroImage.topAnchor),
            itemTitle.leadingAnchor.constraint(equalTo: heroImage.trailingAnchor, constant: 20),
            itemTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            faviconImage.leadingAnchor.constraint(equalTo: heroImage.trailingAnchor, constant: 20),
            faviconImage.bottomAnchor.constraint(equalTo: heroImage.bottomAnchor),
            faviconImage.heightAnchor.constraint(equalToConstant: 24),
            faviconImage.widthAnchor.constraint(equalToConstant: 24),
            
            siteNameLabel.leadingAnchor.constraint(equalTo: faviconImage.trailingAnchor, constant: 8),
            siteNameLabel.centerYAnchor.constraint(equalTo: faviconImage.centerYAnchor),
            siteNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
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

extension JumpBackInCell: Themeable {
    
    func applyTheme() {
        if ThemeManager.instance.currentName == .dark {
            [itemTitle, siteNameLabel, itemDetails].forEach { $0.textColor = UIColor.Photon.LightGrey10 }
            faviconImage.tintColor = UIColor.Photon.LightGrey10
            contentView.backgroundColor = UIColor.theme.homePanel.recentlySavedBookmarkCellBackground
        } else {
            [itemTitle, siteNameLabel, itemDetails].forEach { $0.textColor = UIColor.Photon.DarkGrey90 }
            faviconImage.tintColor = UIColor.Photon.DarkGrey90
            contentView.backgroundColor = UIColor.theme.homePanel.recentlySavedBookmarkCellBackground
        }
    }
    
}
