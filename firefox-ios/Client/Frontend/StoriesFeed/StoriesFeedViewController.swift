// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux
import UIKit

class StoriesFeedViewController: UIViewController,
                                 UICollectionViewDelegate,
                                 StoreSubscriber,
                                 Themeable {
    // MARK: - Themeable Properties
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol

    // MARK: - Private variables
    private var collectionView: UICollectionView?
    private var dataSource: StoriesFeedDiffableDataSource?
    private var storiesFeedState: StoriesFeedState
    private var currentTheme: Theme {
        themeManager.getCurrentTheme(for: windowUUID)
    }

    // Telemetry related
    private var alreadyTrackedStories = Set<StoriesFeedItem>()
    private let trackingImpressionsThrottler: GCDThrottlerProtocol

    // MARK: - Private constants
    private let logger: Logger

    // MARK: Initializers
    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared,
         throttler: GCDThrottlerProtocol = GCDThrottler(seconds: 0.5)
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.logger = logger
        self.storiesFeedState = StoriesFeedState(windowUUID: windowUUID)
        self.trackingImpressionsThrottler = throttler

        super.init(nibName: nil, bundle: nil)

        subscribeToRedux()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        unsubscribeFromRedux()
    }

    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()
        setupLayout()
        configureDataSource()

        store.dispatchLegacy(
            StoriesFeedAction(
                windowUUID: windowUUID,
                actionType: StoriesFeedActionType.initialize
            )
        )

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar(animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackVisibleItemImpressions()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        resetTrackedObjects()
    }

    // MARK: - Redux
    func subscribeToRedux() {
        let action = ScreenAction(
            windowUUID: windowUUID,
            actionType: ScreenActionType.showScreen,
            screen: .storiesFeed
        )
        store.dispatchLegacy(action)

        let uuid = windowUUID
        store.subscribe(self, transform: {
            return $0.select({ appState in
                return StoriesFeedState(
                    appState: appState,
                    uuid: uuid
                )
            })
        })
    }

    func newState(state: StoriesFeedState) {
        self.storiesFeedState = state

        dataSource?.updateSnapshot(state: state)
    }

    func unsubscribeFromRedux() {
        let action = ScreenAction(
            windowUUID: windowUUID,
            actionType: ScreenActionType.closeScreen,
            screen: .storiesFeed
        )
        store.dispatchLegacy(action)
    }

    // MARK: Helper functions
    private func setupNavigationBar(animated: Bool) {
        title = .FirefoxHomepage.Pocket.AllStories.AllStoriesViewTitle
        navigationController?.setNavigationBarHidden(false, animated: animated)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func configureCollectionView() {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())

        StoriesFeedItem.cellTypes.forEach {
            collectionView.register($0, forCellWithReuseIdentifier: $0.cellIdentifier)
        }

        collectionView.backgroundColor = .clear
        collectionView.delegate = self

        self.collectionView = collectionView
    }

    private func setupLayout() {
        guard let collectionView else {
            logger.log(
                "StoriesFeed collectionview should not have been nil, something went wrong",
                level: .fatal,
                category: .storiesFeed
            )
            return
        }

        view.addSubview(collectionView)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        let sectionProvider = StoriesFeedSectionLayoutProvider()
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, environment)
            -> NSCollectionLayoutSection? in
            return sectionProvider.createStoriesFeedSectionLayout(for: environment)
        }
        return layout
    }

    private func configureDataSource() {
        guard let collectionView else {
            logger.log(
                "StoriesFeed collectionview should not have been nil, something went wrong",
                level: .fatal,
                category: .storiesFeed
            )
            return
        }

        dataSource = StoriesFeedDiffableDataSource(
            collectionView: collectionView
        ) { [weak self] (collectionView, indexPath, item) -> UICollectionViewCell? in
            return self?.configureCell(for: item, at: indexPath)
        }
    }

    private func configureCell(
        for item: StoriesFeedItem,
        at indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch item {
        case .stories(let story):
            guard let storiesCell = collectionView?.dequeueReusableCell(cellType: StoriesFeedCell.self,
                                                                        for: indexPath) else {
                return UICollectionViewCell()
            }

            let position = indexPath.item + 1
            let totalCount = dataSource?.snapshot().numberOfItems(inSection: .stories)
            storiesCell.configure(story: story, theme: currentTheme, position: position, totalCount: totalCount)
            return storiesCell
        }
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
        case .stories(let config):
            let destination = NavigationDestination(
                .storiesWebView,
                url: config.url,
                visitType: .link
            )
            store.dispatch(
                NavigationBrowserAction(
                    navigationDestination: destination,
                    windowUUID: windowUUID,
                    actionType: NavigationBrowserActionType.tapOnCell
                )
            )
            store.dispatch(
                StoriesFeedAction(
                    windowUUID: windowUUID,
                    actionType: StoriesFeedActionType.telemetry(.tappedStory(atIndex: indexPath.row + 1))
                )
            )
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        trackVisibleItemImpressions()
    }

    // MARK: - Telemetry
    /// Used to track impressions. If the user has already seen the item on the homepage, we only record the impression once.
    /// We want to track at initial seen as well as when users scrolls.
    /// A throttle is added in order to capture what the users has seen. When we scroll to top programmatically,
    /// the impressions were being tracked, but to match user's perspective, we add a throttle to delay.
    /// Time complexity: O(n) due to iterating visible items.
    private func trackVisibleItemImpressions() {
        trackingImpressionsThrottler.throttle { [self] in
            ensureMainThread {
                guard let collectionView = self.collectionView else {
                    self.logger.log(
                        "Stories collectionview should not have been nil, unable to track impression",
                        level: .warning,
                        category: .storiesFeed
                    )
                    return
                }

                for indexPath in collectionView.indexPathsForVisibleItems {
                    guard let item = self.dataSource?.itemIdentifier(for: indexPath) else { continue }
                    self.handleTrackingImpressions(with: item, at: indexPath.item)
                }
            }
        }
    }

    private func handleTrackingImpressions(with item: StoriesFeedItem, at index: Int) {
        guard !alreadyTrackedStories.contains(item) else { return }
        alreadyTrackedStories.insert(item)
        store.dispatch(
            StoriesFeedAction(
                windowUUID: windowUUID,
                actionType: StoriesFeedActionType.telemetry(.storiesImpression(atIndex: index + 1))
            )
        )
    }

    private func resetTrackedObjects() {
        alreadyTrackedStories.removeAll()
    }

    // MARK: - Themeable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        collectionView?.backgroundColor = .clear
    }
}
