/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import UIKit
import Storage
import SDWebImage
import XCGLogger
import SyncTelemetry
import Core

private let log = Logger.browserLogger

// MARK: -  UX

struct FirefoxHomeUX {
    static let highlightCellHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 250 : 200
    static let sectionInsetsForSizeClass = UXSizeClasses(compact: 0, regular: 101, other: 16)
    static let numberOfItemsPerRowForSizeClassIpad = UXSizeClasses(compact: 4, regular: 6, other: 2)
    static let spacingBetweenSections: CGFloat = 24
    static let SectionInsetsForIpad: CGFloat = 101
    static let MinimumInsets: CGFloat = 16
    static let LibraryShortcutsHeight: CGFloat = 100
    static let LibraryShortcutsMaxWidth: CGFloat = 350
    static let SearchBarHeight: CGFloat = 60
    static let TopSitesInsets: CGFloat = 6
    static let customizeHomeHeight: CGFloat = 100
    static var ScrollSearchBarOffset: CGFloat {
        (UIDevice.current.userInterfaceIdiom == .phone) ? SearchBarHeight : 0
    }
    static var ToolbarHeight: CGFloat {
        (UIDevice.current.userInterfaceIdiom == .phone && UIDevice.current.orientation.isPortrait) ? 46 : 0
    }
}

struct FxHomeAccessibilityIdentifiers {
    struct MoreButtons {
        static let recentlySaved = "recentlySavedSectionMoreButton"
        static let jumpBackIn = "jumpBackInSectionMoreButton"
    }
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
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool)
    func homePanel(didSelectURL url: URL, visitType: VisitType, isGoogleTopSite: Bool)
    func homePanelDidRequestToOpenLibrary(panel: LibraryPanelType)
    func homePanelDidRequestToOpenTabTray(withFocusedTab tabToFocus: Tab?)
    func homePanelDidRequestToCustomizeHomeSettings()
    func homePanelDidPresentContextualHint(type: ContextualHintViewType)
    func homePanelDidDismissContextualHint(type: ContextualHintViewType)
}

protocol HomePanel: Themeable {
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

        let openInNewTabAction = PhotonActionSheetItem(title: Strings.OpenInNewTabContextMenuTitle, iconString: "quick_action_new_tab") { _, _ in
            homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: false)
        }

        let openInNewPrivateTabAction = PhotonActionSheetItem(title: Strings.OpenInNewPrivateTabContextMenuTitle, iconString: "quick_action_new_private_tab") { _, _ in
            homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
        }

        return [openInNewTabAction, openInNewPrivateTabAction]
    }
}

protocol FirefoxHomeViewControllerDelegate: AnyObject {
    func home(_ home: FirefoxHomeViewController, didScroll contentOffset: CGFloat, offset: CGFloat)
    func homeDidTapSearchButton(_ home: FirefoxHomeViewController)
    func home(_ home: FirefoxHomeViewController, willBegin drag: CGPoint)
    func homeDidPressPersonalCounter(_ home: FirefoxHomeViewController, completion: (() -> Void)?)
}

// MARK: - HomeVC

class FirefoxHomeViewController: UICollectionViewController, HomePanel, FeatureFlagsProtocol {
    weak var homePanelDelegate: HomePanelDelegate?
    weak var libraryPanelDelegate: LibraryPanelDelegate?
    weak var delegate: FirefoxHomeViewControllerDelegate?
    fileprivate var hasPresentedContextualHint = false
    fileprivate var didRoate = false
    fileprivate let profile: Profile
    fileprivate let personalCounter = PersonalCounter()
    fileprivate weak var referrals: Referrals!
    fileprivate let flowLayout = NTPLayout()
    fileprivate weak var searchbarCell: UICollectionViewCell?
    fileprivate weak var emptyCell: EmptyCell?
    fileprivate weak var impactCell: TreesCell?
    fileprivate var timer: Timer?
    fileprivate var contextualSourceView = UIView()
    var recentlySavedViewModel = FirefoxHomeRecentlySavedViewModel()
    var jumpBackInViewModel = FirefoxHomeJumpBackInViewModel()
    fileprivate var hasSentJumpBackInSectionEvent = false
    // Ecosia: fileprivate let pocketAPI = Pocket()
    // Ecosia: fileprivate let experiments: NimbusApi
    // Ecosia: fileprivate var hasSentPocketSectionEvent = false

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
    var hasRecentBookmarks = false
    var hasReadingListitems = false
    var currentTab: Tab? {
        let tabManager = BrowserViewController.foregroundBVC().tabManager
        return tabManager.selectedTab
    }

    /* Ecosia: remove experiments
    lazy var homescreen = experiments.withVariables(featureId: .homescreen, sendExposureEvent: false) {
        Homescreen(variables: $0)
    }

    // MARK: - Section availability variables
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

    var isRecentlySavedSectionEnabled: Bool {
        guard featureFlags.isFeatureActiveForBuild(.recentlySaved),
              homescreen.sectionsEnabled[.recentlySaved] == true,
              featureFlags.userPreferenceFor(.recentlySaved) == UserFeaturePreference.enabled
        else { return false }

        return hasRecentBookmarks || hasReadingListitems
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
    */

    // MARK: - Initializers
    init(profile: Profile, delegate: FirefoxHomeViewControllerDelegate?, referrals: Referrals) {
        self.profile = profile
        self.delegate = delegate
        self.referrals = referrals
        super.init(collectionViewLayout: flowLayout)
        flowLayout.highlightDataSource = self
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self
        self.collectionView?.alwaysBounceVertical = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        collectionView?.addGestureRecognizer(longPressRecognizer)
        currentTab?.lastKnownUrl?.absoluteString.hasPrefix("internal://") ?? false ? collectionView?.addGestureRecognizer(tapGestureRecognizer) : nil

        let refreshEvents: [Notification.Name] = [.DynamicFontChanged, .HomePanelPrefsChanged, .DisplayThemeChanged]
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

        Section.allCases.forEach { collectionView.register($0.cellType, forCellWithReuseIdentifier: $0.cellIdentifier) }
        self.collectionView?.register(ASHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        self.collectionView?.register(NTPTooltip.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NTPTooltip.key)
        collectionView?.keyboardDismissMode = .onDrag
        (collectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.estimatedItemSize = UICollectionViewFlowLayout.automaticSize

        self.view.addSubviews(overlayView)
        self.view.addSubview(contextualSourceView)
        contextualSourceView.backgroundColor = .clear
        collectionView?.backgroundColor = .clear
        
		/* Ecosia: Deactivate MOZ Promo
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
        */
		
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        self.view.backgroundColor = UIColor.theme.ecosia.primaryBackground
        self.profile.panelDataObservers.activityStream.delegate = self

        applyTheme()

        personalCounter.subscribe(self) { [weak self] _ in
            guard let self = self else { return }
            self.updateTreesCell()
        }

        referrals.subscribe(self) { [weak self] _ in
            guard let self = self else { return }
            self.updateTreesCell()
        }
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadAll()

        if Referrals.isEnabled {
            referrals.refresh()
        }

        if User.shared.showsReferralSpotlight {
            Analytics.shared.showInvitePromo()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if inOverlayMode, let cell = searchbarCell {
            collectionView.contentOffset = .init(x: 0, y: cell.frame.maxY - FirefoxHomeUX.ScrollSearchBarOffset)
        } else {
            self.flowLayout.invalidateLayout()
        }
	}
	
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer?.invalidate()
        User.shared.hideRebrandIntro()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: {context in
            //The AS context menu does not behave correctly. Dismiss it when rotating.
            if let _ = self.presentedViewController as? PhotonActionSheet {
                self.presentedViewController?.dismiss(animated: true, completion: nil)
            }
            self.flowLayout.invalidateLayout()
            self.collectionView?.reloadData()
        }, completion: { _ in
            if !self.didRoate { self.didRoate = true }
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

    /* Ecosia: deactivate MOZ default browser card
    public func dismissDefaultBrowserCard() {
        self.defaultBrowserCard.removeFromSuperview()
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    */

    @objc func reload(notification: Notification) {
        reloadAll()
    }

    func applyTheme() {
        collectionView?.backgroundColor = .theme.ecosia.ntpBackground
        self.view.backgroundColor = .theme.ecosia.ntpBackground
        collectionView.visibleCells.forEach({
            ($0 as? Themeable)?.applyTheme()
        })
    }

    func scrollToTop(animated: Bool = false) {
        collectionView?.setContentOffset(.zero, animated: animated)
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        currentTab?.lastKnownUrl?.absoluteString.hasPrefix("internal://") ?? false ? BrowserViewController.foregroundBVC().urlBar.leaveOverlayMode() : nil

        // Ecosia: leave overlay mode
        let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView.superview)
        delegate?.home(self, willBegin: velocity)
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
    
	var inOverlayMode = false {
        didSet {
            guard isViewLoaded else { return }
            if inOverlayMode && !oldValue, let cell = searchbarCell {
                UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState], animations: { [weak self] in
                    self?.collectionView.setContentOffset(.init(x: 0, y: cell.frame.maxY - FirefoxHomeUX.ScrollSearchBarOffset), animated: true)
                })
            } else if oldValue && !inOverlayMode && !collectionView.isDragging {
                UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState], animations: { [weak self] in
                    self?.collectionView.contentOffset = .zero
                })
            }
        }
    }

    /* Ecosia: deactivate FF promo
    private var showPromo: Bool {
        guard #available(iOS 14.0, *) else { return false }
        return !UserDefaults.standard.bool(forKey: "DidDismissDefaultBrowserCard")
    }
     */
    
    func configureItemsForRecentlySaved() {
        profile.places.getRecentBookmarks(limit: 5).uponQueue(.main) { [weak self] result in
            self?.hasRecentBookmarks = false

            if let bookmarks = result.successValue,
               !bookmarks.isEmpty,
               !RecentItemsHelper.filterStaleItems(recentItems: bookmarks, since: Date()).isEmpty {
                self?.hasRecentBookmarks = true

                TelemetryWrapper.recordEvent(category: .action,
                                             method: .view,
                                             object: .firefoxHomepage,
                                             value: .recentlySavedBookmarkItemView,
                                             extras: [TelemetryWrapper.EventObject.recentlySavedBookmarkImpressions.rawValue: bookmarks.count])
            }

            self?.collectionView.reloadData()
        }

        if let readingList = profile.readingList.getAvailableRecords().value.successValue?.prefix(RecentlySavedCollectionCellUX.readingListItemsLimit) {
            var readingListItems = Array(readingList)
            readingListItems = RecentItemsHelper.filterStaleItems(recentItems: readingListItems,
                                                                       since: Date()) as! [ReadingListItem]
            self.hasReadingListitems = !readingListItems.isEmpty

            TelemetryWrapper.recordEvent(category: .action,
                                         method: .view,
                                         object: .firefoxHomepage,
                                         value: .recentlySavedBookmarkItemView,
                                         extras: [TelemetryWrapper.EventObject.recentlySavedReadingItemImpressions.rawValue: readingListItems.count])

            self.collectionView.reloadData()
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
        presentContextualHint()
    }
}

// MARK: -  Section Management

extension FirefoxHomeViewController {

    enum Section: Int, CaseIterable {
        case logo
        case search
        case libraryShortcuts
        case topSites
        case impact
        case emptySpace

        var title: String? {
            switch self {
            case .topSites: return Strings.ASTopSitesTitle
            default: return nil
            }
        }

        var headerHeight: CGSize {
            switch self {
            case .topSites:
                return CGSize(width: 50, height: 54)
            default:
                return .zero
            }
        }

        func cellHeight(_ traits: UITraitCollection, width: CGFloat) -> CGFloat {
            switch self {
            case .impact: return .nan
            case .logo: return 100
            case .search: return UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).pointSize + 25 + 16
            case .topSites: return 0 //calculated dynamically
            case .libraryShortcuts: return FirefoxHomeUX.LibraryShortcutsHeight
            case .emptySpace:
                return .nan // will be calculated outside of enum
            }
        }

        /*
         There are edge cases to handle when calculating section insets
        - An iPhone 7+ is considered regular width when in landscape
        - An iPad in 66% split view is still considered regular width
         */
        func sectionInsets(_ traits: UITraitCollection, frameWidth: CGFloat) -> CGFloat {
            var currentTraits = traits
            if (traits.horizontalSizeClass == .regular && UIApplication.shared.statusBarOrientation.isPortrait) || UIDevice.current.userInterfaceIdiom == .phone {
                currentTraits = UITraitCollection(horizontalSizeClass: .compact)
            }
            var insets = FirefoxHomeUX.sectionInsetsForSizeClass[currentTraits.horizontalSizeClass]

            switch self {
            case .libraryShortcuts, .topSites, .search, .impact:
                let window = UIApplication.shared.keyWindow
                let safeAreaInsets = window?.safeAreaInsets.left ?? 0
                insets += FirefoxHomeUX.MinimumInsets + safeAreaInsets
                
                /* Ecosia: center layout in landscape for iPhone */
                if UIApplication.shared.statusBarOrientation.isLandscape, UIDevice.current.userInterfaceIdiom == .phone {
                    insets = frameWidth / 4
                }
                
                return insets
            case .logo:
                insets += FirefoxHomeUX.TopSitesInsets
                return insets
            case .emptySpace:
                return 0
            }
        }

        func cellSize(for traits: UITraitCollection, frameWidth: CGFloat) -> CGSize {
            let height = cellHeight(traits, width: frameWidth)
            let inset = sectionInsets(traits, frameWidth: frameWidth) * 2
            let width = maxWidth(for: traits, frameWidth: (frameWidth - inset))
            return CGSize(width: width, height: height)
        }

        func maxWidth(for traits: UITraitCollection, frameWidth: CGFloat) -> CGFloat {
            var width = frameWidth
            if traits.userInterfaceIdiom == .pad {
                let maxWidth: CGFloat = UIApplication.shared.statusBarOrientation.isPortrait ? 375 : 520
                switch self {
                case .logo, .search, .libraryShortcuts:
                    width = min(375, width)
                default:
                    width = min(520, width)
                }
            }
            return width
        }

        var headerView: UIView? {
            let view = ASHeaderView()
            view.title = title
            return view
        }

        var cellIdentifier: String {
            return "\(cellType)"
        }

        var cellType: UICollectionViewCell.Type {
            switch self {
            case .impact: return TreesCell.self
            case .logo: return LogoCell.self
            case .search: return SearchbarCell.self
            case .topSites: return ASHorizontalScrollCell.self
            case .libraryShortcuts: return ASLibraryCell.self
            case .emptySpace: return EmptyCell.self
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

        let section = Section(rawValue: indexPath.section)

        if section == .impact, let text = ntpLayoutHighlightText()  {
            let tooltip = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NTPTooltip.key, for: indexPath) as! NTPTooltip
            tooltip.setText(text)
            tooltip.delegate = self
            return tooltip
        }

        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header", for: indexPath) as! ASHeaderView
        let title = Section(indexPath.section).title
        view.title = title
        view.titleLabel.accessibilityIdentifier = "topSitesTitle"
        view.remakeConstraint(type: .normal)
        return view
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.longPressRecognizer.isEnabled = false

        switch Section(rawValue: indexPath.section) {
        case .impact:
            delegate?.homeDidPressPersonalCounter(self, completion: { [weak self] in
                self?.updateTreesCell()
            })
            collectionView.deselectItem(at: indexPath, animated: true)
            ntpTooltipTapped(nil)
            Analytics.shared.clickYourImpact(on: .ntp)
        default:
            break
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch Section(section) {
        case .topSites:
            if topSitesManager.content.isEmpty ||
                User.shared.topSites == false ||
                UIDevice.current.userInterfaceIdiom == .phone {
                return .zero
            } else {
                return Section.topSites.headerHeight
            }
        case .impact:
            // Ecosia: minimal height to trigger whether header tooltip is shown
            return ntpLayoutHighlightText() != nil ? .init(width: 200, height: 1) : .zero
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
        var insets = Section(section).sectionInsets(self.traitCollection, frameWidth: self.view.frame.width)

//        if traitCollection.userInterfaceIdiom == .pad {
//            let maxWidth = Section(section).maxWidth(for: traitCollection, frameWidth: view.frame.width)
//            insets = max(insets, (view.frame.width - maxWidth)/2.0)
//        }
        return UIEdgeInsets(top: 0, left: insets, bottom: 0, right: insets)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // only tell delegate after cell has layout ( => width != height)
        guard let searchbarCell = searchbarCell, searchbarCell.bounds.width != searchbarCell.bounds.height else { return }
        delegate?.home(self, didScroll: searchbarCell.frame.minY, offset: scrollView.contentOffset.y)
    }

    fileprivate func showSiteWithURLHandler(_ url: URL) {
        let visitType = VisitType.bookmark
        
        switch url.absoluteString {
        case Environment.current.blog.absoluteString:
            Analytics.shared.open(topSite: .blog)
        case Environment.current.financialReports.absoluteString:
            Analytics.shared.open(topSite: .financialReports)
        case Environment.current.privacy.absoluteString:
            Analytics.shared.open(topSite: .privacy)
        case Environment.current.howEcosiaWorks.absoluteString:
            Analytics.shared.open(topSite: .howEcosiaWorks)
        default:
            break
        }
        
        homePanelDelegate?.homePanel(didSelectURL: url, visitType: visitType, isGoogleTopSite: false)
    }
}

// MARK: - CollectionView Data Source

extension FirefoxHomeViewController {

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Section.allCases.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var numItems: CGFloat = FirefoxHomeUX.numberOfItemsPerRowForSizeClassIpad[self.traitCollection.horizontalSizeClass]
        if UIApplication.shared.statusBarOrientation.isPortrait {
            numItems = numItems - 1
        }
        if self.traitCollection.horizontalSizeClass == .compact && UIApplication.shared.statusBarOrientation.isLandscape {
            numItems = numItems - 1
        }

        switch Section(section) {
        case .impact, .logo, .search, .emptySpace:
            return 1
        case .libraryShortcuts:
            return 1
        case .topSites:
            return (topSitesManager.content.isEmpty || User.shared.topSites == false) ? 0 : 1
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = Section(indexPath.section).cellIdentifier
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        let cellSize = Section(indexPath.section).cellSize(for: self.traitCollection, frameWidth: collectionView.bounds.width)


        switch Section(indexPath.section) {
        case .topSites:
            let topSitesCell = configureTopSitesCell(cell, width: cellSize.width)
            return topSitesCell
        case .search:
            (cell as? SearchbarCell)?.delegate = self
            (cell as? SearchbarCell)?.widthConstraint.constant = cellSize.width
            searchbarCell = cell
            return cell
        case .emptySpace:
            let emptyCell = cell as! EmptyCell
            self.emptyCell = emptyCell
            emptyCell.widthConstraint.constant = cellSize.width
            emptyCell.heightConstraint.constant = 100
            return emptyCell
        case .logo:
            return cell
        case .impact:
            guard let impactCell = cell as? TreesCell else {return cell}
            self.impactCell = impactCell
            impactCell.display(treesCellModel)
            impactCell.widthConstraint.constant = cellSize.width
            return cell
        case .libraryShortcuts:
            let libraryCell = configureLibraryShortcutsCell(cell, forIndexPath: indexPath)
            libraryCell.widthConstraint.constant = cellSize.width
            libraryCell.heightConstraint.constant = FirefoxHomeUX.LibraryShortcutsHeight
            return libraryCell
        }
    }

    func configureLibraryShortcutsCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> ASLibraryCell {
        let libraryCell = cell as! ASLibraryCell
        let targets = [#selector(openBookmarks), #selector(openHistory), #selector(openReadingList), #selector(openDownloads)]
        libraryCell.libraryButtons.map({ $0.button }).zip(targets).forEach { (button, selector) in
            button.removeTarget(nil, action: nil, for: .allEvents)
            button.addTarget(self, action: selector, for: .touchUpInside)
        }
        libraryCell.applyTheme()
        return libraryCell
    }

    //should all be collectionview
    func configureTopSitesCell(_ cell: UICollectionViewCell, width: CGFloat) -> ASHorizontalScrollCell {
        let cell = cell as! ASHorizontalScrollCell
        cell.delegate = self.topSitesManager

        cell.widthConstraint.constant = width
        cell.setNeedsLayout()
        cell.collectionView.reloadData()

        // Create a temporary cell so we can calculate the height.
        let layout = cell.collectionView.collectionViewLayout as! HorizontalFlowLayout
        let estimatedLayout = layout.calculateLayout(for: CGSize(width: width, height: 0))

        cell.heightConstraint.constant = estimatedLayout.size.height
        return cell
    }

    private func configureRecentlySavedCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let recentlySavedCell = cell as! FxHomeRecentlySavedCollectionCell
        recentlySavedCell.homePanelDelegate = homePanelDelegate
        recentlySavedCell.libraryPanelDelegate = libraryPanelDelegate
        recentlySavedCell.profile = profile
        recentlySavedCell.collectionView.reloadData()
        recentlySavedCell.setNeedsLayout()
        recentlySavedCell.viewModel = recentlySavedViewModel

        return recentlySavedCell
    }

    private func configureJumpBackInCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let jumpBackInCell = cell as! FxHomeJumpBackInCollectionCell
        jumpBackInCell.profile = profile

        jumpBackInViewModel.onTapGroup = { [weak self] tab in
            self?.homePanelDelegate?.homePanelDidRequestToOpenTabTray(withFocusedTab: tab)
        }

        jumpBackInCell.viewModel = jumpBackInViewModel
        jumpBackInCell.collectionView.reloadData()
        jumpBackInCell.setNeedsLayout()
        
        return jumpBackInCell
    }

    private func configureCustomizeHomeCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let customizeHomeCell = cell as! FxHomeCustomizeHomeView
        customizeHomeCell.goToSettingsButton.addTarget(self, action: #selector(openCustomizeHomeSettings), for: .touchUpInside)
        customizeHomeCell.setNeedsLayout()

        return customizeHomeCell
    }
}

// MARK: - Data Management

extension FirefoxHomeViewController: DataObserverDelegate {

    // Reloads both highlights and top sites data from their respective caches. Does not invalidate the cache.
    // See ActivityStreamDataObserver for invalidation logic.
    func reloadAll() {
        // Overlay view is used by contextual hint and reloading the view while the hint is shown can cause the popover to flicker
        guard overlayView.isHidden else { return }

        // If the pocket stories are not availible for the Locale the PocketAPI will return nil
        // So it is okay if the default here is true

        self.configureItemsForRecentlySaved()

        TopSitesHandler.getTopSites(profile: profile).uponQueue(.main) { [weak self] result in
            guard let self = self else { return }

            // If there is no pending cache update and highlights are empty. Show the onboarding screen
            self.collectionView?.reloadData()

            self.topSitesManager.currentTraits = self.view.traitCollection

            let numRows = self.traitCollection.userInterfaceIdiom == .pad ? 2 : 1

            let maxItems = Int(numRows) * self.topSitesManager.numberOfHorizontalItems()

            var sites = Array(result.prefix(maxItems))

            // Check if all result items are pinned site
            var pinnedSites = 0
            result.forEach {
                if let _ = $0 as? PinnedSite {
                    pinnedSites += 1
                }
            }
            /* Ecosia: remove pinned Google topsite
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
            */
            self.topSitesManager.content = sites
            self.topSitesManager.urlPressedHandler = { [unowned self] site, indexPath in
                self.longPressRecognizer.isEnabled = false
                guard let url = site.url.asURL else { return }
                // Ecosia: let isGoogleTopSiteUrl = url.absoluteString == GoogleTopSiteConstants.usUrl || url.absoluteString == GoogleTopSiteConstants.rowUrl
                self.topSiteTracking(site: site, position: indexPath.item)
                self.showSiteWithURLHandler(url as URL)
            }

            // Refresh the AS data in the background so we'll have fresh data next time we show.
            self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: false)
        }
    }

    func topSiteTracking(site: Site, position: Int) {
        let topSitePositionKey = TelemetryWrapper.EventExtraKey.topSitePosition.rawValue
        let topSiteTileTypeKey = TelemetryWrapper.EventExtraKey.topSiteTileType.rawValue
        let isPinnedAndGoogle = site is PinnedSite && site.guid == GoogleTopSiteConstants.googleGUID
        let isPinnedOnly = site is PinnedSite
        let isSuggestedSite = site is SuggestedSite
        let type = isPinnedAndGoogle ? "google" : isPinnedOnly ? "user-added" : isSuggestedSite ? "suggested" : "history-based"
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .topSiteTile, value: nil, extras: [topSitePositionKey : "\(position)", topSiteTileTypeKey: type])
    }

    /* Ecosia: deactivate Pocket
    func getPocketSites() -> Success {

        guard isPocketSectionEnabled else {
            self.pocketStories = []
            return succeed()
        }

        return pocketAPI.globalFeed(items: 10).bindQueue(.main) { pStory in
            self.pocketStories = pStory
            return succeed()
        }
    }
    */

    @objc func showMorePocketStories() {
        showSiteWithURLHandler(Pocket.MoreStoriesURL)
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
        guard let indexPath = self.collectionView?.indexPathForItem(at: point) else { return }

        switch Section(indexPath.section) {
        case .topSites:
            let topSiteCell = self.collectionView?.cellForItem(at: indexPath) as! ASHorizontalScrollCell
            let pointInTopSite = longPressGestureRecognizer.location(in: topSiteCell.collectionView)
            guard let topSiteIndexPath = topSiteCell.collectionView.indexPathForItem(at: pointInTopSite) else { return }
            presentContextMenu(for: IndexPath(row: topSiteIndexPath.row, section: Section.topSites.rawValue))
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

    func selectItemAtIndex(_ index: Int, inSection section: Section) {
        var site: Site? = nil
        /* Ecosia deactivate pocket
        switch section {
        case .pocket:
            site = Site(url: pocketStories[index].url.absoluteString, title: pocketStories[index].title)
            let key = TelemetryWrapper.EventExtraKey.pocketTilePosition.rawValue
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .pocketStory, value: nil, extras: [key : "\(index)"])
        case .topSites, .libraryShortcuts, .jumpBackIn, .recentlySaved, .customizeHome:
            return
        }
        */

        if let site = site {
            showSiteWithURLHandler(URL(string: site.url)!)
        }
    }
}

// MARK: - Actions Handling

extension FirefoxHomeViewController {
    @objc func openTabTray(_ sender: UIButton) {
        if sender.accessibilityIdentifier == FxHomeAccessibilityIdentifiers.MoreButtons.jumpBackIn {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .jumpBackInSectionShowAll)
        }
        homePanelDelegate?.homePanelDidRequestToOpenTabTray(withFocusedTab: nil)
    }

    @objc func openBookmarks(_ sender: UIButton) {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .bookmarks)
        Analytics.shared.browser(.open, label: .favourites, property: .home)
    }

    @objc func openHistory() {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .history)
        Analytics.shared.browser(.open, label: .history, property: .home)
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
        default:
            return nil
        }

        let openInNewTabAction = PhotonActionSheetItem(title: Strings.OpenInNewTabContextMenuTitle, iconString: "rebrandNewTab") { _, _ in
            self.homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: false)
            Analytics.shared.browser(.open, label: .newTab, property: .menu)
        }

        let openInNewPrivateTabAction = PhotonActionSheetItem(title: Strings.OpenInNewPrivateTabContextMenuTitle, iconString: "rebrandPrivate") { _, _ in
            self.homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
        }

        let bookmarkAction: PhotonActionSheetItem
        if site.bookmarked ?? false {
            bookmarkAction = PhotonActionSheetItem(title: Strings.RemoveBookmarkContextMenuTitle, iconString: "rebrandBookmarkRemove", handler: { _, _ in
                self.profile.places.deleteBookmarksWithURL(url: site.url) >>== {
                    self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: false)
                    site.setBookmarked(false)
                }

                TelemetryWrapper.recordEvent(category: .action, method: .delete, object: .bookmark, value: .activityStream)
                Analytics.shared.browser(.delete, label: .favourites, property: .home)
            })
        } else {
            bookmarkAction = PhotonActionSheetItem(title: Strings.BookmarkContextMenuTitle, iconString: "rebrandBookmarkRemove", handler: { _, _ in
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
                Analytics.shared.browser(.add, label: .favourites, property: .home)
            })
        }

        let shareAction = PhotonActionSheetItem(title: Strings.ShareContextMenuTitle, iconString: "action_share", handler: { _, _ in
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

        let removeTopSiteAction = PhotonActionSheetItem(title: Strings.RemoveContextMenuTitle, iconString: "rebrandRemove", handler: { _, _ in
            self.hideURLFromTopSites(site)
        })

        let pinTopSite = PhotonActionSheetItem(title: Strings.AddToShortcutsActionTitle, iconString: "action_pin", handler: { _, _ in
            self.pinTopSite(site)
        })

        let removePinTopSite = PhotonActionSheetItem(title: Strings.RemoveFromShortcutsActionTitle, iconString: "action_unpin", handler: { _, _ in
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

// MARK: - Ecosia Additions

extension FirefoxHomeViewController: SearchbarCellDelegate {
    func searchbarCellPressed(_ cell: SearchbarCell) {
        delegate?.homeDidTapSearchButton(self)
    }
}

extension FirefoxHomeViewController {

    fileprivate func updateTreesCell() {
        guard let impactCell = impactCell else { return }
        impactCell.display(treesCellModel)
        flowLayout.invalidateLayout()
    }

    fileprivate var treesCellModel: TreesCellModel {
        let trees = Referrals.isEnabled ? User.shared.impact : User.shared.searchImpact
        return .init(trees: trees, searches: personalCounter.state!, style: .ntp)
    }

}

extension FirefoxHomeViewController: NTPTooltipDelegate {
    func ntpTooltipTapped(_ tooltip: NTPTooltip?) {

        guard let ntpHighlight = ntpHighlight else { return }

        UIView.animate(withDuration: 0.3) {
            tooltip?.alpha = 0
        } completion: { _ in

            switch ntpHighlight {
            case .counterIntro:
                User.shared.hideCounterIntro()
            case .gotClaimed, .successfulInvite:
                User.shared.referrals.accept()
            case .referralSpotlight:
                Analytics.shared.openInvitePromo()
                User.shared.hideReferralSpotlight()
            }
        }
    }
}

extension FirefoxHomeViewController: NTPLayoutHighlightDataSource {
    var ntpHighlight: NTPTooltip.Highlight? {
        guard !User.shared.firstTime else { return nil }

        if User.shared.showsCounterIntro {
            return .counterIntro
        }

        guard Referrals.isEnabled else { return nil }
        if User.shared.referrals.isNewClaim {
            return .gotClaimed
        }

        if User.shared.referrals.newClaims > 0 {
            return .successfulInvite
        }

        if User.shared.showsReferralSpotlight {
            return .referralSpotlight
        }
        return nil
    }

    func ntpLayoutHighlightText() -> String? {
        return ntpHighlight?.text
    }

    func reloadTooltip() {
        collectionView.collectionViewLayout.invalidateLayout()
    }

}
