/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

struct JumpBackInCollectionCellUX {
    static let cellHeight: CGFloat = 58
    static let verticalCellSpacing: CGFloat = 8
    static let iPadHorizontalSpacing: CGFloat = 16
}

struct JumpBackInLayoutVariables {
    let columns: CGFloat
    let scrollDirection: UICollectionView.ScrollDirection
    let maxItemsToDisplay: Int
}

class FxHomeJumpBackInCollectionCell: UICollectionViewCell {

    // MARK: - Properties
    var profile: Profile?
    var viewModel: FirefoxHomeJumpBackInViewModel!

    var layoutVariables: JumpBackInLayoutVariables {
        let horizontalVariables = JumpBackInLayoutVariables(columns: 2, scrollDirection: .horizontal, maxItemsToDisplay: 4)
        let verticalVariables = JumpBackInLayoutVariables(columns: 1, scrollDirection: .vertical, maxItemsToDisplay: 2)

        let deviceIsiPad = UIDevice.current.userInterfaceIdiom == .pad
        let deviceIsInLandscapeMode = UIApplication.shared.statusBarOrientation.isLandscape
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
        collectionView.clipsToBounds = false
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
        return viewModel.jumpableTabs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JumpBackInCell.cellIdentifier, for: indexPath) as! JumpBackInCell

        if let item = viewModel.jumpableTabs[safe: indexPath.row] {
            let itemURL = item.url?.absoluteString ?? ""
            let site = Site(url: itemURL, title: item.displayTitle, bookmarked: true)

            profile?.favicons.getFaviconImage(forSite: site).uponQueue(.main, block: { result in
                guard let image = result.successValue else { return }
                cell.heroImage.image = image
                cell.setNeedsLayout()
            })

            cell.itemTitle.text = site.title
            // TODO: Determine source string here, if from synced tabs. Simply update `cell.itemDetails.text`
        }

        return cell
    }
}

extension FxHomeJumpBackInCollectionCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let tab = viewModel.jumpableTabs[safe: indexPath.row] {
            viewModel.switchTo(tab)
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
        return JumpBackInCollectionCellUX.iPadHorizontalSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if UIDevice.current.userInterfaceIdiom == .phone { return 0 }
        return JumpBackInCollectionCellUX.verticalCellSpacing
    }
}

private struct JumpBackInCellUX {
    static let generalCornerRadius: CGFloat = 4
    static let titleFontSize: CGFloat = 17
    static let detailsFontSize: CGFloat = 12
    static let labelsWrapperSpacing: CGFloat = 4
    static let stackViewSpacing: CGFloat = 8
    static let stackViewShadowRadius: CGFloat = 4
    static let stackViewShadowOffset: CGFloat = 2
    static let heroImageDimension: CGFloat = 24
}

/// A cell used in FxHomeScreen's Jump Back In section.
class JumpBackInCell: UICollectionViewCell {

    // MARK: - Properties
    static let cellIdentifier = "jumpBackInCell"

    // UI
    let heroImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = JumpBackInCellUX.generalCornerRadius
    }

    let itemTitle: UILabel = .build { label in
        label.adjustsFontSizeToFitWidth = false
        label.font = UIFont.systemFont(ofSize: JumpBackInCellUX.titleFontSize)
    }

    let itemDetails: UILabel = .build { label in
        label.adjustsFontSizeToFitWidth = false
        label.font = UIFont.systemFont(ofSize: JumpBackInCellUX.detailsFontSize)
    }

    let stackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fillProportionally
        stackView.spacing = 2
        stackView.translatesAutoresizingMaskIntoConstraints = false
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

        stackView.addArrangedSubview(itemTitle)
        stackView.addArrangedSubview(itemDetails)
        contentView.addSubview(heroImage)
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            heroImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            heroImage.heightAnchor.constraint(equalToConstant: JumpBackInCellUX.heroImageDimension),
            heroImage.widthAnchor.constraint(equalToConstant: JumpBackInCellUX.heroImageDimension),
            heroImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            itemTitle.heightAnchor.constraint(equalToConstant: 22),
            itemDetails.heightAnchor.constraint(lessThanOrEqualToConstant: 16),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: heroImage.trailingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
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
        contentView.backgroundColor = UIColor.theme.homePanel.recentlySavedBookmarkCellBackground
        itemDetails.textColor = UIColor.theme.homePanel.activityStreamCellDescription
    }
}
