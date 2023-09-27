// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Storage

protocol TabTrayController: UIViewController,
                            UIAdaptivePresentationControllerDelegate,
                            UIPopoverPresentationControllerDelegate,
                            Themeable {
    var openInNewTab: ((_ url: URL, _ isPrivate: Bool) -> Void)? { get set }
    var didSelectUrl: ((_ url: URL, _ visitType: VisitType) -> Void)? { get set }
}

class TabTrayViewController: UIViewController,
                             TabTrayController,
                             UIToolbarDelegate {
    struct UX {
        struct NavigationMenu {
            static let width: CGFloat = 343
        }

        static let fixedSpaceWidth: CGFloat = 32
    }

    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    weak var  delegate: TabTrayViewControllerDelegate?
    private var titleWidthConstraint: NSLayoutConstraint?

    var openInNewTab: ((URL, Bool) -> Void)?
    var didSelectUrl: ((URL, Storage.VisitType) -> Void)?

    // MARK: - Redux state
    lazy var layout: LegacyTabTrayViewModel.Layout = {
        return shouldUseiPadSetup() ? .regular : .compact
    }()

    var selectedSegment: LegacyTabTrayViewModel.Segment = .tabs

    var isSyncTabsPanel: Bool {
        return selectedSegment == .syncedTabs
    }

    var hasSyncableAccount: Bool {
        // Temporary. Added for early testing.
        // Eventually we will update this to use Redux state. -mr
        guard let profile = (UIApplication.shared.delegate as? AppDelegate)?.profile else { return false }
        return profile.hasSyncableAccount()
    }

    // iPad Layout
    var isRegularLayout: Bool {
        return layout == .regular
    }

    // MARK: - UI
    private lazy var navigationToolbar: UIToolbar = .build { [self] toolbar in
        toolbar.delegate = self
        toolbar.setItems([UIBarButtonItem(customView: segmentedControl)], animated: false)
        toolbar.isTranslucent = false
    }

    private lazy var segmentedControl: UISegmentedControl = {
        return createSegmentedControl(action: #selector(segmentChanged),
                                      a11yId: AccessibilityIdentifiers.TabTray.navBarSegmentedControl)
    }()

    lazy var countLabel: UILabel = {
        let label = UILabel(frame: CGRect(width: 24, height: 24))
        label.font = TabsButton.UX.titleFont
        label.layer.cornerRadius = TabsButton.UX.cornerRadius
        label.textAlignment = .center
        // TODO: Connect to regular tabs count
        label.text = "0"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var segmentControlItems: [Any] {
        let iPhoneItems = [
            LegacyTabTrayViewModel.Segment.tabs.image!.overlayWith(image: countLabel),
            LegacyTabTrayViewModel.Segment.privateTabs.image!,
            LegacyTabTrayViewModel.Segment.syncedTabs.image!]
        return isRegularLayout ? LegacyTabTrayViewModel.Segment.allCases.map { $0.label } : iPhoneItems
    }

    private lazy var deleteButton: UIBarButtonItem = {
        return createButtonItem(imageName: StandardImageIdentifiers.Large.delete,
                                action: #selector(deleteTabsButtonTapped),
                                a11yId: AccessibilityIdentifiers.TabTray.closeAllTabsButton,
                                a11yLabel: .AppMenu.Toolbar.TabTrayDeleteMenuButtonAccessibilityLabel)
    }()

    private lazy var newTabButton: UIBarButtonItem = {
        return createButtonItem(imageName: StandardImageIdentifiers.Large.plus,
                                action: #selector(newTabButtonTapped),
                                a11yId: AccessibilityIdentifiers.TabTray.newTabButton,
                                a11yLabel: .TabTrayAddTabAccessibilityLabel)
    }()

    private lazy var flexibleSpace: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                               target: nil,
                               action: nil)
    }()

    private lazy var doneButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .done,
                                     target: self,
                                     action: #selector(doneButtonTapped))
        button.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.doneButton
        return button
    }()

    private lazy var syncTabButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: .TabsTray.Sync.SyncTabs,
                                     style: .plain,
                                     target: self,
                                     action: #selector(syncTabsTapped))

        button.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.syncTabsButton
        return button
    }()

    private lazy var syncLoadingView: UIStackView = .build { [self] stackView in
        let syncingLabel = UILabel()
        syncingLabel.text = .SyncingMessageWithEllipsis
        syncingLabel.textColor = themeManager.currentTheme.colors.textPrimary

        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = themeManager.currentTheme.colors.textPrimary
        activityIndicator.startAnimating()

        stackView.addArrangedSubview(syncingLabel)
        stackView.addArrangedSubview(activityIndicator)
        stackView.spacing = 12
    }

    private lazy var fixedSpace: UIBarButtonItem = {
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace,
                                         target: nil,
                                         action: nil)
        fixedSpace.width = CGFloat(UX.fixedSpaceWidth)
        return fixedSpace
    }()

    private lazy var bottomToolbarItems: [UIBarButtonItem] = {
        return [deleteButton, flexibleSpace, newTabButton]
    }()

    private lazy var bottomToolbarItemsForSync: [UIBarButtonItem] = {
        guard hasSyncableAccount else { return [] }

        return [flexibleSpace, syncTabButton]
    }()

    private var rightBarButtonItemsForSync: [UIBarButtonItem] {
        if hasSyncableAccount {
            return [doneButton, fixedSpace, syncTabButton]
        } else {
            return [doneButton]
        }
    }

    init(delegate: TabTrayViewControllerDelegate,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         and notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.delegate = delegate
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter

        super.init(nibName: nil, bundle: nil)
        self.applyTheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        listenForThemeChange(view)
        updateToolbarItems()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateToolbarItems()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateLayout()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()

        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass
            || previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass {
            updateLayout()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.didDismissTabTray()
    }

    private func updateLayout() {
        navigationController?.isToolbarHidden = isRegularLayout
        titleWidthConstraint?.isActive = isRegularLayout

        switch layout {
        case .compact:
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItems = [doneButton]
            navigationItem.titleView = nil
        case .regular:
            navigationItem.titleView = segmentedControl
        }
        updateToolbarItems()
    }

    // MARK: Themeable
    func applyTheme() {
        view.backgroundColor = themeManager.currentTheme.colors.layer1
        navigationToolbar.barTintColor = themeManager.currentTheme.colors.layer1
        deleteButton.tintColor = themeManager.currentTheme.colors.iconPrimary
        newTabButton.tintColor = themeManager.currentTheme.colors.iconPrimary
        doneButton.tintColor = themeManager.currentTheme.colors.iconPrimary
        syncTabButton.tintColor = themeManager.currentTheme.colors.iconPrimary
    }

    // MARK: Private
    private func setupView() {
        // Should use Regular layout used for iPad
        guard isRegularLayout else {
            setupForiPhone()
            return
        }

        setupForiPad()
    }

    private func setupForiPhone() {
        navigationItem.titleView = nil
        updateTitle()
        view.addSubview(navigationToolbar)
        navigationToolbar.setItems([UIBarButtonItem(customView: segmentedControl)], animated: false)

        NSLayoutConstraint.activate([
            navigationToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func updateTitle() {
        navigationItem.title = selectedSegment.navTitle
    }

    private func setupForiPad() {
        navigationItem.titleView = segmentedControl

        if let titleView = navigationItem.titleView {
            titleWidthConstraint = titleView.widthAnchor.constraint(equalToConstant: UX.NavigationMenu.width)
            titleWidthConstraint?.isActive = true
        }
    }

    private func updateToolbarItems() {
        // if iPad
        guard !isRegularLayout else {
            setupToolbarForIpad()
            return
        }

        let toolbarItems = isSyncTabsPanel ? bottomToolbarItemsForSync : bottomToolbarItems
        setToolbarItems(toolbarItems, animated: true)
    }

    private func setupToolbarForIpad() {
        if isSyncTabsPanel {
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItems = rightBarButtonItemsForSync
        } else {
            navigationItem.leftBarButtonItem = deleteButton
            navigationItem.rightBarButtonItems = [doneButton, fixedSpace, newTabButton]
        }
    }

    private func createSegmentedControl(
        action: Selector,
        a11yId: String
    ) -> UISegmentedControl {
        let segmentedControl = UISegmentedControl(items: segmentControlItems)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = true
        segmentedControl.accessibilityIdentifier = a11yId

        let segmentToFocus = LegacyTabTrayViewModel.Segment.tabs
        segmentedControl.selectedSegmentIndex = segmentToFocus.rawValue
        segmentedControl.addTarget(self, action: action, for: .valueChanged)
        return segmentedControl
    }

    private func createButtonItem(imageName: String,
                                  action: Selector,
                                  a11yId: String,
                                  a11yLabel: String) -> UIBarButtonItem {
        let button = UIBarButtonItem(image: UIImage.templateImageNamed(imageName),
                                     style: .plain,
                                     target: self,
                                     action: action)
        button.accessibilityIdentifier = a11yId
        button.accessibilityLabel = a11yLabel
        return button
    }

    private func segmentPanelChange() {}

    @objc
    private func segmentChanged() {
        selectedSegment = LegacyTabTrayViewModel.Segment(rawValue: segmentedControl.selectedSegmentIndex) ?? .tabs
        updateTitle()
        updateLayout()
        segmentPanelChange()
    }

    @objc
    func deleteTabsButtonTapped() {}

    @objc
    func newTabButtonTapped() {}

    @objc
    func doneButtonTapped() {
        notificationCenter.post(name: .TabsTrayDidClose)
        // TODO: FXIOS-6928 Update mode when closing tabTray
        self.dismiss(animated: true, completion: nil)
    }

    @objc
    func syncTabsTapped() {}
}
