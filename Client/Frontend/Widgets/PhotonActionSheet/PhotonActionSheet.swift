// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Storage
import Shared
import UIKit

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
class PhotonActionSheet: UIViewController {

    struct UX {
        static let MaxWidth: CGFloat = 414
        static let Padding: CGFloat = 6
        static let RowHeight: CGFloat = 44
        static let BorderWidth: CGFloat = 0.5
        static let BorderColor = UIColor.Photon.Grey30
        static let CornerRadius: CGFloat = 10
        static let SiteImageViewSize = 52
        static let IconSize = CGSize(width: 24, height: 24)
        static let SiteHeaderName  = "PhotonActionSheetSiteHeaderView"
        static let TitleHeaderName = "PhotonActionSheetTitleHeaderView"
        static let CellName = "PhotonActionSheetCell"
        static let LineSeparatorSectionHeader = "LineSeparatorSectionHeader"
        static let SeparatorSectionHeader = "SeparatorSectionHeader"
        static let EmptyHeader = "EmptyHeader"
        static let CloseButtonHeight: CGFloat  = 56
        static let TablePadding: CGFloat = 6
        static let SeparatorRowHeight: CGFloat = 8
        static let TitleHeaderSectionHeight: CGFloat = 40
        static let TitleHeaderSectionHeightWithSite: CGFloat = 70
        static let BigSpacing: CGFloat = 32
        static let Spacing: CGFloat = 16
        static let SmallSpacing: CGFloat = 8
    }

    // MARK: - Variables
    private var tableView = UITableView(frame: .zero, style: .grouped)
    private var viewModel: PhotonActionSheetViewModel!
    private var constraints = [NSLayoutConstraint]()
    var notificationCenter: NotificationCenter = NotificationCenter.default

    private lazy var closeButton: UIButton = .build { button in
        button.setTitle(.CloseButtonTitle, for: .normal)
        button.setTitleColor(UIConstants.SystemBlueColor, for: .normal)
        button.layer.cornerRadius = UX.CornerRadius
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontExtraLargeBold
        button.addTarget(self, action: #selector(self.dismiss), for: .touchUpInside)
        button.accessibilityIdentifier = "PhotonMenu.close"
    }

    var photonTransitionDelegate: UIViewControllerTransitioningDelegate? {
        didSet {
            transitioningDelegate = photonTransitionDelegate
        }
    }

    // MARK: - Init

    init(viewModel: PhotonActionSheetViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        title = viewModel.title
        modalPresentationStyle = viewModel.modalStyle
        closeButton.setTitle(viewModel.closeButtonTitle, for: .normal)
        tableView.estimatedRowHeight = UX.RowHeight
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
        notificationCenter.removeObserver(self)
    }

    // MARK: - View cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        view.accessibilityIdentifier = "Action Sheet"

        tableView.backgroundColor = .clear
        tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        // In a popover the popover provides the blur background
        // Not using a background color allows the view to style correctly with the popover arrow
        if self.popoverPresentationController == nil {
            let blurEffect = UIBlurEffect(style: UIColor.theme.actionMenu.iPhoneBackgroundBlurStyle)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            tableView.backgroundView = blurEffectView
        }

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

        setupNotifications(forObserver: self, observing: [.ProfileDidFinishSyncing,
                                                          .ProfileDidStartSyncing,
                                                          UIAccessibility.reduceTransparencyStatusDidChangeNotification])
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
        tableView.register(PhotonActionSheetContainerCell.self, forCellReuseIdentifier: UX.CellName)
        tableView.register(PhotonActionSheetSiteHeaderView.self, forHeaderFooterViewReuseIdentifier: UX.SiteHeaderName)
        tableView.register(PhotonActionSheetTitleHeaderView.self, forHeaderFooterViewReuseIdentifier: UX.TitleHeaderName)
        tableView.register(PhotonActionSheetSeparator.self, forHeaderFooterViewReuseIdentifier: UX.SeparatorSectionHeader)
        tableView.register(PhotonActionSheetLineSeparator.self, forHeaderFooterViewReuseIdentifier: UX.LineSeparatorSectionHeader)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: UX.EmptyHeader)

        tableView.isScrollEnabled = true
        tableView.showsVerticalScrollIndicator = false
        tableView.layer.cornerRadius = UX.CornerRadius
        // Don't show separators on ETP menu
        if viewModel.title != nil {
            tableView.separatorStyle = .none
        }
        tableView.separatorColor = UIColor.clear
        tableView.separatorInset = .zero
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.accessibilityIdentifier = "Context Menu"
        tableView.translatesAutoresizingMaskIntoConstraints = false

        if viewModel.isMainMenuInverted {
            tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        }
        tableView.reloadData()

        DispatchQueue.main.async {
            // Pick up the correct/final tableview.contentsize in order to set the height.
            // Without async dispatch, the contentsize is wrong.
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

    private func setupBottomStyle() {
        self.view.addSubview(closeButton)

        let bottomConstraints = [
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: centeredAndBottomWidth),
            closeButton.heightAnchor.constraint(equalToConstant: UX.CloseButtonHeight),
            closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -UX.Padding),

            tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tableView.bottomAnchor.constraint(equalTo: closeButton.topAnchor, constant: -UX.Padding),
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
        if PhotonActionSheetViewModel.isSmallSizeForTraitCollection(trait: view.traitCollection) {
            tableViewConstraints.append(
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            )
        }

        constraints.append(contentsOf: tableViewConstraints)
    }

    private func setupCenteredStyle() {
        let tableViewConstraints = [
            tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tableView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            tableView.widthAnchor.constraint(equalToConstant: centeredAndBottomWidth),
        ]
        constraints.append(contentsOf: tableViewConstraints)

        applyBackgroundBlur()
        viewModel.tintColor = UIConstants.SystemBlueColor
    }

    // The width used for the .centered and .bottom style
    private var centeredAndBottomWidth: CGFloat {
        let minimumWidth = min(view.frame.size.width, UX.MaxWidth)
        return minimumWidth - (UX.Padding * 2)
    }

    // MARK: - Theme

    @objc func reduceTransparencyChanged() {
        // If the user toggles transparency settings, re-apply the theme to also toggle the blur effect.
        applyTheme()
    }

    private func applyBackgroundBlur() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        guard let screenshot = appDelegate.window?.screenshot() else { return }

        let blurredImage = screenshot.applyBlur(withRadius: 5,
                                                blurType: BOXFILTER,
                                                tintColor: UIColor.black.withAlphaComponent(0.2),
                                                saturationDeltaFactor: 1.8,
                                                maskImage: nil)
        let imageView = UIImageView(image: blurredImage)
        view.insertSubview(imageView, belowSubview: tableView)
    }

    // MARK: - Actions

    @objc private func stopRotateSyncIcon() {
        ensureMainThread {
            self.tableView.reloadData()
        }
    }

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        if viewModel.presentationStyle == .popover && !wasHeightOverriden {
            if #available(iOS 15.4, *) {
                var size = tableView.contentSize
                size.height = tableView.contentSize.height - UX.Spacing - UX.TablePadding
                preferredContentSize = size
            } else {
                preferredContentSize = tableView.contentSize
            }
        }
    }

    @objc private func dismiss(_ gestureRecognizer: UIGestureRecognizer?) {
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
    private var wasHeightOverriden = false

    /// Main menu table view height is calculated so if there's not enough space for the menu to be shown completely,
    /// we make sure that the last cell shown is half shown. This indicates to the user that the menu can be scrolled.
    private func setMainMenuTableViewHeight() {
        let visibleCellsHeight = getViewsHeightSum(views: tableView.visibleCells)
        let headerCellsHeight = getViewsHeightSum(views: tableView.visibleHeaders)

        let totalCellsHeight = visibleCellsHeight + headerCellsHeight
        let availableHeight = viewModel.availableMainMenuHeight
        let needsHeightAdjustment = availableHeight - totalCellsHeight < 0

        if needsHeightAdjustment && totalCellsHeight != 0 && !wasHeightOverriden {
            let newHeight: CGFloat
            if viewModel.isAtTopMainMenu {
                let halfCellHeight = (tableView.visibleCells.last?.frame.height ?? 0) / 2
                newHeight = totalCellsHeight - halfCellHeight
            } else {
                let halfCellHeight = (tableView.visibleCells.first?.frame.height ?? 0) / 2
                let aCellAndAHalfHeight = halfCellHeight * 3
                newHeight = totalCellsHeight - aCellAndAHalfHeight
            }

            wasHeightOverriden = true
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
        let buttonHeight = viewModel.presentationStyle == .bottom ? UX.CloseButtonHeight : 0
        let maxHeight = frameHeight - buttonHeight

        // The height of the menu should be no more than 90 percent of the screen
        let height = min(tableView.contentSize.height, maxHeight * 0.90)
        tableViewHeightConstraint?.constant = height
    }

    private func getViewsHeightSum(views: [UIView]) -> CGFloat {
        return views.map { $0.frame.height }.reduce(0, +)
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UX.CellName, for: indexPath) as? PhotonActionSheetContainerCell else { return UITableViewCell() }
        let actions = viewModel.actions[indexPath.section][indexPath.row]
        cell.configure(actions: actions, viewModel: viewModel)
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
        return viewModel.getViewHeader(tableView: tableView, section: section)
    }
}

// MARK: - PhotonActionSheetViewDelegate
extension PhotonActionSheet: PhotonActionSheetContainerCellDelegate {
    func didClick(item: SingleActionViewModel?) {
        dismissVC()
    }

    func layoutChanged(item: SingleActionViewModel) {
        tableView.reloadData()
    }
}

// MARK: - Visible Headers
extension UITableView {

    var visibleHeaders: [UITableViewHeaderFooterView] {
        var visibleHeaders = [UITableViewHeaderFooterView]()
        for sectionIndex in indexesOfVisibleHeaderSections {
            guard let sectionHeader = headerView(forSection: sectionIndex) else { continue }
            visibleHeaders.append(sectionHeader)
        }

        return visibleHeaders
    }

    private var indexesOfVisibleHeaderSections: [Int] {
        var visibleSectionIndexes = [Int]()

        (0..<numberOfSections).forEach { index in
            let headerRect = rect(forSection: index)

            // The "visible part" of the tableView is based on the content offset and the tableView's size.
            let visiblePartOfTableView = CGRect(x: contentOffset.x,
                                                y: contentOffset.y,
                                                width: bounds.size.width,
                                                height: bounds.size.height)

            if visiblePartOfTableView.intersects(headerRect) {
                visibleSectionIndexes.append(index)
            }
        }
        return visibleSectionIndexes
    }
}

// MARK: - NotificationThemeable
extension PhotonActionSheet: NotificationThemeable {

    func applyTheme() {
        if viewModel.presentationStyle == .popover {
            view.backgroundColor = UIColor.theme.browser.background.withAlphaComponent(0.7)
        } else {
            tableView.backgroundView?.backgroundColor = UIColor.theme.actionMenu.iPhoneBackground
        }

        // Apply or remove the background blur effect
        if let visualEffectView = tableView.backgroundView as? UIVisualEffectView {
            if UIAccessibility.isReduceTransparencyEnabled {
                // Remove the visual effect and the background alpha
                visualEffectView.effect = nil
                tableView.backgroundView?.backgroundColor = UIColor.theme.actionMenu.iPhoneBackground.withAlphaComponent(1.0)
            } else {
                visualEffectView.effect = UIBlurEffect(style: UIColor.theme.actionMenu.iPhoneBackgroundBlurStyle)
            }
        }

        viewModel.tintColor = UIColor.theme.actionMenu.foreground
        closeButton.backgroundColor = UIColor.theme.actionMenu.closeButtonBackground
        tableView.headerView(forSection: 0)?.backgroundColor = UIColor.Photon.DarkGrey05
    }
}
