// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Redux

final class HomepageViewController: UIViewController,
                                    UICollectionViewDelegate,
                                    ContentContainable,
                                    Themeable,
                                    Notifiable,
                                    StoreSubscriber {
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

    private var currentTheme: Theme {
        themeManager.getCurrentTheme(for: windowUUID)
    }

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

        setupNotifications(forObserver: self, observing: [UIApplication.didBecomeActiveNotification])

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
        dataSource?.applyInitialSnapshot(state: state)
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

        HomepageItem.cellTypes.forEach {
            collectionView.register($0, forCellWithReuseIdentifier: $0.cellIdentifier)
        }

        collectionView.registerSupplementary(
            of: UICollectionView.elementKindSectionHeader,
            cellType: LabelButtonHeaderView.self
        )
        collectionView.registerSupplementary(
            of: UICollectionView.elementKindSectionFooter,
            cellType: PocketFooterView.self
        )

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

        dataSource?.supplementaryViewProvider = { [weak self] (collectionView, kind, indexPath) in
            return self?.configureSupplementaryCell(with: collectionView, for: kind, at: indexPath)
        }
    }

    private func configureCell(
        for item: HomepageDiffableDataSource.HomeItem,
        at indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch item {
        case .header:
            guard let headerCell = collectionView?.dequeueReusableCell(
                cellType: HomepageHeaderCell.self,
                for: indexPath
            )  else {
                return UICollectionViewCell()
            }

            headerCell.configure(
                headerState: homepageState.headerState,
                showiPadSetup: shouldUseiPadSetup()
            ) { [weak self] in
                self?.toggleHomepageMode()
            }
            headerCell.applyTheme(theme: currentTheme)

            return headerCell
        case .pocket(let story):
            guard let pocketCell = collectionView?.dequeueReusableCell(
                cellType: PocketStandardCell.self,
                for: indexPath
            )  else {
                return UICollectionViewCell()
            }
            pocketCell.configure(story: story, theme: currentTheme)

            return pocketCell
        case .pocketDiscover:
            guard let pocketDiscoverCell = collectionView?.dequeueReusableCell(
                cellType: PocketDiscoverCell.self,
                for: indexPath
            )  else {
                return UICollectionViewCell()
            }

            pocketDiscoverCell.configure(text: homepageState.pocketState.pocketDiscoverItem.title, theme: currentTheme)

            return pocketDiscoverCell
        case .customizeHomepage:
            guard let customizeHomeCell = collectionView?.dequeueReusableCell(
                cellType: CustomizeHomepageSectionCell.self,
                for: indexPath
            ) else {
                return UICollectionViewCell()
            }

            customizeHomeCell.configure(onTapAction: { [weak self] _ in
                self?.navigateToHomepageSettings()
            }, theme: currentTheme)

            return customizeHomeCell
        }
    }

    private func configureSupplementaryCell(
        with collectionView: UICollectionView,
        for kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView? {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            guard let sectionHeaderView = collectionView.dequeueSupplementary(
                of: kind,
                cellType: LabelButtonHeaderView.self,
                for: indexPath)
            else { return UICollectionReusableView() }
            guard let section = dataSource?.sectionIdentifier(for: indexPath.section) else {
                self.logger.log(
                    "Section should not have been nil, something went wrong",
                    level: .fatal,
                    category: .homepage
                )
                return UICollectionReusableView()
            }
            return self.configureSectionHeader(for: section, with: sectionHeaderView)
        case UICollectionView.elementKindSectionFooter:
            guard let footerView = collectionView.dequeueSupplementary(
                of: kind,
                cellType: PocketFooterView.self,
                for: indexPath)
            else { return UICollectionReusableView() }
            footerView.onTapLearnMore = {
                self.navigateToPocketLearnMore()
            }
            footerView.applyTheme(theme: currentTheme)
            return footerView
        default:
            return nil
        }
    }

    private func configureSectionHeader(
        for section: HomepageSection,
        with sectionLabelCell: LabelButtonHeaderView
    ) -> LabelButtonHeaderView? {
        switch section {
        case .pocket:
            sectionLabelCell.configure(
                state: homepageState.pocketState.sectionHeaderState,
                theme: currentTheme
            )
            return sectionLabelCell
        default:
            return nil
        }
    }

    // MARK: Dispatch Actions
    private func toggleHomepageMode() {
        store.dispatch(
            HeaderAction(
                windowUUID: windowUUID,
                actionType: HeaderActionType.toggleHomepageMode
            )
        )
    }

    private func navigateToHomepageSettings() {
        store.dispatch(
            NavigationBrowserAction(
                windowUUID: self.windowUUID,
                actionType: NavigationBrowserActionType.tapOnCustomizeHomepage
            )
        )
    }

    private func navigateToPocketLearnMore() {
        store.dispatch(
            NavigationBrowserAction(
                url: homepageState.pocketState.footerURL,
                windowUUID: self.windowUUID,
                actionType: NavigationBrowserActionType.tapOnLink
            )
        )
    }

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource?.itemIdentifier(for: indexPath) else {
            self.logger.log(
                "Item selected at \(indexPath) but does not navigate anywhere",
                level: .debug,
                category: .homepage
            )
            return
        }
        switch item {
        case .pocket(let story):
            store.dispatch(
                NavigationBrowserAction(
                    url: story.url,
                    windowUUID: self.windowUUID,
                    actionType: NavigationBrowserActionType.tapOnCell
                )
            )
        case .pocketDiscover:
            store.dispatch(
                NavigationBrowserAction(
                    url: homepageState.pocketState.pocketDiscoverItem.url,
                    windowUUID: self.windowUUID,
                    actionType: NavigationBrowserActionType.tapOnCell
                )
            )
        default:
            return
        }
    }

    // MARK: - Notifiable
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIApplication.willEnterForegroundNotification:
            store.dispatch(
                PocketAction(
                    windowUUID: self.windowUUID,
                    actionType: PocketActionType.enteredForeground
                )
            )
        default: break
        }
    }
}
