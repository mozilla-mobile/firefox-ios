// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import UIKit

private struct WallpaperSettingsUX {
    static let collectionTitleFontMaxSize = 43.0
    static let switchTitleFontMaxSize = 53.0
    static let switchDescriptionFontMaxSize = 43.0
    
    struct FractionalWidths {
        static let third: CGFloat = 1/3
        static let quarter: CGFloat = 1/4
        static let sixth: CGFloat = 1/6
    }
    
    static let inset: CGFloat = 3.5
}

class WallpaperSettingsViewController: UIViewController {

    // MARK: - UIElements
    // Collection View
    private lazy var collectionTitle: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.preferredFont(
            withTextStyle: .caption1,
            maxSize: WallpaperSettingsUX.collectionTitleFontMaxSize)
        label.adjustsFontForContentSizeCategory = true
        label.text = .Settings.Homepage.Wallpaper.CollectionTitle
    }

    private lazy var collectionContainer: UIView = .build { _ in }

    private lazy var collectionView: DynamicHeightCollectionView = {
        let collectionView = DynamicHeightCollectionView(frame: .zero,
                                                         collectionViewLayout: getCompositionalLayout())

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
    
    // Switch
    private lazy var switchContainer: UIView = .build { _ in }

    private lazy var switchTitle: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.preferredFont(
            withTextStyle: .body,
            maxSize: WallpaperSettingsUX.switchTitleFontMaxSize)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.text = .Settings.Homepage.Wallpaper.SwitchTitle
    }

    private lazy var logoSwitch: UISwitch = .build { toggle in
        toggle.addTarget(self,
                         action: #selector(self.didChangeSwitchState(_:)),
                         for: .valueChanged)
        toggle.accessibilityLabel = .Settings.Homepage.Wallpaper.AccessibilityLabels.ToggleButton
    }

    private lazy var switchLine: UIView = .build { _ in }

    private lazy var switchDescription: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.preferredFont(
            withTextStyle: .caption1,
            maxSize: WallpaperSettingsUX.switchDescriptionFontMaxSize)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.text = .Settings.Homepage.Wallpaper.SwitchDescription
    }

    // MARK: - Variables
    var notificationCenter: NotificationCenter
    private var viewModel: WallpaperSettingsViewModel

    // MARK: - Initializers
    init(with viewModel: WallpaperSettingsViewModel,
         and notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.viewModel = viewModel
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = .Settings.Homepage.Wallpaper.PageTitle
        setupView()
        setupCurrentState()
        applyTheme()
        setupNotifications(forObserver: self,
                           observing: [.DisplayThemeChanged])
        reloadLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.layoutIfNeeded()
    }

    override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        reloadLayout()
    }
    
    // MARK: - View setup
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
            collectionTitle.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            collectionTitle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 19),
            collectionTitle.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            collectionContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionContainer.topAnchor.constraint(equalTo: collectionTitle.bottomAnchor, constant: 9),
            collectionContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            collectionView.leadingAnchor.constraint(equalTo: collectionContainer.leadingAnchor, constant: 28),
            collectionView.topAnchor.constraint(equalTo: collectionContainer.topAnchor, constant: 32),
            collectionView.trailingAnchor.constraint(equalTo: collectionContainer.trailingAnchor, constant: -28),
            collectionView.bottomAnchor.constraint(equalTo: collectionContainer.bottomAnchor, constant: -32),
            collectionView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),

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
        logoSwitch.isOn = viewModel.wallpaperManager.switchWallpaperFromLogoEnabled
    }
    
    private func highlightCurrentlySelectedCell() {
        guard let rowIndex = viewModel.wallpaperManager.currentlySelectedWallpaperIndex else { return }
        let currentIndex = IndexPath(row: rowIndex, section: 0)
        collectionView.selectItem(at: currentIndex,
                                  animated: false,
                                  scrollPosition: [])
    }
    
    private func reloadLayout() {
        collectionView.collectionViewLayout = getCompositionalLayout()
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
        highlightCurrentlySelectedCell()
    }
    
    private func getCompositionalLayout() -> UICollectionViewCompositionalLayout {
        typealias FractionalWidths = WallpaperSettingsUX.FractionalWidths
        
        let deviceFractionalWidth: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? FractionalWidths.quarter : FractionalWidths.third
        let fractionalWidth: CGFloat = UIDevice.current.orientation.isLandscape ? FractionalWidths.sixth : deviceFractionalWidth
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(fractionalWidth),
            heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: WallpaperSettingsUX.inset,
                                                     leading: WallpaperSettingsUX.inset,
                                                     bottom: WallpaperSettingsUX.inset,
                                                     trailing: WallpaperSettingsUX.inset)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalWidth(fractionalWidth))
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }

    // MARK: - Actions
    @objc func didChangeSwitchState(_ sender: UISwitch!) {
        viewModel.wallpaperManager.switchWallpaperFromLogoEnabled = sender.isOn
        let extras = [TelemetryWrapper.EventExtraKey.preferenceChanged.rawValue: sender.isOn ? "on" : "off"]
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .change,
                                     object: .wallpaperSettings,
                                     value: .toggleLogoWallpaperButton,
                                     extras: extras)
    }

    private func showToast() {
        let toast = ButtonToast(
            labelText: WallpaperSettingsViewModel.Constants.Strings.Toast.label,
            buttonText: WallpaperSettingsViewModel.Constants.Strings.Toast.button,
            completion: { buttonPressed in

            if buttonPressed { self.dismissView() }
        })

        toast.showToast(viewController: self,
                        delay: SimpleToastUX.ToastDelayBefore,
                        duration: SimpleToastUX.ToastDismissAfter) { toast in
            [
                toast.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                toast.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                toast.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ]
        }
    }

    private func dismissView() {
        guard let navigationController = self.navigationController as? ThemedNavigationController else { return }

        if let isFxHomeTab = viewModel.tabManager.selectedTab?.isFxHomeTab, !isFxHomeTab {
            viewModel.tabManager.selectTab(viewModel.tabManager.addTab())
        }

        navigationController.done()
    }
}

// MARK: - Notifications
extension WallpaperSettingsViewController: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default:
            break
        }
    }
}

// MARK: - Collection View Data Source
extension WallpaperSettingsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.wallpaperManager.numberOfWallpapers
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WallpaperSettingCollectionCell.cellIdentifier, for: indexPath) as! WallpaperSettingCollectionCell
        let image = viewModel.wallpaperManager.getImageAt(index: indexPath.row, inLandscape: UIDevice.current.orientation.isLandscape)
        cell.updateImage(to: image)
        cell.isAccessibilityElement = true
        cell.accessibilityTraits = .button
        cell.accessibilityLabel = viewModel.wallpaperManager.getAccessibilityLabelForWallpaper(at: indexPath.row)

        return cell
    }
}

// MARK: - Collection View Delegate
extension WallpaperSettingsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) { cell.isSelected = true }
        viewModel.wallpaperManager.updateSelectedWallpaperIndex(to: indexPath.row)
        showToast()

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .wallpaperSettings,
                                     value: .wallpaperSelected,
                                     extras: viewModel.wallpaperManager.currentWallpaper.telemetryMetadata)
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
