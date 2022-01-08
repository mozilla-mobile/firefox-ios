// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import UIKit
import Storage
import SDWebImage
import XCGLogger
import SyncTelemetry
import Nimbus

private let log = Logger.browserLogger

// MARK: -  UX

struct FirefoxHomeUX {
    static let homeHorizontalCellHeight: CGFloat = 120
    static let recentlySavedCellHeight: CGFloat = 136
    static let historyHighlightsCellHeight: CGFloat = 70
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

struct FxHomeDevStrings {
    struct GestureRecognizers {
        static let dismissOverlay = "dismissOverlay"
    }
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
    func homePanelDidRequestToCustomizeHomeSettings()
    func homePanelDidPresentContextualHint(type: ContextualHintViewType)
    func homePanelDidDismissContextualHint(type: ContextualHintViewType)
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
    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonActionSheetItem]?
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
        guard let actions = self.getContextMenuActions(for: site, with: indexPath) else { return nil }

        let contextMenu = PhotonActionSheet(site: site, actions: actions)
        contextMenu.modalPresentationStyle = .overFullScreen
        contextMenu.modalTransitionStyle = .crossDissolve

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        return contextMenu
    }

    func getDefaultContextMenuActions(for site: Site, homePanelDelegate: HomePanelDelegate?) -> [PhotonActionSheetItem]? {
        guard let siteURL = URL(string: site.url) else { return nil }

        let openInNewTabAction = PhotonActionSheetItem(title: .OpenInNewTabContextMenuTitle, iconString: "quick_action_new_tab") { _, _ in
            homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: false)
        }

        let openInNewPrivateTabAction = PhotonActionSheetItem(title: .OpenInNewPrivateTabContextMenuTitle, iconString: "quick_action_new_private_tab") { _, _ in
            homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
        }

        return [openInNewTabAction, openInNewPrivateTabAction]
    }
}

// MARK: - HomeVC

class FirefoxHomeViewController: UICollectionViewController, HomePanel, FeatureFlagsProtocol {
    typealias a11y = AccessibilityIdentifiers.FirefoxHomepage

    weak var homePanelDelegate: HomePanelDelegate?
    weak var libraryPanelDelegate: LibraryPanelDelegate?
    fileprivate var hasPresentedContextualHint = false
    fileprivate var didRotate = false
    fileprivate let profile: Profile
    fileprivate let flowLayout = UICollectionViewFlowLayout()
    fileprivate let experiments: NimbusApi
    fileprivate var hasSentJumpBackInSectionEvent = false
    fileprivate var hasSentHistoryHighlightsSectionEvent = false
    fileprivate var timer: Timer?
    fileprivate var contextualSourceView = UIView()
    fileprivate var isZeroSearch: Bool
    var recentlySavedViewModel: FirefoxHomeRecentlySavedViewModel
    var jumpBackInViewModel: FirefoxHomeJumpBackInViewModel
    var historyHighlightsViewModel: FxHomeHistoryHightlightsVM
    var pocketViewModel: FxHomePocketViewModel

    fileprivate lazy var topSitesManager: ASHorizontalScrollCellManager = {
        let manager = ASHorizontalScrollCellManager()
        return manager
    }()

    var contextualHintViewController = ContextualHintViewController(hintType: .jumpBackIn)

    lazy var overlayView: UIView = .build { [weak self] overlayView in
        overlayView.backgroundColor = UIColor.Photon.Grey90A10
        overlayView.isHidden = true
    }

    fileprivate lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    private var tapGestureRecognizer: UITapGestureRecognizer {
        let dismissOverlay = UITapGestureRecognizer(target: self, action: #selector(dismissOverlayMode))
        dismissOverlay.name = FxHomeDevStrings.GestureRecognizers.dismissOverlay
        dismissOverlay.cancelsTouchesInView = false
        return dismissOverlay
    }

    // Not used for displaying. Only used for calculating layout.
    lazy var topSiteCell: ASHorizontalScrollCell = {
        let customCell = ASHorizontalScrollCell(frame: CGRect(width: self.view.frame.size.width, height: 0))
        customCell.delegate = self.topSitesManager
        return customCell
    }()

    lazy var defaultBrowserCard: DefaultBrowserCard = .build { card in
        card.backgroundColor = UIColor.theme.homePanel.topSitesBackground
    }

    var currentTab: Tab? {
        let tabManager = BrowserViewController.foregroundBVC().tabManager
        return tabManager.selectedTab
    }

    lazy var homescreen = experiments.withVariables(featureId: .homescreen, sendExposureEvent: false) {
        Homescreen(variables: $0)
    }

    // MARK: - Section availability variables
    var shouldShowFxLogoHeader: Bool {
        return featureFlags.isFeatureActiveForBuild(.customWallpaper)
    }

    var isTopSitesSectionEnabled: Bool {
        homescreen.sectionsEnabled[.topSites] == true
    }

    var isYourLibrarySectionEnabled: Bool {
        UIDevice.current.userInterfaceIdiom != .pad &&
            homescreen.sectionsEnabled[.libraryShortcuts] == true
    }

    var isJumpBackInSectionEnabled: Bool {
        guard featureFlags.isFeatureActiveForBuild(.jumpBackIn),
              homescreen.sectionsEnabled[.jumpBackIn] == true,
              featureFlags.userPreferenceFor(.jumpBackIn) == UserFeaturePreference.enabled
        else { return false }

        let tabManager = BrowserViewController.foregroundBVC().tabManager
        return !(tabManager.selectedTab?.isPrivate ?? false)
            && !tabManager.recentlyAccessedNormalTabs.isEmpty
    }

    var shouldShowJumpBackInSection: Bool {
        guard isJumpBackInSectionEnabled else { return false }
        return jumpBackInViewModel.jumpBackInList.itemsToDisplay != 0
    }

    var isRecentlySavedSectionEnabled: Bool {
        return featureFlags.isFeatureActiveForBuild(.recentlySaved)
        && homescreen.sectionsEnabled[.recentlySaved] == true
        && featureFlags.userPreferenceFor(.recentlySaved) == UserFeaturePreference.enabled
    }

    // Recently saved section can be enabled but not shown if it has no data - Data is loaded asynchronously
    var shouldShowRecentlySavedSection: Bool {
        guard isRecentlySavedSectionEnabled else { return false }
        return recentlySavedViewModel.hasData
    }

    var isHistoryHightlightsSectionEnabled: Bool {
        get {
            guard featureFlags.isFeatureActiveForBuild(.historyHighlights),
                  featureFlags.userPreferenceFor(.historyHighlights) == UserFeaturePreference.enabled
            else { return false }
            let tabManager = BrowserViewController.foregroundBVC().tabManager

            return !tabManager.recentlyAccessedNormalTabs.isEmpty
        }
    }

    var isPocketSectionEnabled: Bool {
        // For Pocket, the user preference check returns a user preference if it exists in
        // UserDefaults, and, if it does not, it will return a default preference based on
        // a (nimbus pocket section enabled && Pocket.isLocaleSupported) check
        guard featureFlags.isFeatureActiveForBuild(.pocket),
              featureFlags.userPreferenceFor(.pocket) == UserFeaturePreference.enabled
        else { return false }

        return true
    }

    var shouldShowPocketSection: Bool {
        guard isPocketSectionEnabled else { return false }
        return pocketViewModel.hasData
    }

    // MARK: - Initializers
    init(profile: Profile, isZeroSearch: Bool = false, experiments: NimbusApi = Experiments.shared) {
        self.profile = profile
        self.isZeroSearch = isZeroSearch

        self.jumpBackInViewModel = FirefoxHomeJumpBackInViewModel(isZeroSearch: isZeroSearch, profile: profile)
        self.recentlySavedViewModel = FirefoxHomeRecentlySavedViewModel(isZeroSearch: isZeroSearch, profile: profile)
        self.historyHighlightsViewModel = FxHomeHistoryHightlightsVM()
        self.pocketViewModel = FxHomePocketViewModel(profile: profile, isZeroSearch: isZeroSearch)
        self.experiments = experiments
        super.init(collectionViewLayout: flowLayout)

        pocketViewModel.onTapTileAction = { [weak self] url in
            self?.showSiteWithURLHandler(url)
        }

        pocketViewModel.onLongPressTileAction = { [weak self] indexPath in
            self?.presentContextMenu(for: indexPath)
        }

        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        collectionView?.addGestureRecognizer(longPressRecognizer)
        currentTab?.lastKnownUrl?.absoluteString.hasPrefix("internal://") ?? false ? collectionView?.addGestureRecognizer(tapGestureRecognizer) : nil

        // TODO: .TabClosed notif should be in JumpBackIn view only to reload it's data, but can't right now since doesn't self-size
        let refreshEvents: [Notification.Name] = [.DynamicFontChanged, .HomePanelPrefsChanged, .DisplayThemeChanged, .TabClosed]
        refreshEvents.forEach { NotificationCenter.default.addObserver(self, selector: #selector(reload), name: $0, object: nil) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        Section.allCases.forEach {
            collectionView.register($0.cellType, forCellWithReuseIdentifier: $0.cellIdentifier)
        }
        collectionView?.register(ASHeaderView.self,
                                 forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                 withReuseIdentifier: "Header")
        collectionView?.keyboardDismissMode = .onDrag
        collectionView?.backgroundColor = .clear
        view.addSubviews(overlayView)
        view.addSubview(contextualSourceView)
        contextualSourceView.backgroundColor = .clear

        if #available(iOS 14.0, *), !UserDefaults.standard.bool(forKey: "DidDismissDefaultBrowserCard") {
            self.view.addSubview(defaultBrowserCard)
            NSLayoutConstraint.activate([
                defaultBrowserCard.topAnchor.constraint(equalTo: view.topAnchor),
                defaultBrowserCard.bottomAnchor.constraint(equalTo: collectionView.topAnchor),
                defaultBrowserCard.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                defaultBrowserCard.widthAnchor.constraint(equalToConstant: 380),

                collectionView.topAnchor.constraint(equalTo: defaultBrowserCard.bottomAnchor),
                collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])

            defaultBrowserCard.dismissClosure = {
                self.dismissDefaultBrowserCard()
            }
        }

        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        profile.panelDataObservers.activityStream.delegate = self

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
        experiments.recordExposureEvent(featureId: .homescreen)
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .firefoxHomepage,
                                     value: .fxHomepageOrigin,
                                     extras: TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch))

        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer?.invalidate()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: {context in
            // The AS context menu does not behave correctly. Dismiss it when rotating.
            if let _ = self.presentedViewController as? PhotonActionSheet {
                self.presentedViewController?.dismiss(animated: true, completion: nil)
            }
            self.collectionViewLayout.invalidateLayout()
            self.collectionView?.reloadData()
        }, completion: { _ in
            if !self.didRotate { self.didRotate = true }
            // Workaround: label positions are not correct without additional reload
            self.collectionView?.reloadData()
        })
    }

    // MARK: - Helpers
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.topSitesManager.currentTraits = self.traitCollection
        applyTheme()
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

    @objc func reload(notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged, .DynamicFontChanged:
            reloadAll(shouldUpdateData: false)
        default:
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

    @objc func dismissOverlayMode() {
        BrowserViewController.foregroundBVC().urlBar.leaveOverlayMode()
        if let gestureRecognizers = collectionView.gestureRecognizers {
            for (index, gesture) in gestureRecognizers.enumerated() {
                if gesture.name == FxHomeDevStrings.GestureRecognizers.dismissOverlay {
                    collectionView.gestureRecognizers?.remove(at: index)
                }
            }
        }
    }

    func presentContextualHint() {
        overlayView.isHidden = false
        hasPresentedContextualHint = true

        let contentSize = CGSize(width: 325, height: contextualHintViewController.heightForDescriptionLabel)
        contextualHintViewController.preferredContentSize = contentSize
        contextualHintViewController.modalPresentationStyle = .popover

        if let popoverPresentationController = contextualHintViewController.popoverPresentationController {
            popoverPresentationController.sourceView = contextualSourceView
            popoverPresentationController.sourceRect = contextualSourceView.bounds
            popoverPresentationController.permittedArrowDirections = .down
            popoverPresentationController.delegate = self
        }

        contextualHintViewController.onViewDismissed = { [weak self] in
            self?.overlayView.isHidden = true
            self?.homePanelDelegate?.homePanelDidDismissContextualHint(type: .jumpBackIn)
        }

        contextualHintViewController.viewModel.markContextualHintPresented(profile: profile)
        homePanelDelegate?.homePanelDidPresentContextualHint(type: .jumpBackIn)
        present(contextualHintViewController, animated: true, completion: nil)
    }

    func contextualHintPresentTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1.25, target: self, selector: #selector(presentContextualOverlay), userInfo: nil, repeats: false)
    }

    @objc func presentContextualOverlay() {
        guard BrowserViewController.foregroundBVC().searchController == nil,
              presentedViewController == nil else {
                  timer?.invalidate()
                  return
        }
        presentContextualHint()
    }

    private func getHeaderSize(forSection section: Int) -> CGSize {
        let indexPath = IndexPath(row: 0, section: section)
        let headerView = self.collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader, at: indexPath)
        let size = CGSize(width: collectionView.frame.width, height: UIView.layoutFittingExpandedSize.height)

        return headerView.systemLayoutSizeFitting(size,
                                                  withHorizontalFittingPriority: .required,
                                                  verticalFittingPriority: .fittingSizeLevel)
    }
}

// MARK: -  Section Management

extension FirefoxHomeViewController {

    enum Section: Int, CaseIterable {
        case logoHeader
        case topSites
        case libraryShortcuts
        case jumpBackIn
        case recentlySaved
        case historyHighlights
        case pocket
        case customizeHome

        var title: String? {
            switch self {
            case .pocket: return .ASPocketTitle2
            case .jumpBackIn: return .FirefoxHomeJumpBackInSectionTitle
            case .recentlySaved: return .RecentlySavedSectionTitle
            case .topSites: return .ASShortcutsTitle
            case .libraryShortcuts: return .AppMenuLibraryTitleString
            case .historyHighlights: return .FirefoxHomepage.HistoryHighlights.Title
            default: return nil
            }
        }

        var headerImage: UIImage? {
            switch self {
            case .pocket: return UIImage.templateImageNamed("menu-pocket")
            case .topSites: return UIImage.templateImageNamed("menu-panel-TopSites")
            case .libraryShortcuts: return UIImage.templateImageNamed("menu-library")
            default : return nil
            }
        }

        var footerHeight: CGSize {
            switch self {
            case .topSites, .libraryShortcuts: return CGSize(width: 50, height: 5)
            default: return .zero
            }
        }

        func cellHeight(_ traits: UITraitCollection, width: CGFloat) -> CGFloat {
            switch self {
            case .pocket: return FirefoxHomeUX.homeHorizontalCellHeight * FxHomePocketViewModel.numberOfItemsInColumn
            case .jumpBackIn: return FirefoxHomeUX.homeHorizontalCellHeight
            case .recentlySaved: return FirefoxHomeUX.recentlySavedCellHeight
            case .historyHighlights: return FirefoxHomeUX.historyHighlightsCellHeight
            case .topSites: return 0 //calculated dynamically
            case .libraryShortcuts: return FirefoxHomeUX.libraryShortcutsHeight
            case .customizeHome: return FirefoxHomeUX.customizeHomeHeight
            case .logoHeader: return FirefoxHomeUX.logoHeaderHeight
            }
        }

        /*
         There are edge cases to handle when calculating section insets
        - An iPhone 7+ is considered regular width when in landscape
        - An iPad in 66% split view is still considered regular width
         */
        func sectionInsets(_ traits: UITraitCollection, frameWidth: CGFloat) -> CGFloat {
            var currentTraits = traits
            if (traits.horizontalSizeClass == .regular && UIScreen.main.bounds.size.width != frameWidth) || UIDevice.current.userInterfaceIdiom == .phone {
                currentTraits = UITraitCollection(horizontalSizeClass: .compact)
            }
            var insets = FirefoxHomeUX.sectionInsetsForSizeClass[currentTraits.horizontalSizeClass]
            let window = UIWindow.keyWindow
            let safeAreaInsets = window?.safeAreaInsets.left ?? 0
            insets += FirefoxHomeUX.minimumInsets + safeAreaInsets
            return insets
        }

        func cellSize(for traits: UITraitCollection, frameWidth: CGFloat) -> CGSize {
            let height = cellHeight(traits, width: frameWidth)
            let inset = sectionInsets(traits, frameWidth: frameWidth) * 2

            return CGSize(width: frameWidth - inset, height: height)
        }

        var headerView: UIView? {
            let view = ASHeaderView()
            view.title = title
            return view
        }

        var cellIdentifier: String {
            switch self {
            case .logoHeader: return FxHomeLogoHeaderCell.cellIdentifier
            case .topSites: return ASHorizontalScrollCell.cellIdentifier
            case .pocket: return FxHomePocketCollectionCell.cellIdentifier
            case .jumpBackIn: return FxHomeJumpBackInCollectionCell.cellIdentifier
            case .recentlySaved: return FxHomeRecentlySavedCollectionCell.cellIdentifier
            case .historyHighlights: return FxHomeHistoryHighlightsCollectionCell.cellIdentifier
            case .libraryShortcuts: return  ASLibraryCell.cellIdentifier
            case .customizeHome: return FxHomeCustomizeHomeView.cellIdentifier
            }
        }

        var cellType: UICollectionViewCell.Type {
            switch self {
            case .logoHeader: return FxHomeLogoHeaderCell.self
            case .topSites: return ASHorizontalScrollCell.self
            case .pocket: return FxHomePocketCollectionCell.self
            case .jumpBackIn: return FxHomeJumpBackInCollectionCell.self
            case .recentlySaved: return FxHomeRecentlySavedCollectionCell.self
            case .historyHighlights: return FxHomeHistoryHighlightsCollectionCell.self
            case .libraryShortcuts: return ASLibraryCell.self
            case .customizeHome: return FxHomeCustomizeHomeView.self
            }
        }

        init(at indexPath: IndexPath) {
            self.init(rawValue: indexPath.section)!
        }

        init(_ section: Int) {
            self.init(rawValue: section)!
        }
    }
}

// MARK: -  CollectionView Delegate

extension FirefoxHomeViewController: UICollectionViewDelegateFlowLayout {

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header", for: indexPath) as! ASHeaderView
            let title = Section(indexPath.section).title
            headerView.title = title

            switch Section(indexPath.section) {
            case .pocket:
                headerView.moreButton.isHidden = true
                headerView.titleLabel.accessibilityIdentifier = a11y.SectionTitles.pocket
                return headerView

            case .jumpBackIn:
                if !hasSentJumpBackInSectionEvent
                    && shouldShowJumpBackInSection {
                    TelemetryWrapper.recordEvent(category: .action, method: .view, object: .jumpBackInImpressions, value: nil, extras: nil)
                    hasSentJumpBackInSectionEvent = true
                }
                headerView.moreButton.isHidden = false
                headerView.moreButton.setTitle(.RecentlySavedShowAllText, for: .normal)
                headerView.moreButton.addTarget(self, action: #selector(openTabTray), for: .touchUpInside)
                headerView.moreButton.accessibilityIdentifier = a11y.MoreButtons.jumpBackIn
                headerView.titleLabel.accessibilityIdentifier = a11y.SectionTitles.jumpBackIn
                let attributes = collectionView.layoutAttributesForItem(at: indexPath)
                    if let frame = attributes?.frame, headerView.convert(frame, from: collectionView).height > 1 {
                        // Using a timer for the first presentation of contextual hint due to many reloads that happen on the collection view. Invalidating the timer prevents from showing contextual hint at the wrong position.
                        timer?.invalidate()
                        if didRotate && hasPresentedContextualHint {
                            contextualSourceView = headerView.titleLabel
                            didRotate = false
                        } else if !hasPresentedContextualHint && contextualHintViewController.viewModel.shouldPresentContextualHint(profile: profile) {
                            contextualSourceView = headerView.titleLabel
                            contextualHintPresentTimer()
                        }
                }
                return headerView
            case .recentlySaved:
                headerView.moreButton.isHidden = false
                headerView.moreButton.setTitle(.RecentlySavedShowAllText, for: .normal)
                headerView.moreButton.addTarget(self, action: #selector(openBookmarks), for: .touchUpInside)
                headerView.moreButton.accessibilityIdentifier = a11y.MoreButtons.recentlySaved
                headerView.titleLabel.accessibilityIdentifier = a11y.SectionTitles.recentlySaved
                return headerView

            case .historyHighlights:
                if !hasSentHistoryHighlightsSectionEvent
                    && isHistoryHightlightsSectionEnabled
                    && !historyHighlightsViewModel.historyItems.isEmpty {
                    TelemetryWrapper.recordEvent(category: .action,
                                                 method: .view,
                                                 object: .historyImpressions,
                                                 value: nil,
                                                 extras: nil)
                    hasSentHistoryHighlightsSectionEvent = true
                }

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
        var cellSize = Section(indexPath.section).cellSize(for: self.traitCollection, frameWidth: self.view.frame.width)

        switch Section(indexPath.section) {
        case .topSites:
            // Create a temporary cell so we can calculate the height.
            let layout = topSiteCell.collectionView.collectionViewLayout as! HorizontalFlowLayout
            let estimatedLayout = layout.calculateLayout(for: CGSize(width: cellSize.width, height: 0))
            return CGSize(width: cellSize.width, height: estimatedLayout.size.height)

        case .jumpBackIn:
            cellSize.height *= CGFloat(jumpBackInViewModel.numberOfItemsInColumn)
            return cellSize

        case .libraryShortcuts:
            let width = min(FirefoxHomeUX.libraryShortcutsMaxWidth, cellSize.width)
            return CGSize(width: width, height: cellSize.height)

        case .historyHighlights:
            // Returns the total height based on a variable column/row layout
            let itemCount = historyHighlightsViewModel.historyItems.count
            for number in 1...HistoryHighlightsCollectionCellConstants.maxNumberOfItemsPerColumn {
                if itemCount >= HistoryHighlightsCollectionCellConstants.maxNumberOfItemsPerColumn {
                    cellSize.height *= CGFloat(HistoryHighlightsCollectionCellConstants.maxNumberOfItemsPerColumn)
                    break
                }

                if itemCount == number {
                    cellSize.height *= CGFloat(number)
                    break
                }
            }

            return cellSize

        default:
            return cellSize
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        switch Section(section) {
        case .pocket:
            return shouldShowPocketSection ? getHeaderSize(forSection: section) : .zero
        case .topSites:
            // Only show a header for top sites if the Firefox Browser logo is not showing
            if isTopSitesSectionEnabled {
                return shouldShowFxLogoHeader ? .zero : getHeaderSize(forSection: section)
            }

            return .zero
        case .libraryShortcuts:
            return isYourLibrarySectionEnabled ? getHeaderSize(forSection: section) : .zero
        case .jumpBackIn:
            return shouldShowJumpBackInSection ? getHeaderSize(forSection: section) : .zero
        case .historyHighlights:
            return isHistoryHightlightsSectionEnabled ? getHeaderSize(forSection: section) : .zero
        case .recentlySaved:
            return shouldShowRecentlySavedSection ? getHeaderSize(forSection: section) : .zero
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
        let insets = Section(section).sectionInsets(self.traitCollection, frameWidth: self.view.frame.width)
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
        return Section.allCases.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch Section(section) {
        case .logoHeader:
            return shouldShowFxLogoHeader ? 1 : 0
        case .topSites:
            return isTopSitesSectionEnabled && !topSitesManager.content.isEmpty ? 1 : 0
        case .pocket:
            return shouldShowPocketSection ? 1 : 0
        case .jumpBackIn:
            return shouldShowJumpBackInSection ? 1 : 0
        case .recentlySaved:
            return shouldShowRecentlySavedSection ? 1 : 0
        case .historyHighlights:
            return isHistoryHightlightsSectionEnabled ? 1 : 0
        case .libraryShortcuts:
            return isYourLibrarySectionEnabled ? 1 : 0
        case .customizeHome:
            return 1
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = Section(indexPath.section).cellIdentifier
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)

        switch Section(indexPath.section) {
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
        tap.numberOfTapsRequired = 2
        logoHeaderCell.logoButton.addGestureRecognizer(tap)
        logoHeaderCell.setNeedsLayout()
        return logoHeaderCell
    }

    func configureTopSitesCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        guard let topSiteCell = cell as? ASHorizontalScrollCell else { return UICollectionViewCell() }
        topSiteCell.delegate = self.topSitesManager
        topSiteCell.setNeedsLayout()
        topSiteCell.collectionView.reloadData()
        return cell
    }

    private func configurePocketItemCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        guard let pocketCell = cell as? FxHomePocketCollectionCell else { return UICollectionViewCell() }
        pocketCell.viewModel = pocketViewModel
        pocketCell.viewModel?.pocketShownInSection = indexPath.section
        pocketCell.reloadLayout()
        pocketCell.setNeedsLayout()

        pocketViewModel.recordSectionHasShown()

        return pocketCell
    }

    private func configureRecentlySavedCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        guard let recentlySavedCell = cell as? FxHomeRecentlySavedCollectionCell else { return UICollectionViewCell() }
        recentlySavedCell.viewModel = recentlySavedViewModel
        recentlySavedCell.homePanelDelegate = homePanelDelegate
        recentlySavedCell.libraryPanelDelegate = libraryPanelDelegate
        recentlySavedCell.collectionView.reloadData()
        recentlySavedCell.setNeedsLayout()

        return recentlySavedCell
    }

    private func configureJumpBackInCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        guard let jumpBackInCell = cell as? FxHomeJumpBackInCollectionCell else { return UICollectionViewCell() }
        jumpBackInCell.viewModel = jumpBackInViewModel

        jumpBackInViewModel.onTapGroup = { [weak self] tab in
            self?.homePanelDelegate?.homePanelDidRequestToOpenTabTray(withFocusedTab: tab)
        }
        jumpBackInCell.reloadLayout()
        jumpBackInCell.setNeedsLayout()

        return jumpBackInCell
    }

    private func configureHistoryHighlightsCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        guard let historyCell = cell as? FxHomeHistoryHighlightsCollectionCell else { return UICollectionViewCell() }
        historyHighlightsViewModel.onTapItem = { [weak self] in
            // TODO: When the data is hooked up, this will actually send a user to
            // the correct place in history
            self?.openHistory(UIButton())
        }

        historyCell.viewModel = historyHighlightsViewModel
        historyHighlightsViewModel.updateData()
        historyCell.collectionView.reloadData()
        historyCell.setNeedsLayout()

        return historyCell
    }

    private func configureCustomizeHomeCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        guard let customizeHomeCell = cell as? FxHomeCustomizeHomeView else { return UICollectionViewCell() }
        customizeHomeCell.goToSettingsButton.addTarget(self, action: #selector(openCustomizeHomeSettings), for: .touchUpInside)
        customizeHomeCell.setNeedsLayout()

        return customizeHomeCell
    }
}

// MARK: - Data Management

extension FirefoxHomeViewController: DataObserverDelegate {

    /// Reload all data including refreshing cells content and fetching data from backend
    /// - Parameter shouldUpdateData: True means backend data should be refetched
    func reloadAll(shouldUpdateData: Bool = true) {
        // Overlay view is used by contextual hint and reloading the view while the hint is shown can cause the popover to flicker
        guard overlayView.isHidden else { return }

        loadTopSitesData()

        guard shouldUpdateData else { return }
        DispatchQueue.global(qos: .userInteractive).async {
            self.reloadSectionsData()
        }
    }

    private func reloadSectionsData() {
        // TODO: Reload with a protocol comformance once all sections are standardized
        // Idea is that each section will load it's data from it's own view model
        if isRecentlySavedSectionEnabled {
            recentlySavedViewModel.updateData {}
        }

        // Jump back in access tabManager and this needs to be done on the main thread at the moment
        DispatchQueue.main.async {
            if self.isJumpBackInSectionEnabled {
                self.jumpBackInViewModel.updateData {}
            }
        }

        if isPocketSectionEnabled {
            pocketViewModel.updateData {
                // TODO: Once section are standardized, reload only the pocket section when data is updated
                self.collectionView.reloadData()
            }
        }
    }

    // Reloads both highlights and top sites data from their respective caches. Does not invalidate the cache.
    // See ActivityStreamDataObserver for invalidation logic.
    private func loadTopSitesData() {
        TopSitesHandler.getTopSites(profile: profile).uponQueue(.main) { [weak self] result in
            guard let self = self else { return }

            // If there is no pending cache update and highlights are empty. Show the onboarding screen
            self.collectionView?.reloadData()

            self.topSitesManager.currentTraits = self.view.traitCollection

            let numRows = max(self.profile.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows) ?? TopSitesRowCountSettingsController.defaultNumberOfRows, 1)

            let maxItems = Int(numRows) * self.topSitesManager.numberOfHorizontalItems()

            var sites = Array(result.prefix(maxItems))

            // Check if all result items are pinned site
            var pinnedSites = 0
            result.forEach {
                if let _ = $0 as? PinnedSite {
                    pinnedSites += 1
                }
            }
            // Special case: Adding Google topsite
            let googleTopSite = GoogleTopSiteHelper(prefs: self.profile.prefs)
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
            self.topSitesManager.content = sites
            self.topSitesManager.urlPressedHandler = { [unowned self] site, indexPath in
                self.longPressRecognizer.isEnabled = false
                guard let url = site.url.asURL else { return }
                let isGoogleTopSiteUrl = url.absoluteString == GoogleTopSiteConstants.usUrl || url.absoluteString == GoogleTopSiteConstants.rowUrl
                self.topSiteTracking(site: site, position: indexPath.item)
                self.showSiteWithURLHandler(url as URL, isGoogleTopSite: isGoogleTopSiteUrl)
            }

            // Refresh the AS data in the background so we'll have fresh data next time we show.
            self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: false)
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
        profile.history.removeHostFromTopSites(host).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: true)
        }
    }

    func pinTopSite(_ site: Site) {
        profile.history.addPinnedTopSite(site).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: true)
        }
    }

    func removePinTopSite(_ site: Site) {
        // Special Case: Hide google top site
        if site.guid == GoogleTopSiteConstants.googleGUID {
            let gTopSite = GoogleTopSiteHelper(prefs: self.profile.prefs)
            gTopSite.isHidden = true
        }

        profile.history.removeFromPinnedTopSites(site).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: true)
        }
    }

    fileprivate func deleteTileForSuggestedSite(_ siteURL: String) {
        var deletedSuggestedSites = profile.prefs.arrayForKey(TopSitesHandler.DefaultSuggestedSitesKey) as? [String] ?? []
        deletedSuggestedSites.append(siteURL)
        profile.prefs.setObject(deletedSuggestedSites, forKey: TopSitesHandler.DefaultSuggestedSitesKey)
    }

    func defaultTopSites() -> [Site] {
        let suggested = SuggestedSites.asArray()
        let deleted = profile.prefs.arrayForKey(TopSitesHandler.DefaultSuggestedSitesKey) as? [String] ?? []
        return suggested.filter({ deleted.firstIndex(of: $0.url) == .none })
    }

    @objc fileprivate func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }

        let point = longPressGestureRecognizer.location(in: self.collectionView)
        guard let fxHomeIndexPath = self.collectionView?.indexPathForItem(at: point) else { return }

        // Here, we must be careful which `section` we're passing in, as it can be the
        // homescreen's section, or a sub-view's section, thereby requiring a custom
        // `IndexPath` object to be created and passed around.
        switch Section(fxHomeIndexPath.section) {
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
        profile.places.isBookmarked(url: site.url).uponQueue(.main) { result in
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
        homePanelDelegate?.homePanelDidRequestToCustomizeHomeSettings()
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .firefoxHomepage,
                                     value: .customizeHomepageButton)
    }

    @objc func changeHomepageWallpaper() {
        // TODO: Roux - This function will be implemented with the action when wallpaper feature is
        // added in the next ticket.

        // Telemetry is commented out until button action is activated.
//        TelemetryWrapper.recordEvent(category: .action,
//                                     method: .tap,
//                                     object: .firefoxHomepage,
//                                     value: .cycleWallpaperButton)
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
        switch Section(indexPath.section) {
        case .pocket:
            return pocketViewModel.getSitesDetail(for: indexPath.row)
        case .topSites:
            return topSitesManager.content[indexPath.item]
        default:
            return nil
        }
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonActionSheetItem]? {
        guard let siteURL = URL(string: site.url) else { return nil }
        var sourceView: UIView?

        switch Section(indexPath.section) {
        case .topSites:
            if let topSiteCell = self.collectionView?.cellForItem(at: IndexPath(row: 0, section: 0)) as? ASHorizontalScrollCell {
                sourceView = topSiteCell.collectionView.cellForItem(at: indexPath)
            }
        case .pocket:
            sourceView = self.collectionView?.cellForItem(at: indexPath)
        default:
            return nil
        }

        let openInNewTabAction = PhotonActionSheetItem(title: .OpenInNewTabContextMenuTitle, iconString: "quick_action_new_tab") { [weak self] _, _ in
            self?.homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: false)
            if Section(indexPath.section) == .pocket, let isZeroSearch = self?.isZeroSearch {
                let originExtras = TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch)
                TelemetryWrapper.recordEvent(category: .action,
                                             method: .tap,
                                             object: .pocketStory,
                                             extras: originExtras)
            }
        }

        let openInNewPrivateTabAction = PhotonActionSheetItem(title: .OpenInNewPrivateTabContextMenuTitle, iconString: "quick_action_new_private_tab") { _, _ in
            self.homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
        }

        let bookmarkAction: PhotonActionSheetItem
        if site.bookmarked ?? false {
            bookmarkAction = PhotonActionSheetItem(title: .RemoveBookmarkContextMenuTitle, iconString: "action_bookmark_remove", handler: { _, _ in
                self.profile.places.deleteBookmarksWithURL(url: site.url) >>== {
                    self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: false)
                    site.setBookmarked(false)
                }

                TelemetryWrapper.recordEvent(category: .action, method: .delete, object: .bookmark, value: .activityStream)
            })
        } else {
            bookmarkAction = PhotonActionSheetItem(title: .BookmarkContextMenuTitle, iconString: "action_bookmark", handler: { _, _ in
                let shareItem = ShareItem(url: site.url, title: site.title, favicon: site.icon)
                _ = self.profile.places.createBookmark(parentGUID: BookmarkRoots.MobileFolderGUID, url: shareItem.url, title: shareItem.title)

                var userData = [QuickActions.TabURLKey: shareItem.url]
                if let title = shareItem.title {
                    userData[QuickActions.TabTitleKey] = title
                }
                QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(.openLastBookmark,
                                                                                    withUserData: userData,
                                                                                    toApplication: .shared)
                site.setBookmarked(true)
                self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: true)
                TelemetryWrapper.recordEvent(category: .action, method: .add, object: .bookmark, value: .activityStream)
            })
        }

        let shareAction = PhotonActionSheetItem(title: .ShareContextMenuTitle, iconString: "action_share", handler: { _, _ in
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
            self.present(controller, animated: true, completion: nil)
        })

        let removeTopSiteAction = PhotonActionSheetItem(title: .RemoveContextMenuTitle, iconString: "action_remove", handler: { _, _ in
            self.hideURLFromTopSites(site)
        })

        let pinTopSite = PhotonActionSheetItem(title: .AddToShortcutsActionTitle, iconString: "action_pin", handler: { _, _ in
            self.pinTopSite(site)
        })

        let removePinTopSite = PhotonActionSheetItem(title: .RemoveFromShortcutsActionTitle, iconString: "action_unpin", handler: { _, _ in
            self.removePinTopSite(site)
        })

        let topSiteActions: [PhotonActionSheetItem]
        if let _ = site as? PinnedSite {
            topSiteActions = [removePinTopSite]
        } else {
            topSiteActions = [pinTopSite, removeTopSiteAction]
        }

        var actions = [openInNewTabAction, openInNewPrivateTabAction, bookmarkAction, shareAction]

        switch Section(indexPath.section) {
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
        guard hasPresentedContextualHint else {
            popoverPresentationController.presentedViewController.dismiss(animated: false, completion: nil)
            return
        }
        rect.pointee = contextualSourceView.bounds
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        contextualHintViewController.removeFromParent()
        hasPresentedContextualHint = false
        overlayView.isHidden = true
        return true
    }
}
