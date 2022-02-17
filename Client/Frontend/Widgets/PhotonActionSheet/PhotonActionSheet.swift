// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Storage
import SnapKit
import Shared
import UIKit

class PhotonActionSheetViewModel {

    var actions: [[PhotonActionSheetItem]]
    var modalStyle: UIModalPresentationStyle

    var closeButtonTitle: String? = nil
    var site: Site? = nil
    var title: String? = nil
    var tintColor = UIColor.theme.actionMenu.foreground

    var presentationStyle: PresentationStyle {
        return modalStyle.getPhotonPresentationStyle()
    }

    init(actions: [[PhotonActionSheetItem]],
         site: Site? = nil,
         modalStyle: UIModalPresentationStyle) {
        self.actions = actions
        self.site = site
        self.modalStyle = modalStyle
    }

    init(actions: [[PhotonActionSheetItem]],
         closeButtonTitle: String? = nil,
         title: String? = nil,
         modalStyle: UIModalPresentationStyle,
         toolbarMenuInversed: Bool = false) {

        self.actions = actions
        self.closeButtonTitle = closeButtonTitle
        self.title = title
        self.modalStyle = modalStyle

        self.toolbarMenuInversed = toolbarMenuInversed
        setToolbarMenuStyle()
    }

    // TODO: Laurie - explanation of what this is
    var toolbarMenuInversed: Bool = false
    func setToolbarMenuStyle() {
        guard toolbarMenuInversed else { return }

        // Inverse database
        actions = actions.map { $0.reversed() }
        actions.reverse()

        // Flip cells
        actions.forEach { $0.forEach { $0.isFlipped = true } }
    }
}

// TODO: Laurie - Put logic from action sheet here

// TODO: Laurie - Test on iPad
// TODO: Laurie - Test all photon action sheet are properly setup

// This file is main table view used for the action sheet
class PhotonActionSheet: UIViewController, UIGestureRecognizerDelegate, NotificationThemeable {

    // MARK: - Variables
    private var heightConstraint: Constraint?
    private var tableView = UITableView(frame: .zero, style: .grouped)
    private var viewModel: PhotonActionSheetViewModel!

    private lazy var tapRecognizer: UITapGestureRecognizer = {
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(dismiss))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.cancelsTouchesInView = false
        tapRecognizer.delegate = self
        return tapRecognizer
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setTitle(.CloseButtonTitle, for: .normal)
        button.setTitleColor(UIConstants.SystemBlueColor, for: .normal)
        button.layer.cornerRadius = PhotonActionSheetUX.CornerRadius
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontExtraLargeBold
        button.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        button.accessibilityIdentifier = "PhotonMenu.close"
        return button
    }()

    var photonTransitionDelegate: UIViewControllerTransitioningDelegate? {
        didSet {
            self.transitioningDelegate = photonTransitionDelegate
        }
    }

    // MARK: - Init

    init(viewModel: PhotonActionSheetViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        title = viewModel.title
        modalPresentationStyle = viewModel.modalStyle
        closeButton.setTitle(viewModel.closeButtonTitle, for: .normal)
        tableView.estimatedRowHeight = PhotonActionSheetUX.RowHeight
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - View cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        if viewModel.presentationStyle == .centered {
            applyBackgroundBlur()
            viewModel.tintColor = UIConstants.SystemBlueColor
        }

        view.addGestureRecognizer(tapRecognizer)
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
        
        let width = min(self.view.frame.size.width, PhotonActionSheetUX.MaxWidth) - (PhotonActionSheetUX.Padding * 2)

        if viewModel.presentationStyle == .bottom {
            self.view.addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.centerX.equalTo(view.snp.centerX)
                make.width.equalTo(width)
                make.height.equalTo(PhotonActionSheetUX.CloseButtonHeight)
                make.bottom.equalTo(view.safeArea.bottom).inset(PhotonActionSheetUX.Padding)
            }
        }

        if viewModel.presentationStyle == .popover {
            // TODO: Laurie - Change width for toolbarMenu
            let width = UIDevice.current.userInterfaceIdiom == .pad ? 400 : 250
            tableView.snp.makeConstraints { make in
                make.top.bottom.equalTo(view)
                make.width.equalTo(width)
            }

        } else {
            tableView.snp.makeConstraints { make in
                make.centerX.equalTo(view.snp.centerX)
                switch viewModel.presentationStyle {
                case .bottom, .popover:
                    make.bottom.equalTo(closeButton.snp.top).offset(-PhotonActionSheetUX.Padding)
                case .centered:
                    make.centerY.equalTo(view.snp.centerY)
                }
                make.width.equalTo(width)
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(stopRotateSyncIcon), name: .ProfileDidFinishSyncing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopRotateSyncIcon), name: .ProfileDidStartSyncing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reduceTransparencyChanged), name: UIAccessibility.reduceTransparencyStatusDidChangeNotification, object: nil)
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
        tableView.register(PhotonActionSheetCell.self, forCellReuseIdentifier: PhotonActionSheetUX.CellName)
        tableView.register(PhotonActionSheetSiteHeaderView.self, forHeaderFooterViewReuseIdentifier: PhotonActionSheetUX.SiteHeaderName)
        tableView.register(PhotonActionSheetTitleHeaderView.self, forHeaderFooterViewReuseIdentifier: PhotonActionSheetUX.TitleHeaderName)
        tableView.register(PhotonActionSheetSeparator.self, forHeaderFooterViewReuseIdentifier: "SeparatorSectionHeader")
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "EmptyHeader")

        tableView.isScrollEnabled = true
        tableView.showsVerticalScrollIndicator = false
        tableView.layer.cornerRadius = PhotonActionSheetUX.CornerRadius
        // Don't show separators on ETP menu
        if viewModel.title != nil {
            tableView.separatorStyle = .none
        }
        tableView.separatorColor = UIColor.clear
        tableView.separatorInset = .zero
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.accessibilityIdentifier = "Context Menu"

        if viewModel.toolbarMenuInversed {
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

        var frameHeight: CGFloat
        frameHeight = view.safeAreaLayoutGuide.layoutFrame.size.height
        let buttonHeight = viewModel.presentationStyle == .bottom ? PhotonActionSheetUX.CloseButtonHeight : 0
        let maxHeight = frameHeight - buttonHeight
        tableView.snp.makeConstraints { make in
            heightConstraint?.deactivate()
            // The height of the menu should be no more than 90 percent of the screen
            heightConstraint = make.height.equalTo(min(self.tableView.contentSize.height, maxHeight * 0.90)).constraint
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if self.traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass
            || self.traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            updateViewConstraints()
        }
    }

    // MARK: - Theme

    @objc func reduceTransparencyChanged() {
        // If the user toggles transparency settings, re-apply the theme to also toggle the blur effect.
        applyTheme()
    }

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

    private func applyBackgroundBlur() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let screenshot = appDelegate.window?.screenshot() {
            let blurredImage = screenshot.applyBlur(withRadius: 5,
                                                    blurType: BOXFILTER,
                                                    tintColor: UIColor.black.withAlphaComponent(0.2),
                                                    saturationDeltaFactor: 1.8,
                                                    maskImage: nil)
            let imageView = UIImageView(image: blurredImage)
            view.addSubview(imageView)
        }
    }

    // MARK: - Actions

    @objc func dismiss(_ gestureRecognizer: UIGestureRecognizer?) {
        dismiss(animated: true, completion: nil)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if tableView.frame.contains(touch.location(in: self.view)) {
            return false
        }
        return true
    }

    @objc func stopRotateSyncIcon() {
        ensureMainThread {
            self.tableView.reloadData()
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if viewModel.presentationStyle == .popover {
            self.preferredContentSize = tableView.contentSize
        }
    }
}

// MARK: - UITableViewDelegate
extension PhotonActionSheet: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let action = viewModel.actions[indexPath.section][indexPath.row]
        guard let handler = action.tapHandler else {
            self.dismiss(nil)
            return
        }

        // Switches can be toggled on/off without dismissing the menu
        if action.accessory == .Switch {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action.isEnabled = !action.isEnabled
            viewModel.actions[indexPath.section][indexPath.row] = action
            self.tableView.deselectRow(at: indexPath, animated: true)
            self.tableView.reloadData()
        } else {
            action.isEnabled = !action.isEnabled
            self.dismiss(nil)
        }

        return handler(action, self.tableView(tableView, cellForRowAt: indexPath))
    }
}

// MARK: - UITableViewDataSource
extension PhotonActionSheet: UITableViewDataSource {
    // Nested tableview rows get additional height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let section = viewModel.actions[safe: indexPath.section], let action = section[safe: indexPath.row] {
            if let custom = action.customHeight {
                return custom(action)
            }
        }

        return UITableView.automaticDimension
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
        let cell = tableView.dequeueReusableCell(withIdentifier: PhotonActionSheetUX.CellName, for: indexPath) as! PhotonActionSheetCell
        let action = viewModel.actions[indexPath.section][indexPath.row]
        cell.tintColor = viewModel.tintColor
        cell.configure(with: action)

        // TODO: Laurie - Test this on all sheets again
        // Hide separator line when needed
        if viewModel.toolbarMenuInversed {
            let rowIsFirst = indexPath.row == 0 && indexPath.section == 0
            cell.bottomBorder.isHidden = rowIsFirst

        } else if viewModel.modalStyle == .popover {
            let isLastRow = indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1
            let isLastSection = indexPath.section == tableView.numberOfSections - 1
            let rowIsLast = isLastRow && isLastSection

            cell.bottomBorder.isHidden = rowIsLast
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
        if section == 0 {
            if viewModel.site != nil {
                return PhotonActionSheetUX.TitleHeaderSectionHeightWithSite
            } else if viewModel.title != nil {
                return PhotonActionSheetUX.TitleHeaderSectionHeight
            } else {
                return 0
            }
        } else {
            if viewModel.site != nil || viewModel.title != nil {
                return PhotonActionSheetUX.SeparatorRowHeight
            }
        }

        return PhotonActionSheetUX.SeparatorRowHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let site = viewModel.site {
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: PhotonActionSheetUX.SiteHeaderName) as! PhotonActionSheetSiteHeaderView
            header.tintColor = viewModel.tintColor
            header.configure(with: site)
            return header
        } else if let title = viewModel.title {
            if section > 0 {
                return tableView.dequeueReusableHeaderFooterView(withIdentifier: "SeparatorSectionHeader")
            } else {
                let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: PhotonActionSheetUX.TitleHeaderName) as! PhotonActionSheetTitleHeaderView
                header.tintColor = viewModel.tintColor
                header.configure(with: title)
                return header
            }
        }
        else {
            let view = UIView()
            view.backgroundColor = UIColor.theme.tableView.separator
            return view
        }
    }
}
