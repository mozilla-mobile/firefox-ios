// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared
import UIKit
import Common

extension PhotonActionSheet: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .ProfileDidFinishSyncing, .ProfileDidStartSyncing:
            stopRotateSyncIcon()
        case UIAccessibility.reduceTransparencyStatusDidChangeNotification:
            reduceTransparencyChanged()
        default: break
        }
    }
}

// This file is main table view used for the action sheet
class PhotonActionSheet: UIViewController, Themeable {
    struct UX {
        static let maxWidth: CGFloat = 414
        static let padding: CGFloat = 6
        static let rowHeight: CGFloat = 44
        static let cornerRadius: CGFloat = 10
        static let iconSize = CGSize(width: 24, height: 24)
        static let closeButtonHeight: CGFloat  = 56
        static let tablePadding: CGFloat = 6
        static let separatorRowHeight: CGFloat = 8
        static let titleHeaderSectionHeight: CGFloat = 40
        static let bigSpacing: CGFloat = 32
        static let spacing: CGFloat = 16
        static let smallSpacing: CGFloat = 8
    }

    // MARK: - Variables
    private var tableView = UITableView(frame: .zero, style: .grouped)
    private var backgroundBlurView: UIVisualEffectView?
    let viewModel: PhotonActionSheetViewModel
    private var constraints = [NSLayoutConstraint]()
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    private lazy var closeButton: UIButton = .build { button in
        button.setTitle(.CloseButtonTitle, for: .normal)
        button.layer.cornerRadius = UX.cornerRadius
        button.titleLabel?.font = FXFontStyles.Bold.body.scaledFont()
        button.addTarget(self, action: #selector(self.dismiss), for: .touchUpInside)
        button.accessibilityIdentifier = AccessibilityIdentifiers.Photon.closeButton
    }

    var photonTransitionDelegate: UIViewControllerTransitioningDelegate? {
        didSet {
            transitioningDelegate = photonTransitionDelegate
        }
    }

    // MARK: - Init

    init(viewModel: PhotonActionSheetViewModel,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)

        title = viewModel.title
        modalPresentationStyle = viewModel.modalStyle
        closeButton.setTitle(viewModel.closeButtonTitle, for: .normal)
        tableView.estimatedRowHeight = UX.rowHeight
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0.0, height: .leastNonzeroMagnitude))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
        tableView.removeFromSuperview()
        notificationCenter.removeObserver(self)
    }

    // MARK: - View cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(view)
        view.addSubview(tableView)
        view.accessibilityIdentifier = AccessibilityIdentifiers.Photon.view

        tableView.backgroundColor = .clear
        tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)

        setupLayout()

        setupNotifications(
            forObserver: self,
            observing: [.ProfileDidFinishSyncing,
                        .ProfileDidStartSyncing,
                        UIAccessibility.reduceTransparencyStatusDidChangeNotification]
        )
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tableView.removeObserver(self, forKeyPath: "contentSize")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        applyTheme()

        tableView.bounces = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(PhotonActionSheetSeparator.self,
                           forHeaderFooterViewReuseIdentifier: PhotonActionSheetSeparator.cellIdentifier)
        tableView.register(PhotonActionSheetSiteHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: PhotonActionSheetSiteHeaderView.cellIdentifier)
        tableView.register(PhotonActionSheetTitleHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: PhotonActionSheetTitleHeaderView.cellIdentifier)
        tableView.register(PhotonActionSheetLineSeparator.self,
                           forHeaderFooterViewReuseIdentifier: PhotonActionSheetLineSeparator.cellIdentifier)
        tableView.register(PhotonActionSheetContainerCell.self,
                           forCellReuseIdentifier: PhotonActionSheetContainerCell.cellIdentifier)

        tableView.isScrollEnabled = true
        tableView.showsVerticalScrollIndicator = false
        tableView.layer.cornerRadius = UX.cornerRadius
        // Don't show separators on ETP menu
        if viewModel.title != nil {
            tableView.separatorStyle = .none
        }
        tableView.separatorColor = UIColor.clear
        tableView.separatorInset = .zero
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.accessibilityIdentifier = AccessibilityIdentifiers.Photon.tableView
        tableView.translatesAutoresizingMaskIntoConstraints = false

        if viewModel.isMainMenuInverted {
            tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        }
        tableView.reloadData()

        DispatchQueue.main.async {
            // Pick up the correct/final tableview.content size in order to set the height.
            // Without async dispatch, the content size is wrong.
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setTableViewHeight()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass
            || traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            updateViewConstraints()
        }
    }

    // MARK: - Setup

    private func setupLayout() {
        if viewModel.presentationStyle == .bottom {
            setupBottomStyle()
        } else if viewModel.presentationStyle == .popover {
            setupPopoverStyle()
        } else {
            setupCenteredStyle()
        }

        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableViewHeightConstraint?.isActive = true
        NSLayoutConstraint.activate(constraints)
    }

    private func setupBottomStyle() {
        self.view.addSubview(closeButton)

        let bottomConstraints = [
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: centeredAndBottomWidth),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonHeight),
            closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -UX.padding),

            tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tableView.bottomAnchor.constraint(equalTo: closeButton.topAnchor, constant: -UX.padding),
            tableView.widthAnchor.constraint(equalToConstant: centeredAndBottomWidth),
        ]
        constraints.append(contentsOf: bottomConstraints)
    }

    private func setupPopoverStyle() {
        let width: CGFloat = viewModel.popOverWidthForTraitCollection(trait: view.traitCollection)

        var tableViewConstraints = [
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.widthAnchor.constraint(greaterThanOrEqualToConstant: width),
        ]

        // Can't set this on iPad (not in multitasking) since it causes the menu to take all the width of the screen.
        tableViewConstraints.append(
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        )

        constraints.append(contentsOf: tableViewConstraints)
    }

    private func setupCenteredStyle() {
        let tableViewConstraints = [
            tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tableView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            tableView.widthAnchor.constraint(equalToConstant: centeredAndBottomWidth),
        ]
        constraints.append(contentsOf: tableViewConstraints)
    }

    private func setupBackgroundBlur() {
        guard backgroundBlurView == nil else { return }

        let blur = UIBlurEffect(style: .systemMaterialDark)
        let backgroundBlurView = IntensityVisualEffectView(effect: blur, intensity: 0.2)
        view.insertSubview(backgroundBlurView, belowSubview: tableView)
        backgroundBlurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundBlurView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundBlurView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.backgroundBlurView = backgroundBlurView
    }

    // The width used for the .centered and .bottom style
    private var centeredAndBottomWidth: CGFloat {
        let minimumWidth = min(view.frame.size.width, UX.maxWidth)
        return minimumWidth - (UX.padding * 2)
    }

    // MARK: - Theme

    @objc
    func reduceTransparencyChanged() {
        // If the user toggles transparency settings, re-apply the theme to also toggle the blur effect.
        applyTheme()
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)

        if viewModel.presentationStyle == .centered {
            setupBackgroundBlur()
        }

        // In a popover the popover provides the blur background
        if viewModel.presentationStyle == .popover {
            view.backgroundColor = theme.colors.layer1
        } else if UIAccessibility.isReduceTransparencyEnabled {
            backgroundBlurView?.alpha = 0.0

            // Remove the visual effect and the background alpha
            (tableView.backgroundView as? UIVisualEffectView)?.effect = nil
            tableView.backgroundView?.backgroundColor = theme.colors.layer1
            tableView.backgroundColor = theme.colors.layer1
        } else {
            backgroundBlurView?.alpha = 1.0

            tableView.backgroundColor = .clear
            let blurEffect = UIBlurEffect(style: .regular)

            if let visualEffectView = tableView.backgroundView as? UIVisualEffectView {
                visualEffectView.effect = blurEffect
            } else {
                let blurEffectView = UIVisualEffectView(effect: blurEffect)
                tableView.backgroundView = blurEffectView
            }
            tableView.backgroundView?.backgroundColor = theme.colors.layer1.withAlphaComponent(0.9)
        }

        closeButton.backgroundColor = theme.colors.layer1
        closeButton.setTitleColor(theme.colors.actionPrimary, for: .normal)
    }

    // MARK: - Actions

    @objc
    private func stopRotateSyncIcon() {
        ensureMainThread {
            self.tableView.reloadData()
        }
    }

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        if viewModel.presentationStyle == .popover && !wasHeightOverridden {
            let size = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            preferredContentSize = CGSize(width: size.width, height: tableView.contentSize.height)
        }
    }

    @objc
    private func dismiss(_ gestureRecognizer: UIGestureRecognizer?) {
        dismissVC()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        // Need to handle click outside view for non-popover sheet styles
        guard let touch = touches.first else { return }
        if !tableView.frame.contains(touch.location(in: view)) {
            dismissVC()
        }
    }

    // MARK: - TableView height

    private var tableViewHeightConstraint: NSLayoutConstraint?

    private func setTableViewHeight() {
        if viewModel.isMainMenu {
            setMainMenuTableViewHeight()
        } else {
            setDefaultStyleTableViewHeight()
        }
    }

    // Needed to override the preferredContentSize, so key value observer doesn't get called
    private var wasHeightOverridden = false

    /// Main menu table view height is calculated so if there's not enough space for the menu to be shown completely,
    /// we make sure that the last cell shown is half shown. This indicates to the user that the menu can be scrolled.
    private func setMainMenuTableViewHeight() {
        let visibleCellsHeight = getViewsHeightSum(views: tableView.visibleCells)
        let headerCellsHeight = getViewsHeightSum(views: visibleTableViewHeaders)

        let totalCellsHeight = visibleCellsHeight + headerCellsHeight
        let availableHeight = viewModel.availableMainMenuHeight
        let needsHeightAdjustment = availableHeight - totalCellsHeight < 0

        if needsHeightAdjustment && totalCellsHeight != 0 && !wasHeightOverridden {
            let newHeight: CGFloat
            if viewModel.isAtTopMainMenu {
                let halfCellHeight = (tableView.visibleCells.last?.frame.height ?? 0) / 2
                newHeight = totalCellsHeight - halfCellHeight
            } else {
                let halfCellHeight = (tableView.visibleCells.first?.frame.height ?? 0) / 2
                let aCellAndAHalfHeight = halfCellHeight * 3
                newHeight = totalCellsHeight - aCellAndAHalfHeight
            }

            wasHeightOverridden = true
            tableViewHeightConstraint?.constant = newHeight
            tableViewHeightConstraint?.priority = .required

            preferredContentSize = view.systemLayoutSizeFitting(
                UIView.layoutFittingCompressedSize
            )

            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }

    private func setDefaultStyleTableViewHeight() {
        let frameHeight = view.safeAreaLayoutGuide.layoutFrame.size.height
        let buttonHeight = viewModel.presentationStyle == .bottom ? UX.closeButtonHeight : 0
        let maxHeight = frameHeight - buttonHeight

        // The height of the menu should be no more than 90 percent of the screen
        let height = min(tableView.contentSize.height, maxHeight * 0.90)
        tableViewHeightConstraint?.constant = height
    }

    private func getViewsHeightSum(views: [UIView]) -> CGFloat {
        return views.map { $0.frame.height }.reduce(0, +)
    }

    private var visibleTableViewHeaders: [UITableViewHeaderFooterView] {
        var visibleHeaders = [UITableViewHeaderFooterView]()
        for sectionIndex in indexesOfVisibleHeaderSections {
            guard let sectionHeader = tableView.headerView(forSection: sectionIndex) else { continue }
            visibleHeaders.append(sectionHeader)
        }

        return visibleHeaders
    }

    private var indexesOfVisibleHeaderSections: [Int] {
        var visibleSectionIndexes = [Int]()

        (0..<tableView.numberOfSections).forEach { index in
            let headerRect = tableView.rect(forSection: index)

            // The "visible part" of the tableView is based on the content offset and the tableView's size.
            let visiblePartOfTableView = CGRect(x: tableView.contentOffset.x,
                                                y: tableView.contentOffset.y,
                                                width: tableView.bounds.size.width,
                                                height: tableView.bounds.size.height)

            if visiblePartOfTableView.intersects(headerRect) {
                visibleSectionIndexes.append(index)
            }
        }
        return visibleSectionIndexes
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension PhotonActionSheet: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = viewModel.actions[safe: indexPath.section],
              let action = section[safe: indexPath.row],
              let custom = action.items[0].customHeight
        else { return UITableView.automaticDimension }

        // Nested tableview rows get additional height
        return custom(action.items[0])
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.actions.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.actions[section].count
    }

    func tableView(_ tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: IndexPath) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: PhotonActionSheetContainerCell.cellIdentifier,
            for: indexPath) as? PhotonActionSheetContainerCell
        else { return UITableViewCell() }

        let actions = viewModel.actions[indexPath.section][indexPath.row]
        cell.configure(actions: actions, viewModel: viewModel, theme: themeManager.getCurrentTheme(for: windowUUID))
        cell.delegate = self

        if viewModel.isMainMenuInverted {
            let rowIsLastInSection = indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1
            cell.hideBottomBorder(isHidden: rowIsLastInSection)
        } else {
            let isLastRow = indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1
            cell.hideBottomBorder(isHidden: isLastRow)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return viewModel.getHeaderHeightForSection(section: section)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = viewModel.getViewHeader(tableView: tableView, section: section)
        (header as? ThemeApplicable)?.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        return header
    }
}

// MARK: - PhotonActionSheetViewDelegate
extension PhotonActionSheet: PhotonActionSheetContainerCellDelegate {
    func didClick(item: SingleActionViewModel?, animationCompletion: @escaping () -> Void) {
        dismissVC(withCompletion: animationCompletion)
    }
}
