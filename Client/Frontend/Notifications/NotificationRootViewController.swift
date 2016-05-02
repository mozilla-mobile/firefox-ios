/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import Shared

/// This view controller wraps around the main UINavigationController of our app that holds the Browser/Tab Tray.
/// It allows us to display notifications/toasts in the top area of the screen while pushing away the status
/// bar to indicate sync status globally.
class NotificationRootViewController: UIViewController {
    private var rootViewController: UIViewController

    private let notificationCenter = NSNotificationCenter.defaultCenter()
    private var statusBarHidden = false
    private var showingNotification = false

    private lazy var notificationView: NotificationStatusView = {
        let view = NotificationStatusView()
        view.hidden = true
        return view
    }()

    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
        super.init(nibName: nil, bundle: nil)

        notificationCenter.addObserver(self, selector: #selector(NotificationRootViewController.didStartSyncing), name: NotificationProfileDidStartSyncing, object: nil)
        notificationCenter.addObserver(self, selector: #selector(NotificationRootViewController.didFinishSyncing), name: NotificationProfileDidFinishSyncing, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self, name: NotificationProfileDidStartSyncing, object: nil)
        notificationCenter.removeObserver(self, name: NotificationProfileDidFinishSyncing, object: nil)
    }
}

// MARK: - View Controller Overrides
extension NotificationRootViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        addChildViewController(rootViewController)
        view.addSubview(rootViewController.view)
        rootViewController.didMoveToParentViewController(self)

        view.addSubview(notificationView)

        remakeConstraintsForHiddenNotification()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        showingNotification ? remakeConstraintsForVisibleNotification() : remakeConstraintsForHiddenNotification()
        view.setNeedsUpdateConstraints()
    }

    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        coordinator.animateAlongsideTransition({ _ in
            self.setNeedsStatusBarAppearanceUpdate()
        }, completion: nil)
    }

    override func prefersStatusBarHidden() -> Bool {
        // Always hide status bar when in landscape iPhone
        if traitCollection.horizontalSizeClass == .Compact && traitCollection.verticalSizeClass == .Compact {
            return true
        }
        return statusBarHidden
    }

    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

// MARK: - Notification API
extension NotificationRootViewController {
    func showStatusNotification() {
        assert(NSThread.isMainThread(), "Showing notifications must occur on the UI Thread.")
        self.statusBarHidden = true
        self.notificationView.hidden = false
        self.notificationView.alpha = 0
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(0.33) {
            self.remakeConstraintsForVisibleNotification()
            self.notificationView.alpha = 1
            self.setNeedsStatusBarAppearanceUpdate()
            self.view.setNeedsUpdateConstraints()
            self.view.layoutIfNeeded()
        }
    }

    func hideStatusNotification() {
        assert(NSThread.isMainThread(), "Hiding notifications must occur on the UI Thread.")
        self.statusBarHidden = false
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(0.33, animations: {
            self.remakeConstraintsForHiddenNotification()
            self.notificationView.alpha = 0
            self.setNeedsStatusBarAppearanceUpdate()
            self.view.setNeedsUpdateConstraints()
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.notificationView.hidden = true
        })
    }
}

// MARK: - Layout Constraints
private extension NotificationRootViewController {
    func remakeConstraintsForVisibleNotification() {
        self.notificationView.snp_remakeConstraints { make in
            make.height.equalTo(20)
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.snp_topLayoutGuideBottom)
        }

        self.rootViewController.view.snp_remakeConstraints { make in
            make.bottom.left.right.equalTo(self.view)
            make.top.equalTo(self.notificationView.snp_bottom)
        }
    }

    func remakeConstraintsForHiddenNotification() {
        self.notificationView.snp_remakeConstraints { make in
            make.height.equalTo(20)
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.snp_topLayoutGuideTop)
        }

        self.rootViewController.view.snp_remakeConstraints { make in
            make.bottom.left.right.equalTo(self.view)
            make.top.equalTo(self.snp_topLayoutGuideBottom)
        }
    }
}

// MARK: - Notification Selectors
private extension NotificationRootViewController {
    @objc func didStartSyncing() {
        showingNotification = true
        notificationView.titleLabel.text = Strings.SyncingMessage
        dispatch_async(dispatch_get_main_queue()) {
            self.showStatusNotification()
        }
    }

    @objc func didFinishSyncing() {
        showingNotification = false
        dispatch_async(dispatch_get_main_queue()) {
            self.hideStatusNotification()
        }
    }
}

// MARK: Notification Status View
private class NotificationStatusView: UIView {
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .whiteColor()
        label.font = UIConstants.DefaultChromeSmallFontBold
        return label
    }()

    init() {
        super.init(frame: CGRect.zero)
        backgroundColor = UIConstants.AppBackgroundColor
        addSubview(titleLabel)
        titleLabel.snp_makeConstraints { make in
            make.center.equalTo(self)
            make.width.lessThanOrEqualTo(self.snp_width)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}