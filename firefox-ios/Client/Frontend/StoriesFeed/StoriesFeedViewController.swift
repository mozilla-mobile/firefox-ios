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
                                 Themeable,
                                 DismissalNotifiable {
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
    private let telemetry: StoriesFeedTelemetryProtocol
    private let scrollThrottler: MainThreadThrottlerProtocol
    private let impressionsThrottler: MainThreadThrottlerProtocol
    private let impressionsTracker: ImpressionTrackingUtility
    private var recordTelemetryOnDisappear = true

    // MARK: - Private constants
    private let logger: Logger

    // MARK: Initializers
    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared,
         telemetry: StoriesFeedTelemetryProtocol = StoriesFeedTelemetry(),
         impressionsThrottler: MainThreadThrottlerProtocol = MainThreadThrottler(seconds: 0.2),
         scrollThrottler: MainThreadThrottlerProtocol = MainThreadThrottler(seconds: 0.2),
         impressionsTracker: ImpressionTrackingUtility = ImpressionTrackingUtility()
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.logger = logger
        self.storiesFeedState = StoriesFeedState(windowUUID: windowUUID)
        self.telemetry = telemetry
        self.impressionsThrottler = impressionsThrottler
        self.scrollThrottler = scrollThrottler
        self.impressionsTracker = impressionsTracker

        super.init(nibName: nil, bundle: nil)

        subscribeToRedux()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // TODO: FXIOS-13097 This is a work around until we can leverage isolated deinits
        guard Thread.isMainThread else {
            assertionFailure(
                "StoriesFeedViewController was not deallocated on the main thread. Observer was not removed."
            )
            return
        }

        MainActor.assumeIsolated {
            if recordTelemetryOnDisappear {
                telemetry.storiesFeedClosed()
            }
            impressionsTracker.reset()
            unsubscribeFromRedux()
        }
    }

    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()
        setupLayout()
        configureDataSource()

        store.dispatch(
            StoriesFeedAction(
                windowUUID: windowUUID,
                actionType: StoriesFeedActionType.initialize
            )
        )

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
        telemetry.storiesFeedViewed()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar(animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackVisibleItemImpressions(sampleOnly: true)
    }

    // MARK: - Redux
    func subscribeToRedux() {
        let action = ScreenAction(
            windowUUID: windowUUID,
            actionType: ScreenActionType.showScreen,
            screen: .storiesFeed
        )
        store.dispatch(action)

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
        store.dispatch(action)
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
            telemetry.sendStoryTappedTelemetry(atIndex: indexPath.row)
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
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollThrottler.throttle { [weak self] in
            Task { @MainActor [weak self] in
                self?.trackVisibleItemImpressions(sampleOnly: true)
            }
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { flushImpressions() }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { flushImpressions() }

    // MARK: - Telemetry
    /// The sampleOnly parameter is there to distinguish between “sampling visibility”
    /// while the user is still scrolling vs. doing a full flush at the end of scrolling.
    private func trackVisibleItemImpressions(sampleOnly: Bool = false) {
        guard let collectionView else { return }

        let visibleRect = CGRect(origin: collectionView.contentOffset,
                                 size: collectionView.bounds.size)

        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let attributes = collectionView.layoutAttributesForItem(at: indexPath) else { continue }

            let cellFrame = attributes.frame
            let intersection = visibleRect.intersection(cellFrame)
            guard !intersection.isNull else { continue }

            let cellArea = cellFrame.width * cellFrame.height
            let visibleArea = intersection.width * intersection.height
            let ratio = visibleArea / max(cellArea, 1)

            if ratio >= impressionsTracker.impressionVisibilityThreshold {
                impressionsTracker.markPending(indexPath)
            }

            if sampleOnly {
                flushImpressions()
            }
        }
    }

    private func flushImpressions() {
        impressionsTracker.flush { indexPaths in
            for indexPath in indexPaths {
                telemetry.sendStoryViewedTelemetryFor(storyIndex: indexPath.item)
            }
        }
    }

    // MARK: - Themeable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        collectionView?.backgroundColor = .clear
    }

    // MARK: - DismissalNotifiable

    func willBeDismissed(reason: DismissalReason) {
        recordTelemetryOnDisappear = false
    }
}
