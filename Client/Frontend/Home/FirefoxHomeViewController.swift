// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import UIKit
import Storage
import SDWebImage
import XCGLogger
import SyncTelemetry
import MozillaAppServices

private let log = Logger.browserLogger

// MARK: -  UX

struct FirefoxHomeUX {
    static let homeHorizontalCellHeight: CGFloat = 120
    static let recentlySavedCellHeight: CGFloat = 136
    static let historyHighlightsCellHeight: CGFloat = 68
    static let sectionInsetsForSizeClass = UXSizeClasses(compact: 0, regular: 101, other: 15)
    static let numberOfItemsPerRowForSizeClassIpad = UXSizeClasses(compact: 3, regular: 4, other: 2)
    static let spacingBetweenSections: CGFloat = 24
    static let sectionInsetsForIpad: CGFloat = 101
    static let minimumInsets: CGFloat = 15
    static let libraryShortcutsHeight: CGFloat = 90
    static let libraryShortcutsMaxWidth: CGFloat = 375
    static let customizeHomeHeight: CGFloat = 100
    static let logoHeaderHeight: CGFloat = 85
}

/*
 Size classes are the way Apple requires us to specify our UI.
 Split view on iPad can make a landscape app appear with the demensions of an iPhone app
 Use UXSizeClasses to specify things like offsets/itemsizes with respect to size classes
 For a primer on size classes https://useyourloaf.com/blog/size-classes/
 */
struct UXSizeClasses {
    var compact: CGFloat
    var regular: CGFloat
    var unspecified: CGFloat

    init(compact: CGFloat, regular: CGFloat, other: CGFloat) {
        self.compact = compact
        self.regular = regular
        self.unspecified = other
    }

    subscript(sizeClass: UIUserInterfaceSizeClass) -> CGFloat {
        switch sizeClass {
        case .compact:
            return self.compact
        case .regular:
            return self.regular
        case .unspecified:
            return self.unspecified
        @unknown default:
            fatalError()
        }
    }
}

// MARK: - Home Panel

protocol HomePanelDelegate: AnyObject {
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool, selectNewTab: Bool)
    func homePanel(didSelectURL url: URL, visitType: VisitType, isGoogleTopSite: Bool)
    func homePanelDidRequestToOpenLibrary(panel: LibraryPanelType)
    func homePanelDidRequestToOpenTabTray(withFocusedTab tabToFocus: Tab?)
    func homePanelDidRequestToOpenSettings(at settingsPage: AppSettingsDeeplinkOption)
    func homePanelDidPresentContextualHintOf(type: ContextualHintViewType)
}

extension HomePanelDelegate {
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool, selectNewTab: Bool = false) {
        homePanelDidRequestToOpenInNewTab(url, isPrivate: isPrivate, selectNewTab: selectNewTab)
    }
}

protocol HomePanel: NotificationThemeable {
    var homePanelDelegate: HomePanelDelegate? { get set }
}

enum HomePanelType: Int {
    case topSites = 0

    var internalUrl: URL {
        let aboutUrl: URL! = URL(string: "\(InternalURL.baseUrl)/\(AboutHomeHandler.path)")
        return URL(string: "#panel=\(self.rawValue)", relativeTo: aboutUrl)!
    }
}

protocol HomePanelContextMenu {
    func getSiteDetails(for indexPath: IndexPath) -> Site?
    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonRowActions]?
    func presentContextMenu(for indexPath: IndexPath)
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?)
}

extension HomePanelContextMenu {
    func presentContextMenu(for indexPath: IndexPath) {
        guard let site = getSiteDetails(for: indexPath) else { return }

        presentContextMenu(for: site, with: indexPath, completionHandler: {
            return self.contextMenu(for: site, with: indexPath)
        })
    }

    func contextMenu(for site: Site, with indexPath: IndexPath) -> PhotonActionSheet? {
        guard let actions = getContextMenuActions(for: site, with: indexPath) else { return nil }

        let viewModel = PhotonActionSheetViewModel(actions: [actions], site: site, modalStyle: .overFullScreen)
        let contextMenu = PhotonActionSheet(viewModel: viewModel)
        contextMenu.modalTransitionStyle = .crossDissolve

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        return contextMenu
    }

    func getDefaultContextMenuActions(for site: Site, homePanelDelegate: HomePanelDelegate?) -> [PhotonRowActions]? {
        guard let siteURL = URL(string: site.url) else { return nil }

        let openInNewTabAction = SingleActionViewModel(title: .OpenInNewTabContextMenuTitle, iconString: ImageIdentifiers.newTab) { _ in
            homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: false)
        }

        let openInNewPrivateTabAction = SingleActionViewModel(title: .OpenInNewPrivateTabContextMenuTitle, iconString: "quick_action_new_private_tab") { _ in
            homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
        }

        return [PhotonRowActions(openInNewTabAction), PhotonRowActions(openInNewPrivateTabAction)]
    }
}

// MARK: - HomeVC

class FirefoxHomeViewController: UICollectionViewController, HomePanel {
    // MARK: - Typealiases
    typealias a11y = AccessibilityIdentifiers.FirefoxHomepage

    lazy var wallpaperView: WallpaperBackgroundView = .build { _ in }

    // MARK: - Operational Variables
    weak var homePanelDelegate: HomePanelDelegate?
    weak var libraryPanelDelegate: LibraryPanelDelegate?
    fileprivate let flowLayout = UICollectionViewFlowLayout()
    fileprivate var hasSentJumpBackInSectionEvent = false
    fileprivate var hasSentHistoryHighlightsSectionEvent = false
    fileprivate var isZeroSearch: Bool
    fileprivate var wallpaperManager: WallpaperManager
    private var viewModel: FirefoxHomeViewModel

    var contextualHintViewController: ContextualHintViewController

    fileprivate lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    // Not used for displaying. Only used for calculating layout.
    lazy var topSiteCell: ASHorizontalScrollCell = {
        let customCell = ASHorizontalScrollCell(frame: CGRect(width: self.view.frame.size.width, height: 0))
        customCell.delegate = self.viewModel.topSitesManager
        return customCell
    }()

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
         experiments: NimbusApi = Experiments.shared,
         wallpaperManager: WallpaperManager = WallpaperManager()
    ) {
        self.isZeroSearch = isZeroSearch
        self.wallpaperManager = wallpaperManager
        let isPrivate = BrowserViewController.foregroundBVC().tabManager.selectedTab?.isPrivate ?? true
        self.viewModel = FirefoxHomeViewModel(profile: profile,
                                              isZeroSearch: isZeroSearch,
                                              isPrivate: isPrivate,
                                              experiments: experiments)
        let contextualViewModel = ContextualHintViewModel(forHintType: .jumpBackIn,
                                                          with: viewModel.profile)
        self.contextualHintViewController = ContextualHintViewController(with: contextualViewModel)

        super.init(collectionViewLayout: flowLayout)

        viewModel.pocketViewModel.onTapTileAction = { [weak self] url in
            self?.showSiteWithURLHandler(url)
        }

        viewModel.pocketViewModel.onLongPressTileAction = { [weak self] indexPath in
            self?.presentContextMenu(for: indexPath)
        }

        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        collectionView?.addGestureRecognizer(longPressRecognizer)

        // TODO: .TabClosed notif should be in JumpBackIn view only to reload it's data, but can't right now since doesn't self-size
        let refreshEvents: [Notification.Name] = [.DynamicFontChanged,
                                                  .HomePanelPrefsChanged,
                                                  .DisplayThemeChanged,
                                                  .TabClosed,
                                                  .WallpaperDidChange,
                                                  .TabsPrivacyModeChanged]
        refreshEvents.forEach { NotificationCenter.default.addObserver(self, selector: #selector(reload), name: $0, object: nil) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        contextualHintViewController.stopTimer()
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

        viewModel.profile.panelDataObservers.activityStream.delegate = self

        applyTheme()

        topSiteCell.collectionView.reloadData()
        if let collectionView = self.collectionView, collectionView.numberOfSections > 0, collectionView.numberOfItems(inSection: 0) > 0 {
            collectionView.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadAll()
    }

    override func viewDidAppear(_ animated: Bool) {
        viewModel.experiments.recordExposureEvent(featureId: .homescreen)
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

        wallpaperView.updateImageForOrientationChange()
    }

    // MARK: - Helpers
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.viewModel.topSitesManager.currentTraits = self.traitCollection
        applyTheme()
    }

    @objc func reload(notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged,
                .DynamicFontChanged,
                .WallpaperDidChange:
            reloadAll(shouldUpdateData: false)
        case .TabsPrivacyModeChanged:
            adjustPrivacySensitiveSections(notification: notification)
        default:
            reloadAll()
        }
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

            switch FirefoxHomeSectionType(indexPath.section) {
            case .pocket:
                headerView.moreButton.isHidden = true
                headerView.titleLabel.accessibilityIdentifier = a11y.SectionTitles.pocket
                return headerView

            case .jumpBackIn:
                if !hasSentJumpBackInSectionEvent
                    && viewModel.shouldShowJumpBackInSection {
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
            // Create a temporary cell so we can calculate the height.
            let layout = topSiteCell.collectionView.collectionViewLayout as! HorizontalFlowLayout
            let estimatedLayout = layout.calculateLayout(for: CGSize(width: cellSize.width, height: 0))
            return CGSize(width: cellSize.width, height: estimatedLayout.size.height)

        case .jumpBackIn:
            cellSize.height *= CGFloat(viewModel.jumpBackInViewModel.numberOfItemsInColumn)
            cellSize.height += HistoryHighlightsCollectionCellUX.verticalPadding * 2
            return cellSize

        case .libraryShortcuts:
            let width = min(FirefoxHomeUX.libraryShortcutsMaxWidth, cellSize.width)
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
            return viewModel.shouldShowPocketSection ? getHeaderSize(forSection: section) : .zero
        case .topSites:
            // Only show a header for top sites if the Firefox Browser logo is not showing
            if viewModel.isTopSitesSectionEnabled {
                return viewModel.shouldShowFxLogoHeader ? .zero : getHeaderSize(forSection: section)
            }

            return .zero
        case .libraryShortcuts:
            return viewModel.isYourLibrarySectionEnabled ? getHeaderSize(forSection: section) : .zero
        case .jumpBackIn:
            return viewModel.shouldShowJumpBackInSection ? getHeaderSize(forSection: section) : .zero
        case .historyHighlights:
            return viewModel.shouldShowHistoryHightlightsSection ? getHeaderSize(forSection: section) : .zero
        case .recentlySaved:
            return viewModel.shouldShowRecentlySavedSection ? getHeaderSize(forSection: section) : .zero
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
        let insets = FirefoxHomeSectionType(section).sectionInsets(self.traitCollection, frameWidth: self.view.frame.width)
        return UIEdgeInsets(top: 0, left: insets, bottom: FirefoxHomeUX.spacingBetweenSections, right: insets)
    }

    fileprivate func showSiteWithURLHandler(_ url: URL, isGoogleTopSite: Bool = false) {
        let visitType = VisitType.bookmark
        homePanelDelegate?.homePanel(didSelectURL: url, visitType: visitType, isGoogleTopSite: isGoogleTopSite)
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
        let targets = [#selector(openBookmarks), #selector(openHistory), #selector(openDownloads), #selector(openReadingList)]
        libraryCell.libraryButtons.map({ $0.button }).zip(targets).forEach { (button, selector) in
            button.removeTarget(nil, action: nil, for: .allEvents)
            button.addTarget(self, action: selector, for: .touchUpInside)
        }
        libraryCell.applyTheme()

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
        guard let topSiteCell = cell as? ASHorizontalScrollCell else { return UICollectionViewCell() }
        topSiteCell.delegate = self.viewModel.topSitesManager
        topSiteCell.setNeedsLayout()
        topSiteCell.collectionView.reloadData()
        return cell
    }

    private func configurePocketItemCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        guard let pocketCell = cell as? FxHomePocketCollectionCell else { return UICollectionViewCell() }
        pocketCell.viewModel = viewModel.pocketViewModel
        pocketCell.viewModel?.pocketShownInSection = indexPath.section
        pocketCell.reloadLayout()
        pocketCell.setNeedsLayout()

        viewModel.pocketViewModel.recordSectionHasShown()

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

extension FirefoxHomeViewController: DataObserverDelegate {

    /// Reload all data including refreshing cells content and fetching data from backend
    /// - Parameter shouldUpdateData: True means backend data should be refetched
    func reloadAll(shouldUpdateData: Bool = true) {
        loadTopSitesData()
        guard shouldUpdateData else { return }
        DispatchQueue.global(qos: .userInteractive).async {
            self.reloadSectionsData()
        }
    }

    private func reloadSectionsData() {
        // TODO: Reload with a protocol comformance once all sections are standardized
        // Idea is that each section will load it's data from it's own view model
        if viewModel.isRecentlySavedSectionEnabled {
            viewModel.recentlySavedViewModel.updateData {}
        }

        // Jump back in access tabManager and this needs to be done on the main thread at the moment
        DispatchQueue.main.async {
            if self.viewModel.isJumpBackInSectionEnabled {
                self.viewModel.jumpBackInViewModel.updateData {}
            }
        }

        if viewModel.isPocketSectionEnabled {
            viewModel.pocketViewModel.updateData {
                // TODO: Once section are standardized, reload only the pocket section when data is updated
                self.collectionView.reloadData()
            }
        }
        
        
        if viewModel.isHistoryHightlightsSectionEnabled {
            // TODO: Once section are standardized, reload only the historyHighligthst section when data is updated
            viewModel.historyHighlightsViewModel.updateData {
                self.collectionView.reloadData()
            }
        }
    }

    // Reloads both highlights and top sites data from their respective caches. Does not invalidate the cache.
    // See ActivityStreamDataObserver for invalidation logic.
    private func loadTopSitesData() {
        TopSitesHandler.getTopSites(profile: viewModel.profile).uponQueue(.main) { [weak self] result in
            guard let self = self else { return }

            // If there is no pending cache update and highlights are empty. Show the onboarding screen
            self.collectionView?.reloadData()

            self.viewModel.topSitesManager.currentTraits = self.view.traitCollection

            let numRows = max(self.viewModel.profile.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows) ?? TopSitesRowCountSettingsController.defaultNumberOfRows, 1)

            let maxItems = Int(numRows) * self.viewModel.topSitesManager.numberOfHorizontalItems()

            var sites = Array(result.prefix(maxItems))

            // Check if all result items are pinned site
            var pinnedSites = 0
            result.forEach {
                if let _ = $0 as? PinnedSite {
                    pinnedSites += 1
                }
            }
            // Special case: Adding Google topsite
            let googleTopSite = GoogleTopSiteHelper(prefs: self.viewModel.profile.prefs)
            if !googleTopSite.isHidden, let gSite = googleTopSite.suggestedSiteData() {
                // Once Google top site is added, we don't remove unless it's explicitly unpinned
                // Add it when pinned websites are less than max pinned sites
                if googleTopSite.hasAdded || pinnedSites < maxItems {
                    sites.insert(gSite, at: 0)
                    // Purge unwated websites from the end of list
                    if sites.count > maxItems {
                        sites.removeLast(sites.count - maxItems)
                    }
                    googleTopSite.hasAdded = true
                }
            }
            self.viewModel.topSitesManager.content = sites
            self.viewModel.topSitesManager.urlPressedHandler = { [unowned self] site, indexPath in
                self.longPressRecognizer.isEnabled = false
                guard let url = site.url.asURL else { return }
                let isGoogleTopSiteUrl = url.absoluteString == GoogleTopSiteConstants.usUrl || url.absoluteString == GoogleTopSiteConstants.rowUrl
                self.topSiteTracking(site: site, position: indexPath.item)
                self.showSiteWithURLHandler(url as URL, isGoogleTopSite: isGoogleTopSiteUrl)
            }

            // Refresh the AS data in the background so we'll have fresh data next time we show.
            self.viewModel.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: false)
        }
    }

    func topSiteTracking(site: Site, position: Int) {
        // Top site extra
        let topSitePositionKey = TelemetryWrapper.EventExtraKey.topSitePosition.rawValue
        let topSiteTileTypeKey = TelemetryWrapper.EventExtraKey.topSiteTileType.rawValue
        let isPinnedAndGoogle = site is PinnedSite && site.guid == GoogleTopSiteConstants.googleGUID
        let isPinnedOnly = site is PinnedSite
        let isSuggestedSite = site is SuggestedSite
        let type = isPinnedAndGoogle ? "google" : isPinnedOnly ? "user-added" : isSuggestedSite ? "suggested" : "history-based"
        let topSiteExtra = [topSitePositionKey : "\(position)", topSiteTileTypeKey: type]

        // Origin extra
        let originExtra = TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch)
        let extras = originExtra.merge(with: topSiteExtra)

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .topSiteTile,
                                     value: nil,
                                     extras: extras)
    }

    // Invoked by the ActivityStreamDataObserver when highlights/top sites invalidation is complete.
    func didInvalidateDataSources(refresh forced: Bool, topSitesRefreshed: Bool) {
        // Do not reload panel unless we're currently showing the highlight intro or if we
        // force-reloaded the highlights or top sites. This should prevent reloading the
        // panel after we've invalidated in the background on the first load.
        if forced {
            reloadAll()
        }
    }

    func hideURLFromTopSites(_ site: Site) {
        guard let host = site.tileURL.normalizedHost else { return }

        let url = site.tileURL.absoluteString
        // if the default top sites contains the siteurl. also wipe it from default suggested sites.
        if !defaultTopSites().filter({ $0.url == url }).isEmpty {
            deleteTileForSuggestedSite(url)
        }
        viewModel.profile.history.removeHostFromTopSites(host).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            self.viewModel.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: true)
        }
    }

    func pinTopSite(_ site: Site) {
        viewModel.profile.history.addPinnedTopSite(site).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            self.viewModel.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: true)
        }
    }

    func removePinTopSite(_ site: Site) {
        // Special Case: Hide google top site
        if site.guid == GoogleTopSiteConstants.googleGUID {
            let gTopSite = GoogleTopSiteHelper(prefs: self.viewModel.profile.prefs)
            gTopSite.isHidden = true
        }

        viewModel.profile.history.removeFromPinnedTopSites(site).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            self.viewModel.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: true)
        }
    }

    fileprivate func deleteTileForSuggestedSite(_ siteURL: String) {
        var deletedSuggestedSites = viewModel.profile.prefs.arrayForKey(TopSitesHandler.DefaultSuggestedSitesKey) as? [String] ?? []
        deletedSuggestedSites.append(siteURL)
        viewModel.profile.prefs.setObject(deletedSuggestedSites, forKey: TopSitesHandler.DefaultSuggestedSitesKey)
    }

    func defaultTopSites() -> [Site] {
        let suggested = SuggestedSites.asArray()
        let deleted = viewModel.profile.prefs.arrayForKey(TopSitesHandler.DefaultSuggestedSitesKey) as? [String] ?? []
        return suggested.filter({ deleted.firstIndex(of: $0.url) == .none })
    }

    @objc fileprivate func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }

        let point = longPressGestureRecognizer.location(in: self.collectionView)
        guard let fxHomeIndexPath = self.collectionView?.indexPathForItem(at: point) else { return }

        // Here, we must be careful which `section` we're passing in, as it can be the
        // homescreen's section, or a sub-view's section, thereby requiring a custom
        // `IndexPath` object to be created and passed around.
        switch FirefoxHomeSectionType(fxHomeIndexPath.section) {
        case .topSites:
            let topSiteCell = self.collectionView?.cellForItem(at: fxHomeIndexPath) as! ASHorizontalScrollCell
            let pointInTopSite = longPressGestureRecognizer.location(in: topSiteCell.collectionView)
            guard let topSiteItemIndexPath = topSiteCell.collectionView.indexPathForItem(at: pointInTopSite) else { return }
            let topSiteIndexPath = IndexPath(row: topSiteItemIndexPath.row,
                                             section: fxHomeIndexPath.section)
            presentContextMenu(for: topSiteIndexPath)
        default:
            return
        }
    }

    fileprivate func fetchBookmarkStatus(for site: Site, completionHandler: @escaping () -> Void) {
        viewModel.profile.places.isBookmarked(url: site.url).uponQueue(.main) { result in
            let isBookmarked = result.successValue ?? false
            site.setBookmarked(isBookmarked)
            completionHandler()
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

    @objc func openReadingList() {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .readingList)
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .firefoxHomepage,
                                     value: .yourLibrarySection,
                                     extras: [TelemetryWrapper.EventObject.libraryPanel.rawValue: TelemetryWrapper.EventValue.readingListPanel.rawValue])
    }

    @objc func openDownloads() {
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
        self.homePanelDelegate?.homePanelDidPresentContextualHintOf(type: .jumpBackIn)
    }
    
    @objc func openTabsSettings() {
        homePanelDelegate?.homePanelDidRequestToOpenSettings(at: .customizeTabs)
    }

    @objc func changeHomepageWallpaper() {
        wallpaperView.cycleWallpaper()
    }

    func animateFirefoxLogo() {
        guard shouldRunLogoAnimation(),
              let cell = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? FxHomeLogoHeaderCell
        else { return }
        
        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { _ in
            cell.runLogoAnimation()
        })
    }
    
    private func shouldRunLogoAnimation() -> Bool {
        let localesAnimationIsAvailableFor = ["en_US", "es_US"]
        guard viewModel.profile.prefs.intForKey(PrefsKeys.IntroSeen) != nil,
              !UserDefaults.standard.bool(forKey: PrefsKeys.WallpaperLogoHasShownAnimation),
              localesAnimationIsAvailableFor.contains(Locale.current.identifier)
        else { return false }

        return true
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
            return viewModel.topSitesManager.content[indexPath.item]
        default:
            return nil
        }
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonRowActions]? {
        guard let siteURL = URL(string: site.url) else { return nil }
        var sourceView: UIView?

        switch FirefoxHomeSectionType(indexPath.section) {
        case .topSites:
            if let topSiteCell = collectionView?.cellForItem(at: IndexPath(row: 0, section: indexPath.section)) as? ASHorizontalScrollCell {
                sourceView = topSiteCell.collectionView.cellForItem(at: IndexPath(row: indexPath.row, section: 0))
            }
        case .pocket:
            if let pocketCell = collectionView?.cellForItem(at: IndexPath(row: 0, section: indexPath.section)) as? FxHomePocketCollectionCell {
                sourceView = pocketCell.collectionView.cellForItem(at: IndexPath(row: indexPath.row, section: 0))
            }
        default:
            return nil
        }

        let openInNewTabAction = SingleActionViewModel(title: .OpenInNewTabContextMenuTitle, iconString: ImageIdentifiers.newTab) { [weak self] _ in
            self?.homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: false)
            if FirefoxHomeSectionType(indexPath.section) == .pocket, let isZeroSearch = self?.isZeroSearch {
                let originExtras = TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch)
                TelemetryWrapper.recordEvent(category: .action,
                                             method: .tap,
                                             object: .pocketStory,
                                             extras: originExtras)
            }
        }

        let openInNewPrivateTabAction = SingleActionViewModel(title: .OpenInNewPrivateTabContextMenuTitle, iconString: "quick_action_new_private_tab") { _ in
            self.homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
        }

        let bookmarkAction: SingleActionViewModel
        if site.bookmarked ?? false {
            bookmarkAction = SingleActionViewModel(title: .RemoveBookmarkContextMenuTitle, iconString: "action_bookmark_remove", tapHandler: { _ in
                self.viewModel.profile.places.deleteBookmarksWithURL(url: site.url) >>== {
                    self.viewModel.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: false)
                    site.setBookmarked(false)
                }

                TelemetryWrapper.recordEvent(category: .action, method: .delete, object: .bookmark, value: .activityStream)
            })
        } else {
            bookmarkAction = SingleActionViewModel(title: .BookmarkContextMenuTitle, iconString: "action_bookmark", tapHandler: { _ in
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
                self.viewModel.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: true)
                TelemetryWrapper.recordEvent(category: .action, method: .add, object: .bookmark, value: .activityStream)
            })
        }

        let shareAction = SingleActionViewModel(title: .ShareContextMenuTitle, iconString: ImageIdentifiers.share, tapHandler: { _ in
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
        })

        let removeTopSiteAction = SingleActionViewModel(title: .RemoveContextMenuTitle, iconString: "action_remove", tapHandler: { _ in
            self.hideURLFromTopSites(site)
        })

        let pinTopSite = SingleActionViewModel(title: .AddToShortcutsActionTitle, iconString: ImageIdentifiers.addShortcut, tapHandler: { _ in
            self.pinTopSite(site)
        })

        let removePinTopSite = SingleActionViewModel(title: .RemoveFromShortcutsActionTitle, iconString: "action_unpin", tapHandler: { _ in
            self.removePinTopSite(site)
        })

        let topSiteActions: [PhotonRowActions]
        if let _ = site as? PinnedSite {
            topSiteActions = [PhotonRowActions(removePinTopSite)]
        } else {
            topSiteActions = [PhotonRowActions(pinTopSite), PhotonRowActions(removeTopSiteAction)]
        }

        var actions = [PhotonRowActions(openInNewTabAction),
                       PhotonRowActions(openInNewPrivateTabAction),
                       PhotonRowActions(bookmarkAction),
                       PhotonRowActions(shareAction)]

        switch FirefoxHomeSectionType(indexPath.section) {
        case .topSites: actions.append(contentsOf: topSiteActions)
        default: break
        }
        
        return actions
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

