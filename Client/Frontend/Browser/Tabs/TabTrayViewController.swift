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
            static let width: CGFloat = 32
        }
    }

    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    weak var  delegate: TabTrayViewControllerDelegate?

    var openInNewTab: ((URL, Bool) -> Void)?
    var didSelectUrl: ((URL, Storage.VisitType) -> Void)?

    var layout: LegacyTabTrayViewModel.Layout = .compact

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
        return shouldUseiPadSetup() ? LegacyTabTrayViewModel.Segment.allCases.map { $0.label } : iPhoneItems
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

    private lazy var newTabButtonIpad: UIBarButtonItem = {
        return createButtonItem(imageName: StandardImageIdentifiers.Large.plus,
                                action: #selector(newTabButtonTapped),
                                a11yId: AccessibilityIdentifiers.TabTray.newTabButton,
                                a11yLabel: .TabTrayAddTabAccessibilityLabel)
    }()

    private lazy var fixedSpace: UIBarButtonItem = {
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace,
                                         target: nil,
                                         action: nil)
        fixedSpace.width = CGFloat(UX.NavigationMenu.width)
        return fixedSpace
    }()

    private lazy var bottomToolbarItems: [UIBarButtonItem] = {
        return [deleteButton, flexibleSpace, newTabButton]
    }()

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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.didDismissTabTray()
    }

    // MARK: Themeable
    func applyTheme() {
        view.backgroundColor = themeManager.currentTheme.colors.layer1
        navigationToolbar.barTintColor = themeManager.currentTheme.colors.layer1
        deleteButton.tintColor = themeManager.currentTheme.colors.iconPrimary
        newTabButton.tintColor = themeManager.currentTheme.colors.iconPrimary
    }

    // MARK: Private
    private func setupView() {
        view.addSubview(navigationToolbar)
        navigationToolbar.setItems([UIBarButtonItem(customView: segmentedControl)], animated: false)

        NSLayoutConstraint.activate([
            navigationToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func updateToolbarItems() {
        switch layout {
        case .compact:
            navigationController?.isToolbarHidden = false
            setToolbarItems(bottomToolbarItems, animated: true)
        case .regular:
            navigationItem.rightBarButtonItems = [doneButton, fixedSpace, newTabButtonIpad]
            navigationItem.leftBarButtonItem = deleteButton
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
        segmentPanelChange()
    }

    @objc
    func deleteTabsButtonTapped() {}

    @objc
    func newTabButtonTapped() {}

    @objc
    func doneButtonTapped() {}
}
