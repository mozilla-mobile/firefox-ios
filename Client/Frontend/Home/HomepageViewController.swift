// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import UIKit
import Storage
// Ecosia // import SyncTelemetry
import MozillaAppServices
import Core

class HomepageViewController: UIViewController, HomePanel, FeatureFlaggable {

    // MARK: - Typealiases
    private typealias a11y = AccessibilityIdentifiers.FirefoxHomepage

    // MARK: - Operational Variables
    weak var homePanelDelegate: HomePanelDelegate?
    weak var libraryPanelDelegate: LibraryPanelDelegate?
    weak var browserBarViewDelegate: BrowserBarViewDelegate? {
        didSet {
            // Ecosia viewModel.jumpBackInViewModel.browserBarViewDelegate = browserBarViewDelegate
        }
    }

    var notificationCenter: NotificationProtocol = NotificationCenter.default

    private (set) var viewModel: HomepageViewModel
    private var contextMenuHelper: HomepageContextMenuHelper
    private var tabManager: TabManagerProtocol
    private var urlBar: URLBarViewProtocol
    var collectionView: UICollectionView! = nil

    var currentTab: Tab? {
        return tabManager.selectedTab
    }

    // MARK: - Initializers
    init(profile: Profile,
         tabManager: TabManagerProtocol,
         urlBar: URLBarViewProtocol,
         delegate: HomepageViewControllerDelegate?,
         referrals: Referrals) {

        self.urlBar = urlBar
        self.tabManager = tabManager
        let isPrivate = tabManager.selectedTab?.isPrivate ?? true
        self.viewModel = HomepageViewModel(profile: profile,
                                           isPrivate: isPrivate,
                                           tabManager: tabManager,
                                           urlBar: urlBar)
        self.delegate = delegate
        self.referrals = referrals

        self.contextMenuHelper = HomepageContextMenuHelper(viewModel: viewModel)
        super.init(nibName: nil, bundle: nil)

        contextMenuHelper.delegate = self
        contextMenuHelper.getPopoverSourceRect = { [weak self] popoverView in
            guard let self = self else { return CGRect() }
            return self.getPopoverSourceRect(sourceView: popoverView)
        }

        setupNotifications(forObserver: self,
                           observing: [.HomePanelPrefsChanged,
                                       .TabsPrivacyModeChanged])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()
        configureEcosiaSetup()

        // Delay setting up the view model delegate to ensure the views have been configured first
        viewModel.delegate = self

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        applyTheme()
        setupSectionsAction()
        reloadView()

        viewModel.recordViewAppeared()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if UIDevice.current.userInterfaceIdiom == .pad {
            reloadOnRotation()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()

        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass
            || previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass {
            reloadOnRotation()
        }
    }

    // MARK: - Layout

    func configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds,
                                          collectionViewLayout: createLayout())

        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        HomepageSectionType.cellTypes.forEach {
            collectionView.register($0, forCellWithReuseIdentifier: $0.cellIdentifier)
        }
        collectionView.register(LabelButtonHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: LabelButtonHeaderView.cellIdentifier)
        collectionView.register(NTPTooltip.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: NTPTooltip.key)
        collectionView.register(MoreButtonCell.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: MoreButtonCell.cellIdentifier)
        collectionView.keyboardDismissMode = .onDrag
        collectionView.addGestureRecognizer(longPressRecognizer)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .clear
        collectionView.accessibilityIdentifier = a11y.collectionView

        (collectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        collectionView?.backgroundColor = .clear

    }

    func createLayout() -> UICollectionViewLayout {
        let layout = NTPLayout { [weak self]
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in

            guard let self = self,
                  let viewModel = self.viewModel.getSectionViewModel(shownSection: sectionIndex),
                  viewModel.shouldShow
            else { return nil }
            return viewModel.section(for: layoutEnvironment.traitCollection)
        }
        layout.highlightDataSource = viewModel
        return layout
    }

    // MARK: Long press

    private lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    @objc fileprivate func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }

        let point = longPressGestureRecognizer.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point),
              let viewModel = viewModel.getSectionViewModel(shownSection: indexPath.section) as? HomepageSectionHandler
        else { return }

        viewModel.handleLongPress(with: collectionView, indexPath: indexPath)
    }

    // MARK: - Helpers

    /// Called to update the appearance source of the home page, and send tracking telemetry
    func recordHomepageAppeared(isZeroSearch: Bool) {
        viewModel.isZeroSearch = isZeroSearch
        viewModel.recordViewAppeared()
    }

    func recordHomepageDisappeared() {
        viewModel.recordViewDisappeared()
    }

    /// On iPhone, we call reloadOnRotation when the trait collection has changed, to ensure calculation
    /// is done with the new trait. On iPad, trait collection doesn't change from portrait to landscape (and vice-versa)
    /// since it's `.regular` on both. We reloadOnRotation from viewWillTransition in that case.
    private func reloadOnRotation() {
        if let _ = presentedViewController as? PhotonActionSheet {
            presentedViewController?.dismiss(animated: false, completion: nil)
        }

        // Force the entire collectionview to re-layout
        viewModel.refreshData(for: traitCollection)
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()

        // This pushes a reload to the end of the main queue after all the work associated with
        // rotating has been completed. This is important because some of the cells layout are
        // based on the screen state
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }

    private func adjustPrivacySensitiveSections(notification: Notification) {
        guard let dict = notification.object as? NSDictionary,
              let isPrivate = dict[Tab.privateModeKey] as? Bool
        else { return }

        viewModel.isPrivate = isPrivate
        reloadView()
    }

    func applyTheme() {
        view.backgroundColor = .theme.ecosia.ntpBackground
        collectionView?.backgroundColor = .theme.ecosia.ntpBackground
        collectionView.visibleCells.forEach({
            ($0 as? NotificationThemeable)?.applyTheme()
        })
        collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader).forEach({
            ($0 as? NotificationThemeable)?.applyTheme()
        })
        collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionFooter).forEach({
            ($0 as? NotificationThemeable)?.applyTheme()
        })
    }

    func scrollToTop(animated: Bool = false) {
        collectionView?.setContentOffset(.zero, animated: animated)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        dismissKeyboard()
    }

    @objc private func dismissKeyboard() {
        // Ecosia: only leave overlay mode if active
        guard urlBar.inOverlayMode,
                currentTab?.lastKnownUrl?.absoluteString.hasPrefix("internal://") == true else { return }

        urlBar.leaveOverlayMode()
    }

    func updatePocketCellsWithVisibleRatio(cells: [UICollectionViewCell], relativeRect: CGRect) {
        guard let window = UIWindow.keyWindow else { return }
        for cell in cells {
            // For every story cell get it's frame relative to the window
            let targetRect = cell.superview.map { window.convert(cell.frame, from: $0) } ?? .zero

            // TODO: If visibility ratio is over 50% sponsored content can be marked as seen by the user
            _ = targetRect.visibilityRatio(relativeTo: relativeRect)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Find visible pocket cells that holds pocket stories
        /* Ecosia
        let cells = self.collectionView.visibleCells.filter { $0.reuseIdentifier == PocketStandardCell.cellIdentifier }

        // Relative frame is the collectionView frame plus the status bar height
        let relativeRect = CGRect(
            x: collectionView.frame.minX,
            y: collectionView.frame.minY,
            width: collectionView.frame.width,
            height: collectionView.frame.height + UIWindow.statusBarHeight
        )
        updatePocketCellsWithVisibleRatio(cells: cells, relativeRect: relativeRect)
         */
    }

    private func showSiteWithURLHandler(_ url: URL, isGoogleTopSite: Bool = false) {
        let visitType = VisitType.bookmark
        homePanelDelegate?.homePanel(didSelectURL: url, visitType: visitType, isGoogleTopSite: isGoogleTopSite)
    }

    // MARK: Ecosia
    weak var delegate: HomepageViewControllerDelegate?
    var inOverlayMode = false {
        didSet {
            /* TODO: check if needed
            guard isViewLoaded else { return }
            if inOverlayMode && !oldValue, let cell = searchbarCell {
                UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState], animations: { [weak self] in
                    self?.collectionView.setContentOffset(.init(x: 0, y: cell.frame.maxY - FirefoxHomeUX.ScrollSearchBarOffset), animated: true)
                })
            } else if oldValue && !inOverlayMode && !collectionView.isDragging {
                UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState], animations: { [weak self] in
                    self?.collectionView.contentOffset = .zero
                })
            }*/
        }
    }
    let personalCounter = PersonalCounter()
    weak var referrals: Referrals!
}

// MARK: - CollectionView Data Source

extension HomepageViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        guard let sectionViewModel = viewModel.getSectionViewModel(shownSection: indexPath.section)
        else { return UICollectionReusableView() }

        // tooltip for impact
        if sectionViewModel.sectionType == .impact, let text = viewModel.ntpLayoutHighlightText(), kind == UICollectionView.elementKindSectionHeader {
            let tooltip = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NTPTooltip.key, for: indexPath) as! NTPTooltip
            tooltip.setText(text)
            tooltip.delegate = self
            return tooltip
        }

        // footer for news
        if sectionViewModel.sectionType == .news, kind == UICollectionView.elementKindSectionFooter  {
            let moreButton = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: MoreButtonCell.cellIdentifier, for: indexPath) as! MoreButtonCell
            moreButton.button.setTitle(.localized(.seeMoreNews), for: .normal)
            moreButton.button.addTarget(self, action: #selector(allNews), for: .primaryActionTriggered)
            moreButton.applyTheme()
            return moreButton
        }

        guard let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: LabelButtonHeaderView.cellIdentifier,
                for: indexPath) as? LabelButtonHeaderView
        else { return UICollectionReusableView() }

        // Configure header only if section is shown
        let headerViewModel = sectionViewModel.shouldShow ? sectionViewModel.headerViewModel : LabelButtonHeaderViewModel.emptyHeader
        headerView.configure(viewModel: headerViewModel)
        return headerView
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.shownSections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.getSectionViewModel(shownSection: section)?.numberOfItemsInSection() ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let viewModel = viewModel.getSectionViewModel(shownSection: indexPath.section) as? HomepageSectionHandler else {
            return UICollectionViewCell()
        }

        return viewModel.configure(collectionView, at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? NotificationThemeable)?.applyTheme()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewModel = viewModel.getSectionViewModel(shownSection: indexPath.section) as? HomepageSectionHandler else { return }
        viewModel.didSelectItem(at: indexPath, homePanelDelegate: homePanelDelegate, libraryPanelDelegate: libraryPanelDelegate)
    }
}

// MARK: - Actions Handling

private extension HomepageViewController {

    // Setup all the tap and long press actions on cells in each sections
    private func setupSectionsAction() {

        viewModel.topSiteViewModel.tilePressedHandler = { [weak self] site, isGoogle in
            guard let url = site.url.asURL else { return }
            self?.showSiteWithURLHandler(url, isGoogleTopSite: isGoogle)
        }

        viewModel.topSiteViewModel.tileLongPressedHandler = { [weak self] (site, sourceView) in
            self?.contextMenuHelper.presentContextMenu(for: site, with: sourceView, sectionType: .topSites)
        }

        viewModel.libraryViewModel.delegate = self
    }

    func openTabTray(_ sender: UIButton) {
        homePanelDelegate?.homePanelDidRequestToOpenTabTray(withFocusedTab: nil)

        if sender.accessibilityIdentifier == a11y.MoreButtons.jumpBackIn {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .jumpBackInSectionShowAll,
                                         extras: TelemetryWrapper.getOriginExtras(isZeroSearch: viewModel.isZeroSearch))
        }
    }

    func openBookmarks(_ sender: UIButton) {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .bookmarks)

        if sender.accessibilityIdentifier == a11y.MoreButtons.recentlySaved {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .recentlySavedSectionShowAll,
                                         extras: TelemetryWrapper.getOriginExtras(isZeroSearch: viewModel.isZeroSearch))
        }
    }

    func openHistory(_ sender: UIButton) {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .history)

        if sender.accessibilityIdentifier == a11y.MoreButtons.historyHighlights {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .historyHighlightsShowAll)

        }
    }

    func openTabsSettings() {
        homePanelDelegate?.homePanelDidRequestToOpenSettings(at: .customizeTabs)
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
extension HomepageViewController: HomepageContextMenuHelperDelegate {
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool, selectNewTab: Bool) {
        homePanelDelegate?.homePanelDidRequestToOpenInNewTab(url, isPrivate: isPrivate, selectNewTab: selectNewTab)
    }

    func homePanelDidRequestToOpenSettings(at settingsPage: AppSettingsDeeplinkOption) {
        homePanelDelegate?.homePanelDidRequestToOpenSettings(at: settingsPage)
    }
}

// MARK: - Popover Presentation Delegate

extension HomepageViewController: UIPopoverPresentationControllerDelegate {

    // Dismiss the popover if the device is being rotated.
    // This is used by the Share UIActivityViewController action sheet on iPad
    func popoverPresentationController(
        _ popoverPresentationController: UIPopoverPresentationController,
        willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>,
        in view: AutoreleasingUnsafeMutablePointer<UIView>
    ) {
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
extension HomepageViewController: HomepageViewModelDelegate {
    func reloadView() {
        ensureMainThread { [weak self] in
            // If the view controller is not visible ignore updates
            guard let self = self
            else { return }

            self.viewModel.refreshData(for: self.traitCollection)
            self.collectionView.reloadData()
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
}

// MARK: - Notifiable
extension HomepageViewController: Notifiable {
    func handleNotifications(_ notification: Notification) {
        ensureMainThread { [weak self] in
            guard let self = self else { return }

            switch notification.name {
            case .TabsPrivacyModeChanged:
                self.adjustPrivacySensitiveSections(notification: notification)

            case .HomePanelPrefsChanged:
                self.reloadView()

            default: break
            }
        }
    }
}
