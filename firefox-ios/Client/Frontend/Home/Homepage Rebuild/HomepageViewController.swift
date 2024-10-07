// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Redux

<<<<<<< HEAD:firefox-ios/Client/Frontend/Home/Homepage Rebuild/HomepageViewController.swift
final class HomepageViewController: UIViewController, ContentContainable, Themeable {
=======
final class NewHomepageViewController: UIViewController,
                                       UICollectionViewDelegate,
                                       ContentContainable,
                                       Themeable,
                                       StoreSubscriber {
>>>>>>> 1451919a81 (add initial redux):firefox-ios/Client/Frontend/Home/Homepage Rebuild/NewHomepageViewController.swift
    // MARK: - Typealiases
    typealias SubscriberStateType = HomepageState
    private typealias a11y = AccessibilityIdentifiers.FirefoxHomepage

    // MARK: - ContentContainable variables
    var contentType: ContentType = .homepage

    // MARK: - Themable variables
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol

    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { return windowUUID }

    // MARK: - Private variables
    private var collectionView: UICollectionView?
    private var dataSource: HomepageDiffableDataSource?
    private var layoutConfiguration = HomepageSectionLayoutProvider().createCompositionalLayout()
    private var logger: Logger
    private var homepageState: HomepageState

    // MARK: - Initializers
    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.logger = logger
        homepageState = HomepageState(windowUUID: windowUUID)
        super.init(nibName: nil, bundle: nil)

        subscribeToRedux()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        unsubscribeFromRedux()
        notificationCenter.removeObserver(self)
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        configureCollectionView()
        configureDataSource()

        store.dispatch(
            HomepageAction(
                windowUUID: windowUUID,
                actionType: HomepageActionType.initialize
            )
        )

        listenForThemeChange(view)
        applyTheme()
    }

    // MARK: - Redux
    func subscribeToRedux() {
        let action = ScreenAction(
            windowUUID: windowUUID,
            actionType: ScreenActionType.showScreen,
            screen: .homepage
        )
        store.dispatch(action)

        let uuid = windowUUID
        store.subscribe(self, transform: {
            return $0.select({ appState in
                return HomepageState(
                    appState: appState,
                    uuid: uuid
                )
            })
        })
    }

    func newState(state: HomepageState) {
        homepageState = state
        if homepageState.loadInitialData {
            dataSource?.applyInitialSnapshot()
        } else if homepageState.headerState.showHeader {
            dataSource?.updateHeaderSection()
        }
    }

    func unsubscribeFromRedux() {
        let action = ScreenAction(
            windowUUID: windowUUID,
            actionType: ScreenActionType.closeScreen,
            screen: .homepage
        )
        store.dispatch(action)
    }

    // MARK: - Theming
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
    }

    // MARK: - Layout
    private func setupLayout() {
        guard let collectionView else {
            logger.log(
                "Homepage collectionview should not have been nil, something went wrong",
                level: .fatal,
                category: .homepage
            )
            return
        }

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func configureCollectionView() {
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layoutConfiguration)

        // TODO: FXIOS-10163 - Update with proper cells
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")

        collectionView.keyboardDismissMode = .onDrag
        collectionView.showsVerticalScrollIndicator = false
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .clear
        collectionView.accessibilityIdentifier = a11y.collectionView
        collectionView.delegate = self

        self.collectionView = collectionView

        view.addSubview(collectionView)
    }

    private func configureDataSource() {
        guard let collectionView else {
            logger.log(
                "Homepage collectionview should not have been nil, something went wrong",
                level: .fatal,
                category: .homepage
            )
            return
        }

        dataSource = HomepageDiffableDataSource(
            collectionView: collectionView
        ) { [weak self] (collectionView, indexPath, item) -> UICollectionViewCell? in
            return self?.configureCell(for: item, at: indexPath)
        }
    }

    private func configureCell(
        for item: HomepageDiffableDataSource.HomeItem,
        at indexPath: IndexPath
    ) -> UICollectionViewCell {
        // TODO: FXIOS-10163 - Dummy collection cells, to update with proper cells
        guard let section = HomepageSection(
            rawValue: indexPath.section
        ), let cell: UICollectionViewCell = collectionView?.dequeueReusableCell(
            withReuseIdentifier: "cell",
            for: indexPath
        ) else {
            self.logger.log(
                "Section should not have been nil, something went wrong",
                level: .fatal,
                category: .newHomepage
            )
            return UICollectionViewCell()
        }

        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.backgroundColor = getBackgroundColor(for: section)

        let label = UILabel(frame: cell.contentView.bounds)
        label.textAlignment = .center
        label.text = item.title
        label.textColor = .white
        cell.contentView.addSubview(label)

        return cell
    }

    private func getBackgroundColor(for section: HomepageSection) -> UIColor {
        switch section {
        case .header:
            return .systemPink
        case .topSites:
            return .systemGreen
        case .pocket:
            return .systemPurple
        }
    }

    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let selectedItem = dataSource?.itemIdentifier(for: indexPath) {
            // TODO: FXIOS-10163 - Dummy trigger to update with proper triggers
            if selectedItem.title == "First" {
                store.dispatch(
                    HeaderAction(
                        windowUUID: windowUUID,
                        actionType: HeaderActionType.updateHeader
                    )
                )
            }
        }
    }
}
