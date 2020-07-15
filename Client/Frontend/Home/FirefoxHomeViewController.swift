/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import UIKit
import Storage
import SDWebImage
import XCGLogger
import SyncTelemetry
import SnapKit

private let log = Logger.browserLogger
private let DefaultSuggestedSitesKey = "topSites.deletedSuggestedSites"

// MARK: -  Lifecycle
struct FirefoxHomeUX {
    static let rowSpacing: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 30 : 20
    static let highlightCellHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 250 : 200
    static let sectionInsetsForSizeClass = UXSizeClasses(compact: 0, regular: 101, other: 20)
    static let numberOfItemsPerRowForSizeClassIpad = UXSizeClasses(compact: 3, regular: 4, other: 2)
    static let SectionInsetsForIpad: CGFloat = 101
    static let SectionInsetsForIphone: CGFloat = 20
    static let MinimumInsets: CGFloat = 20
    static let TopSitesInsets: CGFloat = 6
    static let LibraryShortcutsHeight: CGFloat = 100
    static let LibraryShortcutsMaxWidth: CGFloat = 350
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

protocol HomePanelDelegate: AnyObject {
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool)
    func homePanel(didSelectURL url: URL, visitType: VisitType)
    func homePanelDidRequestToOpenLibrary(panel: LibraryPanelType)
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

class FirefoxHomeViewController: UICollectionViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate?
    fileprivate let profile: Profile
    fileprivate let pocketAPI = Pocket()
    fileprivate let flowLayout = UICollectionViewFlowLayout()

    fileprivate lazy var topSitesManager: ASHorizontalScrollCellManager = {
        let manager = ASHorizontalScrollCellManager()
        return manager
    }()

    fileprivate lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    // Not used for displaying. Only used for calculating layout.
    lazy var topSiteCell: ASHorizontalScrollCell = {
        let customCell = ASHorizontalScrollCell(frame: CGRect(width: self.view.frame.size.width, height: 0))
        customCell.delegate = self.topSitesManager
        return customCell
    }()

    var pocketStories: [PocketStory] = []

    init(profile: Profile) {
        self.profile = profile
        super.init(collectionViewLayout: flowLayout)
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self

        collectionView?.addGestureRecognizer(longPressRecognizer)

        let refreshEvents: [Notification.Name] = [.DynamicFontChanged, .HomePanelPrefsChanged]
        refreshEvents.forEach { NotificationCenter.default.addObserver(self, selector: #selector(reload), name: $0, object: nil) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Section.allValues.forEach { self.collectionView?.register(Section($0.rawValue).cellType, forCellWithReuseIdentifier: Section($0.rawValue).cellIdentifier) }
        self.collectionView?.register(ASHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        self.collectionView?.register(ASFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "Footer")
        collectionView?.keyboardDismissMode = .onDrag

        self.profile.panelDataObservers.activityStream.delegate = self

        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadAll()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: {context in
            //The AS context menu does not behave correctly. Dismiss it when rotating.
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.topSitesManager.currentTraits = self.traitCollection
    }

    @objc func reload(notification: Notification) {
        reloadAll()
    }

    func applyTheme() {
        collectionView?.backgroundColor = UIColor.theme.homePanel.topSitesBackground
        topSiteCell.collectionView.reloadData()
        if let collectionView = self.collectionView, collectionView.numberOfSections > 0, collectionView.numberOfItems(inSection: 0) > 0 {
            collectionView.reloadData()
        }
    }

    func scrollToTop(animated: Bool = false) {
        collectionView?.setContentOffset(.zero, animated: animated)
    }
}

// MARK: -  Section management
extension FirefoxHomeViewController {
    enum Section: Int {
        case topSites
        case libraryShortcuts
        case pocket

        static let count = 3
        static let allValues = [topSites, libraryShortcuts, pocket]

        var title: String? {
            switch self {
            case .pocket: return Strings.ASPocketTitle
            case .topSites: return Strings.ASTopSitesTitle
            case .libraryShortcuts: return Strings.AppMenuLibraryTitleString
            }
        }

        var headerHeight: CGSize {
            return CGSize(width: 50, height: 40)
        }

        var headerImage: UIImage? {
            switch self {
            case .pocket: return UIImage.templateImageNamed("menu-pocket")
            case .topSites: return UIImage.templateImageNamed("menu-panel-TopSites")
            case .libraryShortcuts: return UIImage.templateImageNamed("menu-library")
            }
        }

        var footerHeight: CGSize {
            switch self {
            case .pocket: return .zero
            case .topSites, .libraryShortcuts: return CGSize(width: 50, height: 5)
            }
        }

        func cellHeight(_ traits: UITraitCollection, width: CGFloat) -> CGFloat {
            switch self {
            case .pocket: return FirefoxHomeUX.highlightCellHeight
            case .topSites: return 0 //calculated dynamically
            case .libraryShortcuts: return FirefoxHomeUX.LibraryShortcutsHeight
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

            switch self {
            case .pocket, .libraryShortcuts:
                let window = UIApplication.shared.keyWindow
                let safeAreaInsets = window?.safeAreaInsets.left ?? 0
                insets += FirefoxHomeUX.MinimumInsets + safeAreaInsets
                return insets
            case .topSites:
                insets += FirefoxHomeUX.TopSitesInsets
                return insets
            }
        }

        func numberOfItemsForRow(_ traits: UITraitCollection) -> CGFloat {
            switch self {
            case .pocket:
                var numItems: CGFloat = FirefoxHomeUX.numberOfItemsPerRowForSizeClassIpad[traits.horizontalSizeClass]
                if UIApplication.shared.statusBarOrientation.isPortrait {
                    numItems = numItems - 1
                }
                if traits.horizontalSizeClass == .compact && UIApplication.shared.statusBarOrientation.isLandscape {
                    numItems = numItems - 1
                }
                return numItems
            case .topSites, .libraryShortcuts:
                return 1
            }
        }

        func cellSize(for traits: UITraitCollection, frameWidth: CGFloat) -> CGSize {
            let height = cellHeight(traits, width: frameWidth)
            let inset = sectionInsets(traits, frameWidth: frameWidth) * 2

            switch self {
            case .pocket:
                let numItems = numberOfItemsForRow(traits)
                return CGSize(width: floor(((frameWidth - inset) - (FirefoxHomeUX.MinimumInsets * (numItems - 1))) / numItems), height: height)
            case .topSites, .libraryShortcuts:
                return CGSize(width: frameWidth - inset, height: height)
            }
        }

        var headerView: UIView? {
            let view = ASHeaderView()
            view.title = title
            return view
        }

        var cellIdentifier: String {
            switch self {
            case .topSites: return "TopSiteCell"
            case .pocket: return "PocketCell"
            case .libraryShortcuts: return  "LibraryShortcutsCell"
            }
        }

        var cellType: UICollectionViewCell.Type {
            switch self {
            case .topSites: return ASHorizontalScrollCell.self
            case .pocket: return FirefoxHomeHighlightCell.self
            case .libraryShortcuts: return ASLibraryCell.self
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

// MARK: -  Tableview Delegate
extension FirefoxHomeViewController: UICollectionViewDelegateFlowLayout {

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header", for: indexPath) as! ASHeaderView
                view.iconView.isHidden = false
                view.iconView.image = Section(indexPath.section).headerImage
                let title = Section(indexPath.section).title
                switch Section(indexPath.section) {
                case .pocket:
                    view.title = title
                    view.moreButton.isHidden = false
                    view.moreButton.setTitle(Strings.PocketMoreStoriesText, for: .normal)
                    view.moreButton.addTarget(self, action: #selector(showMorePocketStories), for: .touchUpInside)
                    view.titleLabel.textColor = UIColor.Pocket.red
                    view.titleLabel.accessibilityIdentifier = "pocketTitle"
                    view.moreButton.setTitleColor(UIColor.Pocket.red, for: .normal)
                    view.iconView.tintColor = UIColor.Pocket.red
                    return view
                case .topSites:
                    view.title = title
                    view.titleLabel.accessibilityIdentifier = "topSitesTitle"
                    view.moreButton.isHidden = true
                    return view
                case .libraryShortcuts:
                    view.title = title
                    view.moreButton.isHidden = false
                    view.moreButton.setTitle(Strings.AppMenuLibrarySeeAllTitleString, for: .normal)
                    view.moreButton.addTarget(self, action: #selector(openHistory), for: .touchUpInside)
                    view.moreButton.accessibilityIdentifier = "libraryMoreButton"
                    view.titleLabel.accessibilityIdentifier = "libraryTitle"
                    return view
            }
        case UICollectionView.elementKindSectionFooter:
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "Footer", for: indexPath) as! ASFooterView
                switch Section(indexPath.section) {
                case .topSites, .pocket:
                    return view
                case .libraryShortcuts:
                    view.separatorLineView?.isHidden = true
                    return view
            }
            default:
                return UICollectionReusableView()
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.longPressRecognizer.isEnabled = false
        selectItemAtIndex(indexPath.item, inSection: Section(indexPath.section))
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize = Section(indexPath.section).cellSize(for: self.traitCollection, frameWidth: self.view.frame.width)

        switch Section(indexPath.section) {
        case .topSites:
            // Create a temporary cell so we can calculate the height.
            let layout = topSiteCell.collectionView.collectionViewLayout as! HorizontalFlowLayout
            let estimatedLayout = layout.calculateLayout(for: CGSize(width: cellSize.width, height: 0))
            return CGSize(width: cellSize.width, height: estimatedLayout.size.height)
        case .pocket:
            return cellSize
        case .libraryShortcuts:
            let numberofshortcuts: CGFloat = 4
            let titleSpacing: CGFloat = 10
            let width = min(FirefoxHomeUX.LibraryShortcutsMaxWidth, cellSize.width)
            return CGSize(width: width, height: (width / numberofshortcuts) + titleSpacing)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch Section(section) {
        case .pocket:
            return pocketStories.isEmpty ? .zero : Section(section).headerHeight
        case .topSites:
            return Section(section).headerHeight
        case .libraryShortcuts:
            return UIDevice.current.userInterfaceIdiom == .pad ? CGSize.zero : Section(section).headerHeight
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        switch Section(section) {
        case .pocket:
            return .zero
        case .topSites:
            return Section(section).footerHeight
        case .libraryShortcuts:
            return UIDevice.current.userInterfaceIdiom == .pad ? CGSize.zero : Section(section).footerHeight
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return FirefoxHomeUX.rowSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let insets = Section(section).sectionInsets(self.traitCollection, frameWidth: self.view.frame.width)
        return UIEdgeInsets(top: 0, left: insets, bottom: 0, right: insets)
    }

    fileprivate func showSiteWithURLHandler(_ url: URL) {
        let visitType = VisitType.bookmark
        homePanelDelegate?.homePanel(didSelectURL: url, visitType: visitType)
    }
}

// MARK: - Tableview Data Source
extension FirefoxHomeViewController {

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
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
        case .topSites:
            return topSitesManager.content.isEmpty ? 0 : 1
        case .pocket:
            // There should always be a full row of pocket stories (numItems) otherwise don't show them
            return pocketStories.count
        case .libraryShortcuts:
            // disable the libary shortcuts on the ipad
            return UIDevice.current.userInterfaceIdiom == .pad ? 0 : 1
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = Section(indexPath.section).cellIdentifier
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)

        switch Section(indexPath.section) {
        case .topSites:
            return configureTopSitesCell(cell, forIndexPath: indexPath)
        case .pocket:
            return configurePocketItemCell(cell, forIndexPath: indexPath)
        case .libraryShortcuts:
            return configureLibraryShortcutsCell(cell, forIndexPath: indexPath)
        }
    }

    func configureLibraryShortcutsCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let libraryCell = cell as! ASLibraryCell
        let targets = [#selector(openBookmarks), #selector(openReadingList), #selector(openDownloads), #selector(openSyncedTabs)]
        libraryCell.libraryButtons.map({ $0.button }).zip(targets).forEach { (button, selector) in
            button.removeTarget(nil, action: nil, for: .allEvents)
            button.addTarget(self, action: selector, for: .touchUpInside)
        }
        libraryCell.applyTheme()
        return cell
    }

    //should all be collectionview
    func configureTopSitesCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let topSiteCell = cell as! ASHorizontalScrollCell
        topSiteCell.delegate = self.topSitesManager
        topSiteCell.setNeedsLayout()
        topSiteCell.collectionView.reloadData()
        return cell
    }

    func configurePocketItemCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let pocketStory = pocketStories[indexPath.row]
        let pocketItemCell = cell as! FirefoxHomeHighlightCell
        pocketItemCell.configureWithPocketStory(pocketStory)
        return pocketItemCell
    }

}

// MARK: - Data Management
extension FirefoxHomeViewController: DataObserverDelegate {

    // Reloads both highlights and top sites data from their respective caches. Does not invalidate the cache.
    // See ActivityStreamDataObserver for invalidation logic.
    func reloadAll() {
        // If the pocket stories are not availible for the Locale the PocketAPI will return nil
        // So it is okay if the default here is true

        self.getTopSites().uponQueue(.main) { _ in
            // If there is no pending cache update and highlights are empty. Show the onboarding screen
            self.collectionView?.reloadData()

            self.getPocketSites().uponQueue(.main) { _ in
                if !self.pocketStories.isEmpty {
                    self.collectionView?.reloadData()
                }
            }
            // Refresh the AS data in the background so we'll have fresh data next time we show.
            self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: false)
        }
    }

    func getPocketSites() -> Success {
        let showPocket = (profile.prefs.boolForKey(PrefsKeys.ASPocketStoriesVisible) ?? Pocket.IslocaleSupported(Locale.current.identifier))
        guard showPocket else {
            self.pocketStories = []
            return succeed()
        }

        return pocketAPI.globalFeed(items: 10).bindQueue(.main) { pStory in
            self.pocketStories = pStory
            return succeed()
        }
    }

    @objc func showMorePocketStories() {
        showSiteWithURLHandler(Pocket.MoreStoriesURL)
    }

    func getTopSites() -> Success {
        let numRows = max(self.profile.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows) ?? TopSitesRowCountSettingsController.defaultNumberOfRows, 1)
        let maxItems = UIDevice.current.userInterfaceIdiom == .pad ? 32 : 16
        return self.profile.history.getTopSitesWithLimit(maxItems).both(self.profile.history.getPinnedTopSites()).bindQueue(.main) { (topsites, pinnedSites) in
            guard let mySites = topsites.successValue?.asArray(), let pinned = pinnedSites.successValue?.asArray() else {
                return succeed()
            }

            // How sites are merged together. We compare against the url's base domain. example m.youtube.com is compared against `youtube.com`
            let unionOnURL = { (site: Site) -> String in
                return URL(string: site.url)?.normalizedHost ?? ""
            }

            // Fetch the default sites
            let defaultSites = self.defaultTopSites()
            // create PinnedSite objects. used by the view layer to tell topsites apart
            let pinnedSites: [Site] = pinned.map({ PinnedSite(site: $0) })

            // Merge default topsites with a user's topsites.
            let mergedSites = mySites.union(defaultSites, f: unionOnURL)
            // Merge pinnedSites with sites from the previous step
            let allSites = pinnedSites.union(mergedSites, f: unionOnURL)

            // Favour topsites from defaultSites as they have better favicons. But keep PinnedSites
            let newSites = allSites.map { site -> Site in
                if let _ = site as? PinnedSite {
                    return site
                }
                let domain = URL(string: site.url)?.shortDisplayString
                return defaultSites.find { $0.title.lowercased() == domain } ?? site
            }

            self.topSitesManager.currentTraits = self.view.traitCollection
            let maxItems = Int(numRows) * self.topSitesManager.numberOfHorizontalItems()
            if newSites.count > Int(ActivityStreamTopSiteCacheSize) {
                self.topSitesManager.content = Array(newSites[0..<Int(ActivityStreamTopSiteCacheSize)])
            } else {
                self.topSitesManager.content = newSites
            }

            if newSites.count > maxItems {
                self.topSitesManager.content =  Array(newSites[0..<maxItems])
            }

            self.topSitesManager.urlPressedHandler = { [unowned self] url, indexPath in
                self.longPressRecognizer.isEnabled = false
                self.showSiteWithURLHandler(url as URL)
            }

            return succeed()
        }
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
        guard let host = site.tileURL.normalizedHost else {
            return
        }
        let url = site.tileURL.absoluteString
        // if the default top sites contains the siteurl. also wipe it from default suggested sites.
        if defaultTopSites().filter({$0.url == url}).isEmpty == false {
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
        profile.history.removeFromPinnedTopSites(site).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: true)
        }
    }

    fileprivate func deleteTileForSuggestedSite(_ siteURL: String) {
        var deletedSuggestedSites = profile.prefs.arrayForKey(DefaultSuggestedSitesKey) as? [String] ?? []
        deletedSuggestedSites.append(siteURL)
        profile.prefs.setObject(deletedSuggestedSites, forKey: DefaultSuggestedSitesKey)
    }

    func defaultTopSites() -> [Site] {
        let suggested = SuggestedSites.asArray()
        let deleted = profile.prefs.arrayForKey(DefaultSuggestedSitesKey) as? [String] ?? []
        return suggested.filter({deleted.firstIndex(of: $0.url) == .none})
    }

    @objc fileprivate func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }

        let point = longPressGestureRecognizer.location(in: self.collectionView)
        guard let indexPath = self.collectionView?.indexPathForItem(at: point) else { return }

        switch Section(indexPath.section) {
        case .pocket:
            presentContextMenu(for: indexPath)
        case .topSites:
            let topSiteCell = self.collectionView?.cellForItem(at: indexPath) as! ASHorizontalScrollCell
            let pointInTopSite = longPressGestureRecognizer.location(in: topSiteCell.collectionView)
            guard let topSiteIndexPath = topSiteCell.collectionView.indexPathForItem(at: pointInTopSite) else { return }
            presentContextMenu(for: topSiteIndexPath)
        case .libraryShortcuts:
            return
        }
    }

    fileprivate func fetchBookmarkStatus(for site: Site, with indexPath: IndexPath, forSection section: Section, completionHandler: @escaping () -> Void) {
        profile.places.isBookmarked(url: site.url).uponQueue(.main) { result in
            let isBookmarked = result.successValue ?? false
            site.setBookmarked(isBookmarked)
            completionHandler()
        }
    }

    func selectItemAtIndex(_ index: Int, inSection section: Section) {
        let site: Site?
        switch section {
        case .pocket:
            site = Site(url: pocketStories[index].url.absoluteString, title: pocketStories[index].title)
            let params = ["Source": "Activity Stream", "StoryType": "Article"]
            LeanPlumClient.shared.track(event: .openedPocketStory, withParameters: params)
        case .topSites:
            return
        case .libraryShortcuts:
            return
        }
        if let site = site {
            showSiteWithURLHandler(URL(string: site.url)!)
        }
    }
}

extension FirefoxHomeViewController {
    @objc func openBookmarks() {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .bookmarks)
    }

    @objc func openHistory() {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .history)
    }

    @objc func openSyncedTabs() {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .syncedTabs)
    }

    @objc func openReadingList() {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .readingList)
    }

    @objc func openDownloads() {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .downloads)
    }
}

extension FirefoxHomeViewController: HomePanelContextMenu {
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?) {

        fetchBookmarkStatus(for: site, with: indexPath, forSection: Section(indexPath.section)) {
            guard let contextMenu = completionHandler() else { return }
            self.present(contextMenu, animated: true, completion: nil)
        }
    }

    func getSiteDetails(for indexPath: IndexPath) -> Site? {
        switch Section(indexPath.section) {
        case .pocket:
            return Site(url: pocketStories[indexPath.row].url.absoluteString, title: pocketStories[indexPath.row].title)
        case .topSites:
            return topSitesManager.content[indexPath.item]
        case .libraryShortcuts:
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
        case .libraryShortcuts:
            return nil
        }

        let openInNewTabAction = PhotonActionSheetItem(title: Strings.OpenInNewTabContextMenuTitle, iconString: "quick_action_new_tab") { _, _ in
            self.homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: false)
            let source = ["Source": "Activity Stream Long Press Context Menu"]
            LeanPlumClient.shared.track(event: .openedNewTab, withParameters: source)
            if Section(indexPath.section) == .pocket {
                LeanPlumClient.shared.track(event: .openedPocketStory, withParameters: source)
            }
        }

        let openInNewPrivateTabAction = PhotonActionSheetItem(title: Strings.OpenInNewPrivateTabContextMenuTitle, iconString: "quick_action_new_private_tab") { _, _ in
            self.homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
        }

        let bookmarkAction: PhotonActionSheetItem
        if site.bookmarked ?? false {
            bookmarkAction = PhotonActionSheetItem(title: Strings.RemoveBookmarkContextMenuTitle, iconString: "action_bookmark_remove", handler: { _, _ in
                self.profile.places.deleteBookmarksWithURL(url: site.url) >>== {
                    self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: false)
                    site.setBookmarked(false)
                }

                TelemetryWrapper.recordEvent(category: .action, method: .delete, object: .bookmark, value: .activityStream)
            })
        } else {
            bookmarkAction = PhotonActionSheetItem(title: Strings.BookmarkContextMenuTitle, iconString: "action_bookmark", handler: { _, _ in
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
                LeanPlumClient.shared.track(event: .savedBookmark)
                TelemetryWrapper.recordEvent(category: .action, method: .add, object: .bookmark, value: .activityStream)
            })
        }

        let shareAction = PhotonActionSheetItem(title: Strings.ShareContextMenuTitle, iconString: "action_share", handler: { _, _ in
            let helper = ShareExtensionHelper(url: siteURL, tab: nil)
            let controller = helper.createActivityViewController({ (_, _) in })
            if UI_USER_INTERFACE_IDIOM() == .pad, let popoverController = controller.popoverPresentationController {
                let cellRect = sourceView?.frame ?? .zero
                let cellFrameInSuperview = self.collectionView?.convert(cellRect, to: self.collectionView) ?? .zero

                popoverController.sourceView = sourceView
                popoverController.sourceRect = CGRect(origin: CGPoint(x: cellFrameInSuperview.size.width/2, y: cellFrameInSuperview.height/2), size: .zero)
                popoverController.permittedArrowDirections = [.up, .down, .left]
                popoverController.delegate = self
            }
            self.present(controller, animated: true, completion: nil)
        })

        let removeTopSiteAction = PhotonActionSheetItem(title: Strings.RemoveContextMenuTitle, iconString: "action_remove", handler: { _, _ in
            self.hideURLFromTopSites(site)
        })

        let pinTopSite = PhotonActionSheetItem(title: Strings.PinTopsiteActionTitle, iconString: "action_pin", handler: { _, _ in
            self.pinTopSite(site)
        })

        let removePinTopSite = PhotonActionSheetItem(title: Strings.RemovePinTopsiteActionTitle, iconString: "action_unpin", handler: { _, _ in
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
            case .pocket: break
            case .topSites: actions.append(contentsOf: topSiteActions)
            case .libraryShortcuts: break
        }
        return actions
    }
}

extension FirefoxHomeViewController: UIPopoverPresentationControllerDelegate {

    // Dismiss the popover if the device is being rotated.
    // This is used by the Share UIActivityViewController action sheet on iPad
    func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {
        popoverPresentationController.presentedViewController.dismiss(animated: false, completion: nil)
    }
}

// MARK: - Section Header View
private struct FirefoxHomeHeaderViewUX {
    static var SeparatorColor: UIColor { return UIColor.theme.homePanel.separator }
    static let TextFont = DynamicFontHelper.defaultHelper.SmallSizeHeavyWeightAS
    static let ButtonFont = DynamicFontHelper.defaultHelper.MediumSizeBoldFontAS
    static let SeparatorHeight = 0.5
    static let Insets: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? FirefoxHomeUX.SectionInsetsForIpad + FirefoxHomeUX.MinimumInsets : FirefoxHomeUX.MinimumInsets
    static let TitleTopInset: CGFloat = 5
}

class ASFooterView: UICollectionReusableView {

    var separatorLineView: UIView?
    var leftConstraint: Constraint? //This constraint aligns content (Titles, buttons) between all sections.

    override init(frame: CGRect) {
        super.init(frame: frame)

        let separatorLine = UIView()
        self.backgroundColor = UIColor.clear
        addSubview(separatorLine)
        separatorLine.snp.makeConstraints { make in
            make.height.equalTo(FirefoxHomeHeaderViewUX.SeparatorHeight)
            leftConstraint = make.leading.equalTo(self.safeArea.leading).inset(insets).constraint
            make.trailing.equalTo(self.safeArea.trailing).inset(insets)
            make.top.equalTo(self.snp.top)
        }
        separatorLineView = separatorLine
        applyTheme()
    }

    var insets: CGFloat {
        return UIScreen.main.bounds.size.width == self.frame.size.width && UIDevice.current.userInterfaceIdiom == .pad ? FirefoxHomeHeaderViewUX.Insets : FirefoxHomeUX.MinimumInsets
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        separatorLineView?.isHidden = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // update the insets every time a layout happens.Insets change depending on orientation or size (ipad split screen)
        leftConstraint?.update(offset: insets)
    }
}

extension ASFooterView: Themeable {
    func applyTheme() {
        separatorLineView?.backgroundColor = FirefoxHomeHeaderViewUX.SeparatorColor
    }
}

class ASHeaderView: UICollectionReusableView {
    static let verticalInsets: CGFloat = 4

    lazy fileprivate var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = self.title
        titleLabel.textColor = UIColor.theme.homePanel.activityStreamHeaderText
        titleLabel.font = FirefoxHomeHeaderViewUX.TextFont
        titleLabel.minimumScaleFactor = 0.6
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        return titleLabel
    }()

    lazy var moreButton: UIButton = {
        let button = UIButton()
        button.isHidden = true
        button.titleLabel?.font = FirefoxHomeHeaderViewUX.ButtonFont
        button.contentHorizontalAlignment = .right
        button.setTitleColor(UIConstants.SystemBlueColor, for: .normal)
        button.setTitleColor(UIColor.Photon.Grey50, for: .highlighted)
        return button
    }()

    lazy fileprivate var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = UIColor.Photon.Grey50
        imageView.isHidden = true
        return imageView
    }()

    var title: String? {
        willSet(newTitle) {
            titleLabel.text = newTitle
        }
    }

    var leftConstraint: Constraint?
    var rightConstraint: Constraint?

    var titleInsets: CGFloat {
        get {
            return UIScreen.main.bounds.size.width == self.frame.size.width && UIDevice.current.userInterfaceIdiom == .pad ? FirefoxHomeHeaderViewUX.Insets : FirefoxHomeUX.MinimumInsets
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        moreButton.isHidden = true
        moreButton.setTitle(nil, for: .normal)
        moreButton.accessibilityIdentifier = nil;
        titleLabel.text = nil
        moreButton.removeTarget(nil, action: nil, for: .allEvents)
        iconView.isHidden = true
        iconView.tintColor =  UIColor.theme.homePanel.activityStreamHeaderText
        titleLabel.textColor = UIColor.theme.homePanel.activityStreamHeaderText
        moreButton.setTitleColor(UIConstants.SystemBlueColor, for: .normal)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(moreButton)
        addSubview(iconView)
        moreButton.snp.makeConstraints { make in
            make.top.equalTo(self.snp.top).offset(ASHeaderView.verticalInsets)
            make.bottom.equalToSuperview().offset(-ASHeaderView.verticalInsets)
            self.rightConstraint = make.trailing.equalTo(self.safeArea.trailing).inset(-titleInsets).constraint
        }
        moreButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(5)
            make.trailing.equalTo(moreButton.snp.leading).inset(-FirefoxHomeHeaderViewUX.TitleTopInset)
            make.top.equalTo(self.snp.top).offset(ASHeaderView.verticalInsets)
            make.bottom.equalToSuperview().offset(-ASHeaderView.verticalInsets)
        }
        iconView.snp.makeConstraints { make in
            self.leftConstraint = make.leading.equalTo(self.safeArea.leading).inset(titleInsets).constraint
            make.centerY.equalTo(self.snp.centerY)
            make.size.equalTo(16)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        leftConstraint?.update(offset: titleInsets)
        rightConstraint?.update(offset: -titleInsets)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LibraryShortcutView: UIView {
    static let spacing: CGFloat = 15

    var button = UIButton()
    var title = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(button)
        addSubview(title)
        button.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(self).offset(-LibraryShortcutView.spacing)
            make.height.equalTo(self.snp.width).offset(-LibraryShortcutView.spacing)
        }
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.7
        title.lineBreakMode = .byTruncatingTail
        title.font = DynamicFontHelper.defaultHelper.SmallSizeRegularWeightAS
        title.textAlignment = .center
        title.snp.makeConstraints { make in
            make.top.equalTo(button.snp.bottom).offset(5)
            make.leading.trailing.equalToSuperview()
        }
        button.imageView?.contentMode = .scaleToFill
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(equalInset: LibraryShortcutView.spacing)
        button.tintColor = .white
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        button.layer.cornerRadius = (self.frame.width - LibraryShortcutView.spacing) / 2
        super.layoutSubviews()
    }
}

class ASLibraryCell: UICollectionViewCell, Themeable {

    var mainView = UIStackView()

    struct LibraryPanel {
        let title: String
        let image: UIImage?
        let color: UIColor
    }

    var libraryButtons: [LibraryShortcutView] = []

    let bookmarks = LibraryPanel(title: Strings.AppMenuBookmarksTitleString, image: UIImage.templateImageNamed("menu-Bookmark"), color: UIColor.Photon.Blue50)
    let history = LibraryPanel(title: Strings.AppMenuHistoryTitleString, image: UIImage.templateImageNamed("menu-panel-History"), color: UIColor.Photon.Orange50)
    let readingList = LibraryPanel(title: Strings.AppMenuReadingListTitleString, image: UIImage.templateImageNamed("menu-panel-ReadingList"), color: UIColor.Photon.Teal60)
    let downloads = LibraryPanel(title: Strings.AppMenuDownloadsTitleString, image: UIImage.templateImageNamed("menu-panel-Downloads"), color: UIColor.Photon.Magenta60)
    let syncedTabs = LibraryPanel(title: Strings.AppMenuSyncedTabsTitleString, image: UIImage.templateImageNamed("menu-sync"), color: UIColor.Photon.Purple70)

    override init(frame: CGRect) {
        super.init(frame: frame)
        mainView.distribution = .fillEqually
        mainView.spacing = 10
        addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        [bookmarks, readingList, downloads, syncedTabs].forEach { item in
            let view = LibraryShortcutView()
            view.button.setImage(item.image, for: .normal)
            view.title.text = item.title
            let words = view.title.text?.components(separatedBy: NSCharacterSet.whitespacesAndNewlines).count
            view.title.numberOfLines = words == 1 ? 1 :2
            view.button.backgroundColor = item.color
            view.button.setTitleColor(UIColor.theme.homePanel.topSiteDomain, for: .normal)
            view.accessibilityLabel = item.title
            mainView.addArrangedSubview(view)
            libraryButtons.append(view)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        libraryButtons.forEach { button in
            button.title.textColor = UIColor.theme.homePanel.activityStreamCellTitle
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}

open class PinnedSite: Site {
    let isPinnedSite = true

    init(site: Site) {
        super.init(url: site.url, title: site.title, bookmarked: site.bookmarked)
        self.icon = site.icon
        self.metadata = site.metadata
    }
}
