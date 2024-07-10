//// This Source Code Form is subject to the terms of the Mozilla Public
//// License, v. 2.0. If a copy of the MPL was not distributed with this
//// file, You can obtain one at http://mozilla.org/MPL/2.0/
//
//import Shared
//import UIKit
//import Common
//import ComponentLibrary
//import SiteImageView
//
//extension TrackingProtectionViewController_ {
//    enum Section {
//        case trackers
//        case clearCookies
//    }
//
//    enum Item: Hashable {
//        case image
//        case trackersBlocked
//        case secureConnection
//        case enchancedTracking
//        case clearCookies
//    }
//}
//
//struct CellItem {
//    let title: String
//    let detail: String
//}
//
//@available(iOS 14.0, *)
//class TrackingProtectionViewController_: UIViewController, BottomSheetChild {
//    var asPopover = false
//    let windowUUID: WindowUUID
//    var currentWindowUUID: UUID? { windowUUID }
//    var themeManager: ThemeManager
//    var themeObserver: NSObjectProtocol?
//    var notificationCenter: NotificationProtocol
//    weak var enhancedTrackingProtectionMenuDelegate: TrackingProtectionMenuDelegate?
//    private var viewModel: TrackingProtectionViewModel
//
//    private var collectionView: UICollectionView!
//    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
//
//    // MARK: - View lifecycle
//
//    init(viewModel: TrackingProtectionViewModel,
//         windowUUID: WindowUUID,
//         themeManager: ThemeManager = AppContainer.shared.resolve(),
//         notificationCenter: NotificationProtocol = NotificationCenter.default) {
//        self.viewModel = viewModel
//        self.windowUUID = windowUUID
//        self.themeManager = themeManager
//        self.notificationCenter = notificationCenter
//        super.init(nibName: nil, bundle: nil)
//    }
//
//    func willDismiss() {
//        
//    }
//
//    @available(*, unavailable)
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupCollectionView()
//        configureDataSource()
//    }
//
//    private func setupCollectionView() {
//        collectionView = UICollectionView(
//            frame: .zero,
//            collectionViewLayout: 
//                UICollectionViewCompositionalLayout.list(
//                using: UICollectionLayoutListConfiguration(
//                    appearance: .insetGrouped
//                )
//            )
//        )
//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(collectionView)
//
//        NSLayoutConstraint.activate([
//            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
//            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
//    }
//
//    private func configureDataSource() {
//        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { [weak self] cell, indexPath, item in
//            guard let self = self else { return }
//            self.configure(cell: cell, indexPath: indexPath, item: item)
//        }
//
//        self.dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: self.collectionView) { collectionView, indexPath, item in
//            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
//        }
//
//        let snapshot = NSDiffableDataSourceSnapshot<Section, Item>(model: TrackingProtectionViewModel_())
//        dataSource.apply(snapshot, animatingDifferences: true)
//    }
//
//    private func configure(cell: UICollectionViewListCell, indexPath: IndexPath, item: Item) {
//        var configuration = cell.defaultContentConfiguration()
//        defer { cell.contentConfiguration = configuration }
//
//        switch item {
//        case .image:
//            let sfconfiguration = UIImage.SymbolConfiguration(textStyle: .title1)
//            let image = UIImage(systemName: "star", withConfiguration: sfconfiguration)
//            configuration.image = image
//            configuration.imageProperties.reservedLayoutSize = CGSize(width: 100, height: 100)
//
//            configuration.text = "Firefox is on guard"
//            configuration.secondaryText = "You’re protected. If we spot something, we’ll let you know."
//
//            configuration.textToSecondaryTextVerticalPadding = 8
//
//            var b = UIBackgroundConfiguration.listPlainCell()
//            b.backgroundColor = .purple.withAlphaComponent(0.4)
//            cell.backgroundConfiguration = b
//        case .trackersBlocked:
//            configuration.text = "5 Trackers blocked"
//            cell.accessories.append(
//                .customView(
//                    configuration: UICellAccessory.CustomViewConfiguration(
//                        customView: UIImageView(image: UIImage(systemName: "shield")!),
//                        placement: .leading(displayed: .always),
//                        reservedLayoutWidth: .custom(8)
//                    )
//                )
//            )
//            cell.accessories.append(
//                .disclosureIndicator(
//                    options: .init(
//                        tintColor: .systemGray
//                    )
//                )
//            )
//        case .secureConnection:
//            configuration.text = "Secure connection"
//            cell.accessories.append(
//                .customView(
//                    configuration: UICellAccessory.CustomViewConfiguration(
//                        customView: UIImageView(image: UIImage(systemName: "lock")!),
//                        placement: .leading(displayed: .always),
//                        reservedLayoutWidth: .custom(8)
//                    )
//                )
//            )
//            cell.accessories.append(
//                .disclosureIndicator(
//                    options: .init(
//                        tintColor: .systemGray
//                    )
//                )
//            )
//        case .enchancedTracking:
//            configuration.text = "Enhanced Tracking Protection"
//            configuration.secondaryText = "If something looks broken on this site, try turning it off."
//            cell.accessories = [
//                .customView(
//                    configuration: UICellAccessory.CustomViewConfiguration(
//                        customView: UISwitch(),
//                        placement: .trailing(displayed: .always)
//                    )
//                )
//            ]
//        case .clearCookies:
//            configuration.text = "Clear cookies and site data"
//        }
//    }
//}
//
//import SwiftUI
////
////// This is the UIViewControllerRepresentable implementation.
//struct TrackingProtectionViewController_Representable: UIViewControllerRepresentable {
//    // Required method to create the UIViewController.
//    func makeUIViewController(context: Context) -> TrackingProtectionViewController_ {
//        let etpViewModel = TrackingProtectionViewModel(
//            url: URL(string: "test.com")!,
//            displayTitle: "displayTitle",
//            connectionSecure: true,
//            globalETPIsEnabled: true,
//            contentBlockerStatus: .blocking,
//            contentBlockerStats: TPPageStats()
//        )
//        return TrackingProtectionViewController_(viewModel: etpViewModel, windowUUID: UUID())
//    }
//
//    // Required method to update _ the UIViewController.
//    func updateUIViewController( _ uiViewController: TrackingProtectionViewController_, context: Context) {
//        // No update logic needed for this static preview
//    }
//}
//
//struct TrackingProtectionViewController_Previews: PreviewProvider {
//    static var previews: some View {
//        TrackingProtectionViewController_Representable()
//    }
//}
//
//class TrackingProtectionViewModel_ {}
//
//extension NSDiffableDataSourceSnapshot where SectionIdentifierType == TrackingProtectionViewController_.Section, ItemIdentifierType == TrackingProtectionViewController_.Item {
//    init(model: TrackingProtectionViewModel_) {
//        self.init()
//
//        appendSections([.trackers])
//        appendItems(
//            [
//                .image,
//                .trackersBlocked,
//                .secureConnection,
//                .enchancedTracking,
//            ],
//            toSection: .trackers
//        )
//
//        appendSections([.clearCookies])
//        appendItems(
//            [
//                .clearCookies,
//            ],
//            toSection: .clearCookies
//        )
//    }
//}
