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

        collectionView.register(HomepageHeaderCell.self, forCellWithReuseIdentifier: HomepageHeaderCell.cellIdentifier)

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
        guard let section = HomepageSection(rawValue: indexPath.section) else {
            self.logger.log(
                "Section should not have been nil, something went wrong",
                level: .fatal,
                category: .homepage
            )
            return UICollectionViewCell()
        }

        switch section {
        case .header:
            let cell = collectionView?.dequeueReusableCell(
                withReuseIdentifier: HomepageHeaderCell.cellIdentifier,
                for: indexPath
            )
            guard let headerCell = cell as? HomepageHeaderCell else {
                return UICollectionViewCell()
            }
            headerCell.configure(
                headerState: homepageState.headerState,
                showiPadSetup: shouldUseiPadSetup()
            ) { [weak self] in
                guard let self else { return }
                store.dispatch(
                    HeaderAction(
                        windowUUID: self.windowUUID,
                        actionType: HeaderActionType.toggleHomepageMode
                    )
                )
            }
            headerCell.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            return headerCell
        default:
            return UICollectionViewCell()
        }
    }

    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // TODO: FXIOS-10162 - Dummy trigger to update with proper triggers

        guard let section = HomepageSection(rawValue: indexPath.section) else {
            return
        }
        switch section {
        default:
            return
        }
    }
}
