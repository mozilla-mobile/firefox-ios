// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import UIKit
import Storage
import SyncTelemetry
import MozillaAppServices

class FirefoxHomeViewController: UIViewController, HomePanel, GleanPlumbMessageManagable {

    // MARK: - Typealiases
    private typealias a11y = AccessibilityIdentifiers.FirefoxHomepage

    // MARK: - Operational Variables
    weak var homePanelDelegate: HomePanelDelegate?
    weak var libraryPanelDelegate: LibraryPanelDelegate?
    var notificationCenter: NotificationCenter = NotificationCenter.default

    private var hasSentJumpBackInSectionEvent = false
    private var isZeroSearch: Bool
    private var viewModel: FirefoxHomeViewModel
    private var contextMenuHelper: FirefoxHomeContextMenuHelper

    private var wallpaperManager: WallpaperManager
    private lazy var wallpaperView: WallpaperBackgroundView = .build { _ in }
    private var contextualHintViewController: ContextualHintViewController
    private var collectionView: UICollectionView! = nil

    lazy var homeTabBanner: HomeTabBanner = .build { card in
        card.backgroundColor = UIColor.theme.homePanel.topSitesBackground
    }

    var currentTab: Tab? {
        let tabManager = BrowserViewController.foregroundBVC().tabManager
        return tabManager.selectedTab
    }

    // MARK: - Initializers
    init(profile: Profile,
         isZeroSearch: Bool = false,
         wallpaperManager: WallpaperManager = WallpaperManager()
    ) {
        self.isZeroSearch = isZeroSearch
        self.wallpaperManager = wallpaperManager
        let isPrivate = BrowserViewController.foregroundBVC().tabManager.selectedTab?.isPrivate ?? true
        self.viewModel = FirefoxHomeViewModel(profile: profile,
                                              isZeroSearch: isZeroSearch,
                                              isPrivate: isPrivate)
        let contextualViewModel = ContextualHintViewModel(forHintType: .jumpBackIn,
                                                          with: viewModel.profile)
        self.contextualHintViewController = ContextualHintViewController(with: contextualViewModel)
        self.contextMenuHelper = FirefoxHomeContextMenuHelper(viewModel: viewModel)
        super.init(nibName: nil, bundle: nil)

        contextMenuHelper.delegate = self
        contextMenuHelper.getPopoverSourceRect = { [weak self] popoverView in
            guard let self = self else { return CGRect() }
            return self.getPopoverSourceRect(sourceView: popoverView)
        }

        viewModel.delegate = self

        // TODO: .TabClosed notif should be in JumpBackIn view only to reload it's data, but can't right now since doesn't self-size
        setupNotifications(forObserver: self,
                           observing: [.HomePanelPrefsChanged,
                                       .TopTabsTabClosed,
                                       .TabsTrayDidClose,
                                       .TabsTrayDidSelectHomeTab,
                                       .TabsPrivacyModeChanged])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        contextualHintViewController.stopTimer()
        notificationCenter.removeObserver(self)
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()
        configureWallpaperView()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        if shouldDisplayHomeTabBanner {
            showHomeTabBanner()
        }

        applyTheme()
        setupSectionsAction()
        reloadAll()
    }

    override func viewDidAppear(_ animated: Bool) {
        viewModel.recordViewAppeared()
        animateFirefoxLogo()

        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        contextualHintViewController.stopTimer()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        wallpaperView.updateImageForOrientationChange()
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        reloadOnRotation(newCollection, with: coordinator)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()
    }

    // MARK: - Layout

    func configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds,
                                          collectionViewLayout: createLayout())

        FirefoxHomeSectionType.cellTypes.forEach {
            collectionView.register($0, forCellWithReuseIdentifier: $0.cellIdentifier)
        }
        collectionView.register(ASHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: ASHeaderView.cellIdentifier)

        collectionView.keyboardDismissMode = .onDrag
        collectionView.addGestureRecognizer(longPressRecognizer)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .clear
        view.addSubview(collectionView)
    }

    func configureWallpaperView() {
        view.addSubview(wallpaperView)
        NSLayoutConstraint.activate([
            wallpaperView.topAnchor.constraint(equalTo: view.topAnchor),
            wallpaperView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wallpaperView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            wallpaperView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        view.sendSubviewToBack(wallpaperView)
    }

    func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in

            guard let viewModel = self.viewModel.getSectionViewModel(shownSection: sectionIndex), viewModel.shouldShow else {
                return nil
            }

            return viewModel.section(for: layoutEnvironment.traitCollection)
        }
        return layout
    }

    // MARK: Long press

    private lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    @objc fileprivate func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }

        // TODO: Laurie - Long press for pocket and top sites

        // POCKET
        let point = longPressGestureRecognizer.location(in: collectionView)
        //        guard let indexPath = collectionView.indexPathForItem(at: point),
        //              let viewModel = viewModel, let onLongPressTileAction = viewModel.onLongPressTileAction
        //        else { return }
        //
        //        let site = viewModel.getSitesDetail(for: indexPath.row)
        //        let sourceView = collectionView.cellForItem(at: indexPath)
        //        onLongPressTileAction(site, sourceView)

        // TOPSITE
        //            guard longPressGestureRecognizer.state == .began else { return }
        //
        //            let point = longPressGestureRecognizer.location(in: collectionView)
        //            guard let indexPath = collectionView.indexPathForItem(at: point),
        //                  let viewModel = viewModel,
        //                  let tileLongPressedHandler = viewModel.tileLongPressedHandler,
        //                  let site = viewModel.tileManager.getSiteDetail(index: indexPath.row)
        //            else { return }
        //
        //            let sourceView = collectionView.cellForItem(at: indexPath)
        //            tileLongPressedHandler(site, sourceView)
    }

    // MARK: - Helpers

    private func reloadOnRotation(_ newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        for (index, _) in viewModel.shownSections.enumerated() {
            let viewModel  = viewModel.getSectionViewModel(shownSection: index)
            viewModel?.refreshData(for: newCollection)
        }

        coordinator.animate(alongsideTransition: { context in
            // The contextual menu does not behave correctly. Dismiss it when rotating.
            if let _ = self.presentedViewController as? PhotonActionSheet {
                self.presentedViewController?.dismiss(animated: true, completion: nil)
            }

            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.reloadData()
        }, completion: { _ in
            // TODO: Laurie still necessary to reload here?
            // Workaround: label positions are not correct without additional reload
            self.collectionView?.reloadData()
        })
    }

    private func adjustPrivacySensitiveSections(notification: Notification) {
        guard let dict = notification.object as? NSDictionary,
              let isPrivate = dict[Tab.privateModeKey] as? Bool
        else { return }

        viewModel.isPrivate = isPrivate
        viewModel.updateEnabledSections()
        reloadAll()
    }

    func applyTheme() {
        homeTabBanner.applyTheme()
        view.backgroundColor = UIColor.theme.homePanel.topSitesBackground
    }

    func scrollToTop(animated: Bool = false) {
        collectionView?.setContentOffset(.zero, animated: animated)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        dismissKeyboard()
    }

    @objc private func dismissKeyboard() {
        currentTab?.lastKnownUrl?.absoluteString.hasPrefix("internal://") ?? false ? BrowserViewController.foregroundBVC().urlBar.leaveOverlayMode() : nil
    }

    private func showSiteWithURLHandler(_ url: URL, isGoogleTopSite: Bool = false) {
        let visitType = VisitType.bookmark
        homePanelDelegate?.homePanel(didSelectURL: url, visitType: visitType, isGoogleTopSite: isGoogleTopSite)
    }

    private func animateFirefoxLogo() {
        guard viewModel.headerViewModel.shouldRunLogoAnimation(),
              let cell = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? FxHomeLogoHeaderCell
        else { return }

        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { _ in
            cell.runLogoAnimation()
        })
    }

    // MARK: - Contextual hint
    private func prepareJumpBackInContextualHint(onView headerView: ASHeaderView) {
        guard contextualHintViewController.shouldPresentHint(),
              !shouldDisplayHomeTabBanner
        else { return }

        contextualHintViewController.configure(
            anchor: headerView.titleLabel,
            withArrowDirection: .down,
            andDelegate: self,
            presentedUsing: { self.presentContextualHint() },
            withActionBeforeAppearing: { self.contextualHintPresented() },
            andActionForButton: { self.openTabsSettings() })
    }

    @objc private func presentContextualHint() {
        guard BrowserViewController.foregroundBVC().searchController == nil,
              presentedViewController == nil
        else {
            contextualHintViewController.stopTimer()
            return
        }

        present(contextualHintViewController, animated: true, completion: nil)
    }

    // MARK: - Home Tab Banner

    private var shouldDisplayHomeTabBanner: Bool {
        let message = messagingManager.getNextMessage(for: .newTabCard)
        if #available(iOS 14.0, *), message != nil || !UserDefaults.standard.bool(forKey: PrefsKeys.DidDismissDefaultBrowserMessage) {
            return true
        } else {
            return false
        }
    }

    private func showHomeTabBanner() {
        view.addSubview(homeTabBanner)
        NSLayoutConstraint.activate([
            homeTabBanner.topAnchor.constraint(equalTo: view.topAnchor),
            homeTabBanner.bottomAnchor.constraint(equalTo: collectionView.topAnchor),
            homeTabBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            homeTabBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            homeTabBanner.heightAnchor.constraint(equalToConstant: 264),

            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        homeTabBanner.dismissClosure = { [weak self] in
            self?.dismissHomeTabBanner()
        }
    }

    public func dismissHomeTabBanner() {
        homeTabBanner.removeFromSuperview()
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

// MARK: -  CollectionView Data Source

extension FirefoxHomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: ASHeaderView.cellIdentifier,
                for: indexPath) as? ASHeaderView,
              let viewModel = viewModel.getSectionViewModel(shownSection: indexPath.section)
        else {
            return UICollectionReusableView()
        }

        // Jump back in header specific setup
        if FirefoxHomeSectionType(indexPath.section) == .jumpBackIn {
            if !hasSentJumpBackInSectionEvent {
                TelemetryWrapper.recordEvent(category: .action,
                                             method: .view,
                                             object: .jumpBackInImpressions,
                                             value: nil,
                                             extras: nil)
                hasSentJumpBackInSectionEvent = true
            }
            prepareJumpBackInContextualHint(onView: headerView)
        }

        // Configure header only if section is shown
        let headerViewModel = viewModel.shouldShow ? viewModel.headerViewModel : ASHeaderViewModel.emptyHeader
        headerView.configure(viewModel: headerViewModel)
        return headerView
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.shownSections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.getSectionViewModel(shownSection: section)?.numberOfItemsInSection(for: traitCollection) ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let viewModel = viewModel.getSectionViewModel(shownSection: indexPath.section) as? FxHomeSectionHandler else {
            return UICollectionViewCell()
        }

        return viewModel.configure(collectionView, at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewModel = viewModel.getSectionViewModel(shownSection: indexPath.section) as? FxHomeSectionHandler else { return }
        viewModel.didSelectItem(at: indexPath, homePanelDelegate: homePanelDelegate, libraryPanelDelegate: libraryPanelDelegate)
    }
}

// MARK: - Data Management

extension FirefoxHomeViewController {

    /// Reload all data including refreshing cells content and fetching data from backend
    func reloadAll() {
        collectionView.reloadData()

        DispatchQueue.global(qos: .userInteractive).async {
            self.viewModel.updateData()
        }
    }
}

// MARK: - Actions Handling

private extension FirefoxHomeViewController {

    // Setup all the tap and long press actions on cells in each sections
    private func setupSectionsAction() {

        // Header view
        viewModel.headerViewModel.onTapAction = { [weak self] _ in
            self?.changeHomepageWallpaper()
        }

        // Top sites
        viewModel.topSiteViewModel.tilePressedHandler = { [weak self] site, isGoogle in
            guard let url = site.url.asURL else { return }
            self?.showSiteWithURLHandler(url, isGoogleTopSite: isGoogle)
        }

        viewModel.topSiteViewModel.tileLongPressedHandler = { [weak self] (site, sourceView) in
            self?.contextMenuHelper.presentContextMenu(for: site, with: sourceView, sectionType: .topSites)
        }

        // Recently saved
        viewModel.recentlySavedViewModel.headerButtonAction = { [weak self] button in
            self?.openBookmarks(button)
        }

        // Jumpback in
        viewModel.jumpBackInViewModel.onTapGroup = { [weak self] tab in
            self?.homePanelDelegate?.homePanelDidRequestToOpenTabTray(withFocusedTab: tab)
        }

        viewModel.jumpBackInViewModel.headerButtonAction = { [weak self] button in
            self?.openTabTray(button)
        }

        // History highlights
        viewModel.historyHighlightsViewModel.onTapItem = { [weak self] highlight in
            guard let url = highlight.siteUrl else {
                self?.openHistoryHighlightsSearchGroup(item: highlight)
                return
            }

            self?.homePanelDelegate?.homePanel(didSelectURL: url, visitType: .link, isGoogleTopSite: false)
        }

        viewModel.historyHighlightsViewModel.headerButtonAction = { [weak self] button in
            self?.openHistory(button)
        }

        // Pocket
        viewModel.pocketViewModel.onTapTileAction = { [weak self] url in
            self?.showSiteWithURLHandler(url)
        }

        viewModel.pocketViewModel.onLongPressTileAction = { [weak self] (site, sourceView) in
            self?.contextMenuHelper.presentContextMenu(for: site, with: sourceView, sectionType: .pocket)
        }

        // Customize home
        viewModel.customizeButtonViewModel.onTapAction = { [weak self] _ in
            self?.openCustomizeHomeSettings()
        }
    }

    private func openHistoryHighlightsSearchGroup(item: HighlightItem) {
        guard let groupItem = item.group else { return }

        var groupedSites = [Site]()
        for item in groupItem {
            groupedSites.append(buildSite(from: item))
        }
        let groupSite = ASGroup<Site>(searchTerm: item.displayTitle, groupedItems: groupedSites, timestamp: Date.now())

        let asGroupListViewModel = SearchGroupedItemsViewModel(asGroup: groupSite, presenter: .recentlyVisited)
        let asGroupListVC = SearchGroupedItemsViewController(viewModel: asGroupListViewModel, profile: viewModel.profile)

        let dismissableController: DismissableNavigationViewController
        dismissableController = DismissableNavigationViewController(rootViewController: asGroupListVC)

        self.present(dismissableController, animated: true, completion: nil)

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .firefoxHomepage,
                                     value: .historyHighlightsGroupOpen,
                                     extras: nil)

        asGroupListVC.libraryPanelDelegate = libraryPanelDelegate
    }

    private func buildSite(from highlight: HighlightItem) -> Site {
        let itemURL = highlight.siteUrl?.absoluteString ?? ""
        return Site(url: itemURL, title: highlight.displayTitle)
    }

    @objc func openTabTray(_ sender: UIButton) {
        if sender.accessibilityIdentifier == a11y.MoreButtons.jumpBackIn {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .jumpBackInSectionShowAll,
                                         extras: TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch))
        }
        homePanelDelegate?.homePanelDidRequestToOpenTabTray(withFocusedTab: nil)
    }

    @objc func openBookmarks(_ sender: UIButton) {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .bookmarks)

        if sender.accessibilityIdentifier == a11y.MoreButtons.recentlySaved {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .recentlySavedSectionShowAll,
                                         extras: TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch))
        } else {
            // TODO: Laurie - remove
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .yourLibrarySection,
                                         extras: [TelemetryWrapper.EventObject.libraryPanel.rawValue: TelemetryWrapper.EventValue.bookmarksPanel.rawValue])
        }
    }

    @objc func openHistory(_ sender: UIButton) {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .history)
        if sender.accessibilityIdentifier == a11y.MoreButtons.historyHighlights {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .historyHighlightsShowAll)

        } else {
            // TODO: Laurie - remove
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .yourLibrarySection,
                                         extras: [TelemetryWrapper.EventObject.libraryPanel.rawValue: TelemetryWrapper.EventValue.historyPanel.rawValue])
        }
    }

    // TODO: Laurie - remove
    //    @objc func openReadingList(_ sender: UIButton) {
    //        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .readingList)
    //        TelemetryWrapper.recordEvent(category: .action,
    //                                     method: .tap,
    //                                     object: .firefoxHomepage,
    //                                     value: .yourLibrarySection,
    //                                     extras: [TelemetryWrapper.EventObject.libraryPanel.rawValue: TelemetryWrapper.EventValue.readingListPanel.rawValue])
    //    }

    //    @objc func openDownloads(_ sender: UIButton) {
    //        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .downloads)
    //        TelemetryWrapper.recordEvent(category: .action,
    //                                     method: .tap,
    //                                     object: .firefoxHomepage,
    //                                     value: .yourLibrarySection,
    //                                     extras: [TelemetryWrapper.EventObject.libraryPanel.rawValue: TelemetryWrapper.EventValue.downloadsPanel.rawValue])
    //    }

    func openCustomizeHomeSettings() {
        homePanelDelegate?.homePanelDidRequestToOpenSettings(at: .customizeHomepage)
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .firefoxHomepage,
                                     value: .customizeHomepageButton)
    }

    func contextualHintPresented() {
        homePanelDelegate?.homePanelDidPresentContextualHintOf(type: .jumpBackIn)
    }

    func openTabsSettings() {
        homePanelDelegate?.homePanelDidRequestToOpenSettings(at: .customizeTabs)
    }

    func changeHomepageWallpaper() {
        wallpaperView.cycleWallpaper()
    }

    func getPopoverSourceRect(sourceView: UIView?) -> CGRect {
        let cellRect = sourceView?.frame ?? .zero
        let cellFrameInSuperview = self.collectionView?.convert(cellRect, to: self.collectionView) ?? .zero

        return CGRect(origin: CGPoint(x: cellFrameInSuperview.size.width / 2,
                                      y: cellFrameInSuperview.height / 2),
                      size: .zero)
    }
}

// MARK: FirefoxHomeContextMenuHelperDelegate
extension FirefoxHomeViewController: FirefoxHomeContextMenuHelperDelegate {
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool, selectNewTab: Bool) {
        homePanelDelegate?.homePanelDidRequestToOpenInNewTab(url, isPrivate: isPrivate, selectNewTab: selectNewTab)
    }

    func homePanelDidRequestToOpenSettings(at settingsPage: AppSettingsDeeplinkOption) {
        homePanelDelegate?.homePanelDidRequestToOpenSettings(at: settingsPage)
    }
}

// MARK: - Popover Presentation Delegate

extension FirefoxHomeViewController: UIPopoverPresentationControllerDelegate {

    // Dismiss the popover if the device is being rotated.
    // This is used by the Share UIActivityViewController action sheet on iPad
    func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {
        // Do not dismiss if the popover is a CFR
        if contextualHintViewController.isPresenting { return }
        popoverPresentationController.presentedViewController.dismiss(animated: false, completion: nil)
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return true
    }
}

// MARK: FirefoxHomeViewModelDelegate
extension FirefoxHomeViewController: FirefoxHomeViewModelDelegate {

    func reloadSection(section: FXHomeViewModelProtocol) {
        ensureMainThread { [weak self] in
            guard let self = self else { return }
            self.viewModel.reloadSection(section, with: self.collectionView)
        }
    }
}

// MARK: - Notifiable
extension FirefoxHomeViewController: Notifiable {
    func handleNotifications(_ notification: Notification) {
        ensureMainThread { [weak self] in
            guard let self = self else { return }

            self.viewModel.updateEnabledSections()

            switch notification.name {
            case .TabsPrivacyModeChanged:
                self.adjustPrivacySensitiveSections(notification: notification)
            case .TabsTrayDidClose,
                    .TopTabsTabClosed,
                    .TabsTrayDidSelectHomeTab,
                    .HomePanelPrefsChanged:
                self.reloadAll()
            default: break
            }
        }
    }
}
