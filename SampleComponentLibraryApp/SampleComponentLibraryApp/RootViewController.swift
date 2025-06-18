// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ToolbarKit
import WebKit
import ComponentLibrary

class RootViewController: UIViewController, AddressToolbarDelegate, Presenter, Themeable {
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Properties
    private let dataSource = ComponentDataSource()
    private let componentDelegate: ComponentDelegate

    private lazy var tableView: UITableView = .build { tableView in
        tableView.register(ComponentCell.self, forCellReuseIdentifier: ComponentCell.cellIdentifier)
        tableView.separatorStyle = .none
    }
    private lazy var sampleWebView: WKWebView = .build()
    private lazy var toolbar = BrowserAddressToolbar()
    private lazy var toolbarEffectView: UIVisualEffectView = {
        let effect: UIVisualEffect
        if #available(iOS 26.0, *) {
            var glass = UIGlassEffect()
            glass.isInteractive = false
            effect = glass
        } else {
            effect = UIBlurEffect(style: .systemUltraThinMaterial)
        }
        let view = UIVisualEffectView(effect: effect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private lazy var toolbarContainerView: UIView = .build()

    // MARK: - Init
    init(themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.themeManager = themeManager
        componentDelegate = ComponentDelegate(componentData: dataSource.componentData)
        super.init(nibName: nil, bundle: nil)

        componentDelegate.presenter = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()

        listenForThemeChange(view)
        applyTheme()
    }

    private func setupTableView() {
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        view.addSubview(sampleWebView)
        sampleWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sampleWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sampleWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sampleWebView.topAnchor.constraint(equalTo: view.topAnchor),
            sampleWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        sampleWebView.load(URLRequest(url: URL(string: "https://www.cnn.com")!))

        tableView.dataSource = dataSource
        tableView.delegate = componentDelegate
        tableView.reloadData()

        toolbar.configure(
            config: AddressToolbarConfiguration(
                locationViewConfiguration: LocationViewConfiguration(
                    searchEngineImageViewA11yId: "",
                    searchEngineImageViewA11yLabel: "",
                    lockIconButtonA11yId: "",
                    lockIconButtonA11yLabel: "",
                    urlTextFieldPlaceholder: "",
                    urlTextFieldA11yId: "",
                    searchEngineImage: UIImage(systemName: "star.fill"),
                    lockIconImageName: nil,
                    lockIconNeedsTheming: false,
                    safeListedURLImageName: nil,
                    url: URL(string: "https://www.mozilla.com"),
                    droppableUrl: nil,
                    searchTerm: nil,
                    isEditing: false,
                    didStartTyping: false,
                    shouldShowKeyboard: false,
                    shouldSelectSearchTerm: false
                ),
                navigationActions: [],
                leadingPageActions: [],
                trailingPageActions: [],
                browserActions: [
                    ToolbarElement(
                        iconName: "logoFirefoxLarge",
                        isEnabled: true,
                        a11yLabel: "",
                        a11yHint: nil,
                        a11yId: "",
                        hasLongPressAction: false,
                        onSelected: nil
                    )
                ],
                borderPosition: nil,
                uxConfiguration: AddressToolbarUXConfiguration.default(backgroundAlpha: 0.5, shouldBlur: true),
                shouldAnimate: true
            ),
            toolbarPosition: .bottom,
            toolbarDelegate: self,
            leadingSpace: 10.0,
            trailingSpace: 10.0,
            isUnifiedSearchEnabled: false,
            animated: false
        )

        toolbar.translatesAutoresizingMaskIntoConstraints = false

        toolbarContainerView.backgroundColor = .clear
        toolbarEffectView.layer.cornerRadius = 24.0
        toolbarContainerView.addSubview(toolbarEffectView)
        toolbarContainerView.addSubview(toolbar)
        toolbarEffectView.pinToSuperview()
        toolbar.pinToSuperview()

        view.addSubview(toolbarContainerView)
        NSLayoutConstraint.activate([
            toolbarContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26.0),
            toolbarContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26.0),
            toolbarContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -26.0),
            toolbarContainerView.heightAnchor.constraint(equalToConstant: 65.0)
        ])
    }

    // MARK: Themeable

    func applyTheme() {
        tableView.backgroundColor = .clear
        dataSource.theme = themeManager.currentTheme
        view.backgroundColor = themeManager.currentTheme.colors.layer1
    }

    // MARK: - AddressToolbarDelegate

    func searchSuggestions(searchTerm: String) {
    }

    func didClearSearch() {
    }

    func openBrowser(searchTerm: String) {
    }

    func addressToolbarDidBeginEditing(searchTerm: String, shouldShowSuggestions: Bool) {
    }

    func addressToolbarAccessibilityActions() -> [UIAccessibilityCustomAction]? {
        return nil
    }

    func configureContextualHint(
        _ addressToolbar: ToolbarKit.BrowserAddressToolbar,
        for button: UIButton,
        with contextualHintType: String
    ) {
    }

    func addressToolbarDidBeginDragInteraction() {
    }

    func addressToolbarDidProvideItemsForDragInteraction() {
    }

    func addressToolbarDidTapSearchEngine(_ searchEngineView: UIView) {
    }

    func addressToolbarNeedsSearchReset() {
    }
}
