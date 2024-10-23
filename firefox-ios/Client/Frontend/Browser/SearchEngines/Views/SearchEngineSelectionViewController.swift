// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared
import Redux

struct ImageLabelRowData: ElementData {
    // FIXME Pass image later
    var testPlaceholderImage: UIImage = UIImage(named: "globeLarge")!.withRenderingMode(.alwaysTemplate)
    var titleLabel: String
}

struct SearchEngineSection: SectionData {
    typealias E = ImageLabelRowData

    var elementData: [ImageLabelRowData]
}

class SearchEngineSelectionCell: UITableViewCell, ConfigurableTableViewCell {
//    typealias E = SearchEngineData

    // MARK: - Initializers
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.backgroundColor = .green
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme(theme: any Common.Theme) {
        // TODO apply theme
    }

    func configureCellWith(model: ImageLabelRowData) {
        // TODO set label and image
    }
}

class SearchEngineSelectionViewController: UIViewController,
                                           UISheetPresentationControllerDelegate,
                                           UIPopoverPresentationControllerDelegate,
                                           Themeable,
                                           GeneralTableViewDataDelegate {
    typealias S = SearchEngineSection // For GeneralTableViewDataDelegate conformance

    // MARK: - Properties
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var currentWindowUUID: UUID? { return windowUUID }

    weak var coordinator: SearchEngineSelectionCoordinator?
    private let windowUUID: WindowUUID
    private let logger: Logger

    // MARK: - UI/UX elements
    private var tableView: GeneralTableView<
        SearchEngineSection,
            SearchEngineSelectionCell,
            SearchEngineSelectionViewController
    > = .build()

    // MARK: - Initializers and Lifecycle

    init(
        windowUUID: WindowUUID,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.logger = logger
        super.init(nibName: nil, bundle: nil)

        tableView.delegate = self

        // TODO Additional setup to come
        // ...
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        sheetPresentationController?.delegate = self // For non-iPad setup
        popoverPresentationController?.delegate = self // For iPad setup

        setupView()
        listenForThemeChange(view)

        let fakeData: [SearchEngineSection] = [
            SearchEngineSection(elementData: [
                ImageLabelRowData(titleLabel: "Search engine 1"),
                ImageLabelRowData(titleLabel: "Search engine 2"),
                ImageLabelRowData(titleLabel: "Search engine 3")
            ]),
            SearchEngineSection(elementData: [
                ImageLabelRowData(titleLabel: "Search Settings")
            ])
        ]
        tableView.reloadTableView(with: fakeData)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        applyTheme()
    }

    // MARK: - UI / UX

    private func setupView() {
        view.addSubviews(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

//        view.addSubview(placeholderOpenSettingsButton)
//
//        NSLayoutConstraint.activate([
//            placeholderOpenSettingsButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 80),
//            placeholderOpenSettingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            placeholderOpenSettingsButton.widthAnchor.constraint(equalToConstant: 200)
//        ])
    }

    // MARK: - Theme

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)

        view.backgroundColor = theme.colors.layer3
    }

    // MARK: - UISheetPresentationControllerDelegate inheriting UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        coordinator?.dismissModal(animated: true)
    }

    // MARK: - Navigation

    @objc
    func didTapOpenSettings(sender: UIButton) {
        coordinator?.navigateToSearchSettings(animated: true)
    }

    // MARK: - GeneralTableViewDataDelegate

    func didSelectRowAt(indexPath: IndexPath, withModel: ImageLabelRowData) {
        // TODO
        print("** didSelectRowAt \(indexPath)")
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView, inScrollViewWithTopPadding topPadding: CGFloat) {
        // TODO
        print("** scrollViewDidScroll \(scrollView.contentOffset.y)")
    }
}
