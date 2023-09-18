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

class TabTrayViewController: UIViewController, TabTrayController {
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol

    var openInNewTab: ((URL, Bool) -> Void)?
    var didSelectUrl: ((URL, Storage.VisitType) -> Void)?

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

    init(themeManager: ThemeManager = AppContainer.shared.resolve(),
         and notificationCenter: NotificationProtocol = NotificationCenter.default) {
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
    }

    func applyTheme() {
        view.backgroundColor = themeManager.currentTheme.colors.layer1
        navigationToolbar.barTintColor = themeManager.currentTheme.colors.layer1
    }

    private func setupView() {
        view.addSubview(navigationToolbar)
        navigationToolbar.setItems([UIBarButtonItem(customView: segmentedControl)], animated: false)

        NSLayoutConstraint.activate([
            navigationToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
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

    @objc
    private func segmentChanged() {
        segmentPanelChange()
    }

    private func segmentPanelChange() {}
}

extension TabTrayViewController: UIToolbarDelegate {}
