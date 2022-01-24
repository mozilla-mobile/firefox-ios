// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import UIKit

fileprivate struct WallpaperSettingsUX {
    static let collectionTitleFontMaxSize = 40.0
    static let switchTitleFontMaxSize = 46.0
    static let switchDescriptionFontMaxSize = 34.0
}

class WallpaperSettingsViewController: UIViewController {

    // MARK: - UIElements
    // Collection View
    lazy var collectionTitle: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.preferredFont(
            withTextStyle: .caption1,
            maxSize: WallpaperSettingsUX.collectionTitleFontMaxSize)
        label.adjustsFontForContentSizeCategory = true
        label.text = .Settings.Homepage.Wallpaper.CollectionTitle
    }

    lazy var collectionContainer: UIView = .build { _ in }

    lazy var collectionView: DynamicHeightCollectionView = {
        let collectionView = DynamicHeightCollectionView(
            frame: .zero,
            collectionViewLayout: UICollectionViewFlowLayout())

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            WallpaperSettingCollectionCell.self,
            forCellWithReuseIdentifier: WallpaperSettingCollectionCell.cellIdentifier)

        return collectionView
    }()

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

    // Switch
    lazy var switchContainer: UIView = .build { _ in }

    lazy var switchTitle: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.preferredFont(
            withTextStyle: .body,
            maxSize: WallpaperSettingsUX.switchTitleFontMaxSize)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.text = .Settings.Homepage.Wallpaper.SwitchTitle
    }

    lazy var logoSwitch: UISwitch = .build { toggle in
        toggle.addTarget(self,
                         action: #selector(self.didChangeSwitchState(_:)),
                         for: .valueChanged)
    }

    lazy var switchLine: UIView = .build { _ in }

    lazy var switchDescription: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.preferredFont(
            withTextStyle: .caption1,
            maxSize: WallpaperSettingsUX.switchTitleFontMaxSize)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.text = .Settings.Homepage.Wallpaper.SwitchDescription
    }

    // MARK: - Variables
    var profile: Profile
    var wallpaperManager: WallpaperManager

    // MARK: - Initializers
    init(with profile: Profile, and wallpaperManager: WallpaperManager = WallpaperManager()) {
        self.profile = profile
        self.wallpaperManager = wallpaperManager
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = .Settings.Homepage.Wallpaper.PageTitle
        setupView()
        setupCurrentState()
        applyTheme()
        setupNotifications()
        collectionView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.layoutIfNeeded()
        guard let rowIndex = wallpaperManager.currentIndex else { return }
        let currentIndex = IndexPath(row: rowIndex, section: 0)
        collectionView.selectItem(at: currentIndex,
                                  animated: false,
                                  scrollPosition: [])
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupView() {
        view.addSubview(collectionTitle)
        collectionContainer.addSubview(collectionView)
        view.addSubview(collectionContainer)

        switchContainer.addSubview(switchTitle)
        switchContainer.addSubview(logoSwitch)
        switchContainer.addSubview(switchLine)
        switchContainer.addSubview(switchDescription)
        view.addSubview(switchContainer)

        NSLayoutConstraint.activate([
            // Collection View
            collectionTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionTitle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 19),
            collectionTitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            collectionContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionContainer.topAnchor.constraint(equalTo: collectionTitle.bottomAnchor, constant: 9),
            collectionContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            collectionContainer.heightAnchor.constraint(equalToConstant: 285),

            collectionView.leadingAnchor.constraint(equalTo: collectionContainer.leadingAnchor, constant: 28),
            collectionView.topAnchor.constraint(equalTo: collectionContainer.topAnchor, constant: 32),
            collectionView.trailingAnchor.constraint(equalTo: collectionContainer.trailingAnchor, constant: -28),
            collectionView.bottomAnchor.constraint(equalTo: collectionContainer.bottomAnchor, constant: -32),

            // Switch View
            logoSwitch.trailingAnchor.constraint(equalTo: switchContainer.trailingAnchor, constant: -16),
            logoSwitch.centerYAnchor.constraint(equalTo: switchContainer.centerYAnchor),

            switchTitle.leadingAnchor.constraint(equalTo: switchContainer.leadingAnchor, constant: 16),
            switchTitle.topAnchor.constraint(equalTo: switchContainer.topAnchor, constant: 11),
            switchTitle.trailingAnchor.constraint(equalTo: logoSwitch.leadingAnchor, constant: -8),
            switchTitle.bottomAnchor.constraint(equalTo: switchContainer.bottomAnchor, constant: -11),

            switchLine.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            switchLine.topAnchor.constraint(equalTo: switchContainer.bottomAnchor),
            switchLine.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            switchLine.heightAnchor.constraint(equalToConstant: 0.5),

            switchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            switchContainer.topAnchor.constraint(equalTo: collectionContainer.bottomAnchor, constant: 8),
            switchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            switchDescription.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 17),
            switchDescription.topAnchor.constraint(equalTo: switchLine.bottomAnchor, constant: 8),
            switchDescription.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -17),
            switchDescription.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
    }

    private func setupCurrentState() {
        logoSwitch.isOn = wallpaperManager.switchWallpaperFromLogoEnabled
    }

    // MARK: - Notifications
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleNotifications),
                                               name: .DisplayThemeChanged,
                                               object: nil)
    }

    @objc private func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default:
            break
        }
    }

    // MARK: - Actions
    @objc func didChangeSwitchState(_ sender: UISwitch!) {
        wallpaperManager.switchWallpaperFromLogoEnabled = sender.isOn
    }

}

extension WallpaperSettingsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width/3) - 6
        return CGSize(width: width,
                      height: (width/1.1) - 6)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
}

// MARK: - Collection View Data Source
extension WallpaperSettingsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return wallpaperManager.wallpapers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WallpaperSettingCollectionCell.cellIdentifier, for: indexPath) as! WallpaperSettingCollectionCell
        
        cell.updateImage(to: wallpaperManager.wallpapers[indexPath.row].image)

        return cell
    }
}

// MARK: - Collection View Delegate
extension WallpaperSettingsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) { cell.isSelected = true }
        wallpaperManager.updateTo(index: indexPath.row)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) { cell.isSelected = false }
    }

}

// MARK: - Themable
extension WallpaperSettingsViewController: NotificationThemeable {
    func applyTheme() {
        view.backgroundColor = UIColor.theme.homePanel.topSitesBackground

        collectionTitle.textColor = UIColor.theme.tableView.headerTextLight
        collectionContainer.backgroundColor = UIColor.theme.homePanel.recentlySavedBookmarkCellBackground

        switchContainer.backgroundColor = UIColor.theme.homePanel.recentlySavedBookmarkCellBackground
        logoSwitch.tintColor = UIColor.theme.etpMenu.switchAndButtonTint
        logoSwitch.onTintColor = UIColor.theme.etpMenu.switchAndButtonTint
        switchLine.backgroundColor = UIColor.theme.etpMenu.horizontalLine
        switchDescription.textColor = UIColor.theme.tableView.headerTextLight
    }
}
