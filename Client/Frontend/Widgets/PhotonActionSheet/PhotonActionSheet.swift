/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import SnapKit
import Shared

// This file is main table view used for the action sheet

class PhotonActionSheet: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, Themeable {
    fileprivate(set) var actions: [[PhotonActionSheetItem]]

    private var site: Site?
    private let style: PresentationStyle
    private var tintColor = UIColor.theme.actionMenu.foreground
    private var heightConstraint: Constraint?
    var tableView = UITableView(frame: .zero, style: .grouped)

    lazy var tapRecognizer: UITapGestureRecognizer = {
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(dismiss))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.cancelsTouchesInView = false
        tapRecognizer.delegate = self
        return tapRecognizer
    }()

    lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.CloseButtonTitle, for: .normal)
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

    init(site: Site, actions: [PhotonActionSheetItem], closeButtonTitle: String = Strings.CloseButtonTitle) {
        self.site = site
        self.actions = [actions]
        self.style = .centered
        super.init(nibName: nil, bundle: nil)
        self.closeButton.setTitle(closeButtonTitle, for: .normal)
    }

    init(title: String? = nil, actions: [[PhotonActionSheetItem]], closeButtonTitle: String = Strings.CloseButtonTitle, style presentationStyle: UIModalPresentationStyle? = nil) {
        self.actions = actions
        if let presentationStyle = presentationStyle {
            self.style = presentationStyle == .popover ? .popover : .bottom
        } else {
            self.style = .centered
        }
        super.init(nibName: nil, bundle: nil)
        self.title = title
        self.closeButton.setTitle(closeButtonTitle, for: .normal)

        self.tableView.estimatedRowHeight = PhotonActionSheetUX.RowHeight
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if style == .centered {
            applyBackgroundBlur()
            self.tintColor = UIConstants.SystemBlueColor
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

        if style == .bottom {
            self.view.addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.centerX.equalTo(self.view.snp.centerX)
                make.width.equalTo(width)
                make.height.equalTo(PhotonActionSheetUX.CloseButtonHeight)
                make.bottom.equalTo(self.view.safeArea.bottom).inset(PhotonActionSheetUX.Padding)
            }
        }

        if style == .popover {
            let width = UIDevice.current.userInterfaceIdiom == .pad ? 400 : 250
            tableView.snp.makeConstraints { make in
                make.top.bottom.equalTo(self.view)
                make.width.equalTo(width)
            }
        } else {
            tableView.snp.makeConstraints { make in
                make.centerX.equalTo(self.view.snp.centerX)
                switch style {
                case .bottom, .popover:
                    make.bottom.equalTo(closeButton.snp.top).offset(-PhotonActionSheetUX.Padding)
                case .centered:
                    make.centerY.equalTo(self.view.snp.centerY)
                }
                make.width.equalTo(width)
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(stopRotateSyncIcon), name: .ProfileDidFinishSyncing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopRotateSyncIcon), name: .ProfileDidStartSyncing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reduceTransparencyChanged), name: UIAccessibility.reduceTransparencyStatusDidChangeNotification, object: nil)
    }

    @objc func reduceTransparencyChanged() {
        // If the user toggles transparency settings, re-apply the theme to also toggle the blur effect.
        applyTheme()
    }

    func applyTheme() {
        if style == .popover {
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

        tintColor = UIColor.theme.actionMenu.foreground
        closeButton.backgroundColor = UIColor.theme.actionMenu.closeButtonBackground
        tableView.headerView(forSection: 0)?.backgroundColor = UIColor.Photon.DarkGrey05
        
        tableView.reloadData()
    }

    @objc func stopRotateSyncIcon() {
        ensureMainThread {
            self.tableView.reloadData()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tableView.removeObserver(self, forKeyPath: "contentSize")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

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
        if title != nil {
            tableView.separatorStyle = .none
        }
        tableView.separatorColor = UIColor.clear
        tableView.separatorInset = .zero
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.accessibilityIdentifier = "Context Menu"

        tableView.tableFooterView = UIView()

        applyTheme()

        DispatchQueue.main.async {
            // Pick up the correct/final tableview.contentsize in order to set the height.
            // Without async dispatch, the contentsize is wrong.
            self.view.setNeedsLayout()
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if style == .popover {
            self.preferredContentSize = tableView.contentSize
        }
    }
    
    // Nested tableview rows get additional height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let section = actions[safe: indexPath.section], let action = section[safe: indexPath.row] {
            if let custom = action.customHeight {
                return custom(action)
            }
        }

        return UITableView.automaticDimension
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var frameHeight: CGFloat
        frameHeight = view.safeAreaLayoutGuide.layoutFrame.size.height
        let maxHeight = frameHeight - (style == .bottom ? PhotonActionSheetUX.CloseButtonHeight : 0)
        tableView.snp.makeConstraints { make in
            heightConstraint?.deactivate()
            // The height of the menu should be no more than 85 percent of the screen
            heightConstraint = make.height.equalTo(min(self.tableView.contentSize.height, maxHeight * 0.90)).constraint
        }
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

    @objc func dismiss(_ gestureRecognizer: UIGestureRecognizer?) {
        self.dismiss(animated: true, completion: nil)
    }

    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if self.traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass
            || self.traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            updateViewConstraints()
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if tableView.frame.contains(touch.location(in: self.view)) {
            return false
        }
        return true
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return actions.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions[section].count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var action = actions[indexPath.section][indexPath.row]
        guard let handler = action.tapHandler else {
            self.dismiss(nil)
            return
        }
        
        // Switches can be toggled on/off without dismissing the menu
        if action.accessory == .Switch {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action.isEnabled = !action.isEnabled
            actions[indexPath.section][indexPath.row] = action
            self.tableView.deselectRow(at: indexPath, animated: true)
            self.tableView.reloadData()
        } else {
            action.isEnabled = !action.isEnabled
            self.dismiss(nil)
        }

        return handler(action, self.tableView(tableView, cellForRowAt: indexPath))
    }

    func tableView(_ tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: IndexPath) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PhotonActionSheetUX.CellName, for: indexPath) as! PhotonActionSheetCell
        let action = actions[indexPath.section][indexPath.row]
        cell.tintColor = self.tintColor
        cell.configure(with: action)
        
        // For menus other than ETP, don't show top and bottom separator lines
        if (title == nil) {
            cell.bottomBorder.isHidden = !(indexPath != [tableView.numberOfSections - 1, tableView.numberOfRows(inSection: tableView.numberOfSections - 1) - 1])
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
            if site != nil {
                return PhotonActionSheetUX.TitleHeaderSectionHeightWithSite
            } else if title != nil {
                return PhotonActionSheetUX.TitleHeaderSectionHeight
            } else {
                if #available(iOS 13.0, *) { return 0 } else { return 1 }
            }
        } else {
            if site != nil || title != nil {
                return PhotonActionSheetUX.SeparatorRowHeight
            }
        }

        return PhotonActionSheetUX.SeparatorRowHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let site = site {
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: PhotonActionSheetUX.SiteHeaderName) as! PhotonActionSheetSiteHeaderView
            header.tintColor = self.tintColor
            header.configure(with: site)
            return header
        } else if let title = title {
            if section > 0 {
                return tableView.dequeueReusableHeaderFooterView(withIdentifier: "SeparatorSectionHeader")
            } else {
                let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: PhotonActionSheetUX.TitleHeaderName) as! PhotonActionSheetTitleHeaderView
                header.tintColor = self.tintColor
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
