// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import UIKit
import Storage
import SyncTelemetry
import MozillaAppServices

class FirefoxHomeViewController: UICollectionViewController, HomePanel {
    // MARK: - Typealiases
    private typealias a11y = AccessibilityIdentifiers.FirefoxHomepage

    // MARK: - Operational Variables
    weak var homePanelDelegate: HomePanelDelegate?
    weak var libraryPanelDelegate: LibraryPanelDelegate?
    var notificationCenter: NotificationCenter = NotificationCenter.default

    private let flowLayout = UICollectionViewFlowLayout()
    private var hasSentJumpBackInSectionEvent = false
    private var hasSentHistoryHighlightsSectionEvent = false
    private var isZeroSearch: Bool
    private var viewModel: FirefoxHomeViewModel

    private var wallpaperManager: WallpaperManager
    private lazy var wallpaperView: WallpaperBackgroundView = .build { _ in }
    private var contextualHintViewController: ContextualHintViewController

    lazy var defaultBrowserCard: DefaultBrowserCard = .build { card in
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

        super.init(collectionViewLayout: flowLayout)

        viewModel.delegate = self
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        // TODO: .TabClosed notif should be in JumpBackIn view only to reload it's data, but can't right now since doesn't self-size
        setupNotifications(forObserver: self,
                           observing: [.HomePanelPrefsChanged, .TabClosed, .TabsPrivacyModeChanged])
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

        FirefoxHomeSectionType.allCases.forEach {
            collectionView.register($0.cellType, forCellWithReuseIdentifier: $0.cellIdentifier)
        }
        collectionView?.register(ASHeaderView.self,
                                 forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                 withReuseIdentifier: "Header")
        collectionView?.keyboardDismissMode = .onDrag
        collectionView?.backgroundColor = .clear
        view.addSubview(wallpaperView)

        if shouldShowDefaultBrowserCard {
            showDefaultBrowserCard()
        }

        NSLayoutConstraint.activate([
            wallpaperView.topAnchor.constraint(equalTo: view.topAnchor),
            wallpaperView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wallpaperView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            wallpaperView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        view.sendSubviewToBack(wallpaperView)

        applyTheme()

        if let collectionView = self.collectionView, collectionView.numberOfSections > 0, collectionView.numberOfItems(inSection: 0) > 0 {
            collectionView.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadAll()
    }

    override func viewDidAppear(_ animated: Bool) {
        viewModel.nimbus.features.homescreenFeature.recordExposure()
        animateFirefoxLogo()
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .firefoxHomepage,
                                     value: .fxHomepageOrigin,
                                     extras: TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch))

        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        contextualHintViewController.stopTimer()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        reloadOnRotation(with: coordinator)
        wallpaperView.updateImageForOrientationChange()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()
    }

    // MARK: - Helpers

    private func reloadOnRotation(with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { context in
            // The AS context menu does not behave correctly. Dismiss it when rotating.
            if let _ = self.presentedViewController as? PhotonActionSheet {
                self.presentedViewController?.dismiss(animated: true, completion: nil)
            }
            self.collectionViewLayout.invalidateLayout()
            self.collectionView?.reloadData()
        }, completion: { _ in
            // Workaround: label positions are not correct without additional reload
            self.collectionView?.reloadData()
        })
    }

    private func adjustPrivacySensitiveSections(notification: Notification) {
        guard let dict = notification.object as? NSDictionary,
              let isPrivate = dict[Tab.privateModeKey] as? Bool
        else { return }

        viewModel.isPrivate = isPrivate
        if let jumpBackIndex = viewModel.enabledSections.firstIndex(of: FirefoxHomeSectionType.jumpBackIn) {
            let indexSet = IndexSet([jumpBackIndex])
            collectionView.reloadSections(indexSet)
        }

        if let highlightIndex = viewModel.enabledSections.firstIndex(of: FirefoxHomeSectionType.historyHighlights) {
            let indexSet = IndexSet([highlightIndex])
            collectionView.reloadSections(indexSet)
        } else {
            reloadAll()
        }
    }

    func applyTheme() {
        defaultBrowserCard.applyTheme()
        view.backgroundColor = UIColor.theme.homePanel.topSitesBackground
    }

    func scrollToTop(animated: Bool = false) {
        collectionView?.setContentOffset(.zero, animated: animated)
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
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
              !shouldShowDefaultBrowserCard
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

    // MARK: - Default browser card

    private var shouldShowDefaultBrowserCard: Bool {
        if #available(iOS 14.0, *), !UserDefaults.standard.bool(forKey: "DidDismissDefaultBrowserCard") {
            return true
        } else {
            return false
        }
    }

    private func showDefaultBrowserCard() {
        self.view.addSubview(defaultBrowserCard)
        NSLayoutConstraint.activate([
            defaultBrowserCard.topAnchor.constraint(equalTo: view.topAnchor),
            defaultBrowserCard.bottomAnchor.constraint(equalTo: collectionView.topAnchor),
            defaultBrowserCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            defaultBrowserCard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            defaultBrowserCard.heightAnchor.constraint(equalToConstant: 264),

            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        defaultBrowserCard.dismissClosure = {
            self.dismissDefaultBrowserCard()
        }
    }

    public func dismissDefaultBrowserCard() {
        self.defaultBrowserCard.removeFromSuperview()
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    // MARK: - Headers

    private func getHeaderSize(forSection section: Int) -> CGSize {
        let indexPath = IndexPath(row: 0, section: section)
        let headerView = self.collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader, at: indexPath)
        let size = CGSize(width: collectionView.frame.width, height: UIView.layoutFittingExpandedSize.height)

        return headerView.systemLayoutSizeFitting(size,
                                                  withHorizontalFittingPriority: .required,
                                                  verticalFittingPriority: .fittingSizeLevel)
    }
}

// MARK: -  CollectionView Delegate

extension FirefoxHomeViewController: UICollectionViewDelegateFlowLayout {

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header", for: indexPath) as! ASHeaderView
            let title = FirefoxHomeSectionType(indexPath.section).title
            headerView.title = title
            headerView.titleLabel.accessibilityTraits = .header

            switch FirefoxHomeSectionType(indexPath.section) {
            case .pocket:
                headerView.moreButton.isHidden = true
                headerView.titleLabel.accessibilityIdentifier = a11y.SectionTitles.pocket
                return headerView

            case .jumpBackIn:
                if !hasSentJumpBackInSectionEvent
                    && viewModel.jumpBackInViewModel.isEnabled {
                    TelemetryWrapper.recordEvent(category: .action, method: .view, object: .jumpBackInImpressions, value: nil, extras: nil)
                    hasSentJumpBackInSectionEvent = true
                }
                headerView.moreButton.isHidden = false
                headerView.moreButton.setTitle(.RecentlySavedShowAllText, for: .normal)
                headerView.moreButton.addTarget(self, action: #selector(openTabTray), for: .touchUpInside)
                headerView.moreButton.accessibilityIdentifier = a11y.MoreButtons.jumpBackIn
                headerView.titleLabel.accessibilityIdentifier = a11y.SectionTitles.jumpBackIn
                prepareJumpBackInContextualHint(onView: headerView)

                return headerView

            case .recentlySaved:
                headerView.moreButton.isHidden = false
                headerView.moreButton.setTitle(.RecentlySavedShowAllText, for: .normal)
                headerView.moreButton.addTarget(self, action: #selector(openBookmarks), for: .touchUpInside)
                headerView.moreButton.accessibilityIdentifier = a11y.MoreButtons.recentlySaved
                headerView.titleLabel.accessibilityIdentifier = a11y.SectionTitles.recentlySaved
                return headerView

            case .historyHighlights:
                headerView.moreButton.isHidden = false
                headerView.moreButton.setTitle(.RecentlySavedShowAllText, for: .normal)
                headerView.moreButton.addTarget(self, action: #selector(openHistory), for: .touchUpInside)
                headerView.moreButton.accessibilityIdentifier = a11y.MoreButtons.historyHighlights
                headerView.titleLabel.accessibilityIdentifier = a11y.SectionTitles.historyHighlights
                return headerView

            case .topSites:
                headerView.titleLabel.accessibilityIdentifier = a11y.SectionTitles.topSites
                headerView.moreButton.isHidden = true
                return headerView
            case .libraryShortcuts:
                headerView.moreButton.isHidden = true
                headerView.titleLabel.accessibilityIdentifier = a11y.SectionTitles.library
                return headerView
            case .customizeHome:
                headerView.moreButton.isHidden = true
                return headerView
            case .logoHeader:
                headerView.moreButton.isHidden = true
                return headerView
            }
        default:
            return UICollectionReusableView()
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var cellSize = FirefoxHomeSectionType(indexPath.section).cellSize(for: self.traitCollection, frameWidth: self.view.frame.width)

        switch FirefoxHomeSectionType(indexPath.section) {
        case .topSites:
            let sectionDimension = viewModel.topSiteViewModel.getSectionDimension(for: traitCollection)
            cellSize.height *= CGFloat(sectionDimension.numberOfRows)
            cellSize.height += (FxHomeTopSitesViewModel.UX.parentInterItemSpacing * 2) * CGFloat(sectionDimension.numberOfRows)
            return cellSize

        case .jumpBackIn:
            cellSize.height *= CGFloat(viewModel.jumpBackInViewModel.numberOfItemsInColumn)
            cellSize.height += HistoryHighlightsCollectionCellUX.verticalPadding * 2
            return cellSize

        case .libraryShortcuts:
            let width = min(FirefoxHomeViewModel.UX.libraryShortcutsMaxWidth, cellSize.width)
            return CGSize(width: width, height: cellSize.height)

        case .historyHighlights:

            guard let items = viewModel.historyHighlightsViewModel.historyItems, !items.isEmpty else {
                return CGSize(width: cellSize.width, height: .zero)
            }

            // Returns the total height based on a variable column/row layout
            let rowNumber = items.count < HistoryHighlightsCollectionCellConstants.maxNumberOfItemsPerColumn ? items.count : HistoryHighlightsCollectionCellConstants.maxNumberOfItemsPerColumn

            let sectionHeight = (cellSize.height * CGFloat(rowNumber)) + HistoryHighlightsCollectionCellUX.verticalPadding * 2
            return CGSize(width: cellSize.width,
                          height: sectionHeight)

        default:
            return cellSize
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        switch FirefoxHomeSectionType(section) {
        case .pocket:
            return viewModel.pocketViewModel.shouldShow ? getHeaderSize(forSection: section) : .zero
        case .topSites:
            // Only show a header for top sites if the Firefox Browser logo is not showing
            if viewModel.topSiteViewModel.shouldShow {
                return viewModel.headerViewModel.shouldShow ? .zero : getHeaderSize(forSection: section)
            }

            return .zero
        case .libraryShortcuts:
            return viewModel.isYourLibrarySectionEnabled ? getHeaderSize(forSection: section) : .zero
        case .jumpBackIn:
            return viewModel.jumpBackInViewModel.shouldShow ? getHeaderSize(forSection: section) : .zero
        case .historyHighlights:
            return viewModel.historyHighlightsViewModel.shouldShow ? getHeaderSize(forSection: section) : .zero
        case .recentlySaved:
            return viewModel.recentlySavedViewModel.shouldShow ? getHeaderSize(forSection: section) : .zero
        default:
            return .zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        // This removes extra space since insetForSectionAt is called for all sections even if they are not showing
        // Root cause is that numberOfSections is always returned as FirefoxHomeSectionType.allCases
        let sideInsets = FirefoxHomeSectionType(section).sectionInsets(self.traitCollection, frameWidth: self.view.frame.width)
        let edgeInsets = UIEdgeInsets(top: 0, left: sideInsets, bottom: FirefoxHomeViewModel.UX.spacingBetweenSections, right: sideInsets)

        switch FirefoxHomeSectionType(section) {
        case .logoHeader:
            return viewModel.headerViewModel.shouldShow ? edgeInsets : .zero
        case .pocket:
            return viewModel.pocketViewModel.shouldShow ? edgeInsets : .zero
        case .topSites:
            return viewModel.topSiteViewModel.shouldShow ? edgeInsets : .zero
        case .libraryShortcuts:
            return viewModel.isYourLibrarySectionEnabled ? edgeInsets : .zero
        case .jumpBackIn:
            return viewModel.jumpBackInViewModel.shouldShow ? edgeInsets : .zero
        case .historyHighlights:
            return viewModel.historyHighlightsViewModel.shouldShow ? edgeInsets : .zero
        case .recentlySaved:
            return viewModel.recentlySavedViewModel.shouldShow ? edgeInsets : .zero
        default:
            return .zero
        }
    }
}

// MARK: - CollectionView Data Source

extension FirefoxHomeViewController {

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return FirefoxHomeSectionType.allCases.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.updateEnabledSections()
        return viewModel.enabledSections.contains(FirefoxHomeSectionType(section)) ? 1 : 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = FirefoxHomeSectionType(indexPath.section).cellIdentifier
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)

        switch FirefoxHomeSectionType(indexPath.section) {
        case .logoHeader:
            return configureLogoHeaderCell(cell, forIndexPath: indexPath)
        case .topSites:
            return configureTopSitesCell(cell, forIndexPath: indexPath)
        case .pocket:
            return configurePocketItemCell(cell, forIndexPath: indexPath)
        case .jumpBackIn:
            return configureJumpBackInCell(cell, forIndexPath: indexPath)
        case .recentlySaved:
            return configureRecentlySavedCell(cell, forIndexPath: indexPath)
        case .historyHighlights:
            return configureHistoryHighlightsCell(cell, forIndexPath: indexPath)
        case .libraryShortcuts:
            return configureLibraryShortcutsCell(cell, forIndexPath: indexPath)
        case .customizeHome:
            return configureCustomizeHomeCell(cell, forIndexPath: indexPath)
        }
    }

    func configureLibraryShortcutsCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        guard let libraryCell = cell as? ASLibraryCell else { return UICollectionViewCell() }
        let openBookmarks = { button in
            self.openBookmarks(button)
        }

        let openHistory = { button in
            self.openHistory(button)
        }

        let openDownloads = { button in
            self.openDownloads(button)
        }

        let openReadingList = { button in
            self.openReadingList(button)
        }

        libraryCell.buttonActions = [openBookmarks, openHistory, openDownloads, openReadingList]
        libraryCell.loadLayout()
        return cell
    }

    func configureLogoHeaderCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        guard let logoHeaderCell = cell as? FxHomeLogoHeaderCell else { return UICollectionViewCell() }
        let tap = UITapGestureRecognizer(target: self, action: #selector(changeHomepageWallpaper))
        tap.numberOfTapsRequired = 1
        logoHeaderCell.logoButton.addGestureRecognizer(tap)
        logoHeaderCell.setNeedsLayout()
        return logoHeaderCell
    }

    func configureTopSitesCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        guard let topSiteCell = cell as? TopSiteCollectionCell else { return UICollectionViewCell() }
        topSiteCell.viewModel = viewModel.topSiteViewModel
        topSiteCell.viewModel?.topSitesShownInSection = indexPath.section
        topSiteCell.reloadLayout()
        topSiteCell.setNeedsLayout()

        viewModel.topSiteViewModel.tilePressedHandler = { [weak self] site, isGoogle in
            guard let url = site.url.asURL else { return }
            self?.showSiteWithURLHandler(url, isGoogleTopSite: isGoogle)
        }

        viewModel.topSiteViewModel.tileLongPressedHandler = { [weak self] indexPath in
            self?.presentContextMenu(for: indexPath)
        }

        return cell
    }

    private func configurePocketItemCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        guard let pocketCell = cell as? FxHomePocketCollectionCell else { return UICollectionViewCell() }

        viewModel.pocketViewModel.onTapTileAction = { [weak self] url in
            self?.showSiteWithURLHandler(url)
        }

        viewModel.pocketViewModel.onLongPressTileAction = { [weak self] indexPath in
            self?.presentContextMenu(for: indexPath)
        }

        viewModel.pocketViewModel.recordSectionHasShown()
        pocketCell.viewModel = viewModel.pocketViewModel
        pocketCell.viewModel?.pocketShownInSection = indexPath.section
        pocketCell.reloadLayout()
        pocketCell.setNeedsLayout()

        return pocketCell
    }

    private func configureRecentlySavedCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        guard let recentlySavedCell = cell as? FxHomeRecentlySavedCollectionCell else { return UICollectionViewCell() }
        recentlySavedCell.viewModel = viewModel.recentlySavedViewModel
        recentlySavedCell.homePanelDelegate = homePanelDelegate
        recentlySavedCell.libraryPanelDelegate = libraryPanelDelegate
        recentlySavedCell.collectionView.reloadData()
        recentlySavedCell.setNeedsLayout()

        return recentlySavedCell
    }

    private func configureJumpBackInCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        guard let jumpBackInCell = cell as? FxHomeJumpBackInCollectionCell else { return UICollectionViewCell() }
        jumpBackInCell.viewModel = viewModel.jumpBackInViewModel

        viewModel.jumpBackInViewModel.onTapGroup = { [weak self] tab in
            self?.homePanelDelegate?.homePanelDidRequestToOpenTabTray(withFocusedTab: tab)
        }

        jumpBackInCell.reloadLayout()
        jumpBackInCell.setNeedsLayout()

        return jumpBackInCell
    }

    private func configureHistoryHighlightsCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        guard let historyCell = cell as? FxHomeHistoryHighlightsCollectionCell else { return UICollectionViewCell() }

        guard let items = viewModel.historyHighlightsViewModel.historyItems, !items.isEmpty else { return UICollectionViewCell() }
        viewModel.historyHighlightsViewModel.onTapItem = { [weak self] highlight in
            guard let url = highlight.siteUrl else {
                self?.openHistory(UIButton())
                return
            }

            self?.homePanelDelegate?.homePanel(didSelectURL: url, visitType: .link, isGoogleTopSite: false)
        }

        historyCell.viewModel = viewModel.historyHighlightsViewModel
        historyCell.viewModel?.recordSectionHasShown()
        historyCell.reloadLayout()
        historyCell.setNeedsLayout()

        return historyCell
    }

    private func configureCustomizeHomeCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        guard let customizeHomeCell = cell as? FxHomeCustomizeHomeView else { return UICollectionViewCell() }
        customizeHomeCell.goToSettingsButton.addTarget(
            self,
            action: #selector(openCustomizeHomeSettings),
            for: .touchUpInside)
        customizeHomeCell.setNeedsLayout()

        return customizeHomeCell
    }
}

// MARK: - Data Management

extension FirefoxHomeViewController {

    /// Reload all data including refreshing cells content and fetching data from backend
    func reloadAll() {
        self.collectionView.reloadData()

        DispatchQueue.global(qos: .userInteractive).async {
            self.viewModel.updateData()
        }
    }
}

// MARK: - Actions Handling

extension FirefoxHomeViewController {
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
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .yourLibrarySection,
                                         extras: [TelemetryWrapper.EventObject.libraryPanel.rawValue: TelemetryWrapper.EventValue.historyPanel.rawValue])
        }
    }

    @objc func openReadingList(_ sender: UIButton) {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .readingList)
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .firefoxHomepage,
                                     value: .yourLibrarySection,
                                     extras: [TelemetryWrapper.EventObject.libraryPanel.rawValue: TelemetryWrapper.EventValue.readingListPanel.rawValue])
    }

    @objc func openDownloads(_ sender: UIButton) {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .downloads)
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .firefoxHomepage,
                                     value: .yourLibrarySection,
                                     extras: [TelemetryWrapper.EventObject.libraryPanel.rawValue: TelemetryWrapper.EventValue.downloadsPanel.rawValue])
    }

    @objc func openCustomizeHomeSettings() {
        homePanelDelegate?.homePanelDidRequestToOpenSettings(at: .customizeHomepage)
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .firefoxHomepage,
                                     value: .customizeHomepageButton)
    }
    
    @objc func contextualHintPresented() {
        homePanelDelegate?.homePanelDidPresentContextualHintOf(type: .jumpBackIn)
    }
    
    @objc func openTabsSettings() {
        homePanelDelegate?.homePanelDidRequestToOpenSettings(at: .customizeTabs)
    }

    @objc func changeHomepageWallpaper() {
        wallpaperView.cycleWallpaper()
    }
}

// MARK: - Context Menu

extension FirefoxHomeViewController: HomePanelContextMenu {
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?) {

        fetchBookmarkStatus(for: site) {
            guard let contextMenu = completionHandler() else { return }
            self.present(contextMenu, animated: true, completion: nil)
        }
    }

    func getSiteDetails(for indexPath: IndexPath) -> Site? {
        switch FirefoxHomeSectionType(indexPath.section) {
        case .pocket:
            return viewModel.pocketViewModel.getSitesDetail(for: indexPath.row)
        case .topSites:
            return viewModel.topSiteViewModel.tileManager.getSiteDetail(index: indexPath.row)
        default:
            return nil
        }
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonRowActions]? {
        guard let siteURL = URL(string: site.url) else { return nil }
        var sourceView: UIView?

        switch FirefoxHomeSectionType(indexPath.section) {
        case .topSites:
            if let topSiteCell = collectionView?.cellForItem(at: IndexPath(row: 0, section: indexPath.section)) as? TopSiteCollectionCell {
                sourceView = topSiteCell.collectionView.cellForItem(at: IndexPath(row: indexPath.row, section: 0))
            }
        case .pocket:
            if let pocketCell = collectionView?.cellForItem(at: IndexPath(row: 0, section: indexPath.section)) as? FxHomePocketCollectionCell {
                sourceView = pocketCell.collectionView.cellForItem(at: IndexPath(row: indexPath.row, section: 0))
            }
        default:
            return nil
        }

        let isPocket = FirefoxHomeSectionType(indexPath.section) == .pocket
        guard var actions = getDefaultContextMenuActions(for: site,
                                                         homePanelDelegate: homePanelDelegate,
                                                         isPocket: isPocket,
                                                         isZeroSearch: isZeroSearch)
        else { return nil }

        let bookmarkAction = getBookmarkAction(site: site)
        let shareAction = getShareAction(siteURL: siteURL, sourceView: sourceView)
        actions.append(contentsOf: [bookmarkAction,
                                    shareAction])

        if FirefoxHomeSectionType(indexPath.section) == .topSites {
            actions.append(contentsOf: viewModel.topSiteViewModel.getTopSitesAction(site: site))
        }
        
        return actions
    }

    private func getBookmarkAction(site: Site) -> PhotonRowActions {
        let bookmarkAction: SingleActionViewModel
        if site.bookmarked ?? false {
            bookmarkAction = getRemoveBookmarkAction(site: site)
        } else {
            bookmarkAction = getAddBookmarkAction(site: site)
        }
        return bookmarkAction.items
    }

    private func getRemoveBookmarkAction(site: Site) -> SingleActionViewModel {
        return SingleActionViewModel(title: .RemoveBookmarkContextMenuTitle, iconString: ImageIdentifiers.actionRemoveBookmark, tapHandler: { _ in
            self.viewModel.profile.places.deleteBookmarksWithURL(url: site.url) >>== {
                self.viewModel.topSiteViewModel.tileManager.refreshIfNeeded(forceTopSites: false)
                site.setBookmarked(false)
            }

            TelemetryWrapper.recordEvent(category: .action, method: .delete, object: .bookmark, value: .activityStream)
        })
    }

    private func getAddBookmarkAction(site: Site) -> SingleActionViewModel {
        return SingleActionViewModel(title: .BookmarkContextMenuTitle, iconString: ImageIdentifiers.actionAddBookmark, tapHandler: { _ in
            let shareItem = ShareItem(url: site.url, title: site.title, favicon: site.icon)
            _ = self.viewModel.profile.places.createBookmark(parentGUID: BookmarkRoots.MobileFolderGUID, url: shareItem.url, title: shareItem.title)

            var userData = [QuickActions.TabURLKey: shareItem.url]
            if let title = shareItem.title {
                userData[QuickActions.TabTitleKey] = title
            }
            QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(.openLastBookmark,
                                                                                withUserData: userData,
                                                                                toApplication: .shared)
            site.setBookmarked(true)
            self.viewModel.topSiteViewModel.tileManager.refreshIfNeeded(forceTopSites: true)
            TelemetryWrapper.recordEvent(category: .action, method: .add, object: .bookmark, value: .activityStream)
        })
    }

    private func getShareAction(siteURL: URL, sourceView: UIView?) -> PhotonRowActions {
        return SingleActionViewModel(title: .ShareContextMenuTitle, iconString: ImageIdentifiers.share, tapHandler: { _ in
            let helper = ShareExtensionHelper(url: siteURL, tab: nil)
            let controller = helper.createActivityViewController { (_, _) in }
            if UIDevice.current.userInterfaceIdiom == .pad, let popoverController = controller.popoverPresentationController {
                let cellRect = sourceView?.frame ?? .zero
                let cellFrameInSuperview = self.collectionView?.convert(cellRect, to: self.collectionView) ?? .zero

                popoverController.sourceView = sourceView
                popoverController.sourceRect = CGRect(origin: CGPoint(x: cellFrameInSuperview.size.width/2, y: cellFrameInSuperview.height/2), size: .zero)
                popoverController.permittedArrowDirections = [.up, .down, .left]
                popoverController.delegate = self
            }
            self.presentWithModalDismissIfNeeded(controller, animated: true)
        }).items
    }

    private func fetchBookmarkStatus(for site: Site, completionHandler: @escaping () -> Void) {
        viewModel.profile.places.isBookmarked(url: site.url).uponQueue(.main) { result in
            let isBookmarked = result.successValue ?? false
            site.setBookmarked(isBookmarked)
            completionHandler()
        }
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
    func reloadSection(index: Int?) {
        DispatchQueue.main.async {
            if let index = index {
                let indexSet = IndexSet([index])
                self.collectionView.reloadSections(indexSet)
            } else {
                self.collectionView.reloadData()
            }
        }
    }
}

// MARK: - Notifiable
extension FirefoxHomeViewController: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .TabsPrivacyModeChanged:
            adjustPrivacySensitiveSections(notification: notification)
        default:
            reloadAll()
        }
    }
}
