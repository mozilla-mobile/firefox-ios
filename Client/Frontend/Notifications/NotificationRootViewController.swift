/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import Shared

let NotificationStatusNotificationTapped = "NotificationStatusNotificationTapped"

// Notification duration in seconds
enum NotificationDuration: NSTimeInterval {
    case Short = 4
}

/// This view controller wraps around the main UINavigationController of our app that holds the Browser/Tab Tray.
/// It allows us to display notifications/toasts in the top area of the screen while pushing away the status
/// bar to indicate sync status globally.
class NotificationRootViewController: UIViewController {
    private var rootViewController: UIViewController

    private let notificationCenter = NSNotificationCenter.defaultCenter()
    private(set) var statusBarHidden = false
    private(set) var showingNotification = false
    private(set) var showNotificationForSync: Bool = false
    private(set) var syncTitle: String?
    private(set) var notificationTimer: NSTimer?

    lazy var notificationView: NotificationStatusView = {
        let view = NotificationStatusView()
        view.addTarget(self, action: #selector(NotificationRootViewController.didTapNotification))
        view.hidden = true
        return view
    }()

    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
        super.init(nibName: nil, bundle: nil)

        notificationCenter.addObserver(self, selector: #selector(NotificationRootViewController.didStartSyncing), name: NotificationProfileDidStartSyncing, object: nil)
        notificationCenter.addObserver(self, selector: #selector(NotificationRootViewController.didFinishSyncing), name: NotificationProfileDidFinishSyncing, object: nil)
        notificationCenter.addObserver(self, selector: #selector(NotificationRootViewController.fxaAccountDidChange), name: NotificationFirefoxAccountChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(NotificationRootViewController.userDidInitiateSync), name: SyncNowSetting.NotificationUserInitiatedSyncManually, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self, name: NotificationProfileDidStartSyncing, object: nil)
        notificationCenter.removeObserver(self, name: NotificationProfileDidFinishSyncing, object: nil)
        notificationCenter.removeObserver(self, name: NotificationFirefoxAccountChanged, object: nil)
        notificationCenter.removeObserver(self, name: SyncNowSetting.NotificationUserInitiatedSyncManually, object: nil)
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
        view.setNeedsLayout()
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
    func showStatusNotification(duration duration: NotificationDuration?) {
        assert(NSThread.isMainThread(), "Showing notifications must occur on the UI Thread.")

        if let activeTimer = notificationTimer {
            activeTimer.fire()
            activeTimer.invalidate()
            notificationTimer = nil
        }

        self.statusBarHidden = true
        self.notificationView.hidden = false
        self.notificationView.alpha = 0
        self.notificationView.startAnimation()
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(0.33) {
            self.remakeConstraintsForVisibleNotification()
            self.notificationView.alpha = 1
            self.setNeedsStatusBarAppearanceUpdate()
            self.view.setNeedsUpdateConstraints()
            self.view.layoutIfNeeded()
        }

        if let duration = duration?.rawValue {
            notificationTimer = NSTimer.scheduledTimerWithTimeInterval(
                duration,
                target: self,
                selector: #selector(NotificationRootViewController.dismissDurationedNotification),
                userInfo: nil,
                repeats: false)
            NSRunLoop.mainRunLoop().addTimer(notificationTimer!, forMode: NSRunLoopCommonModes)
        }
    }

    func hideStatusNotification() {
        assert(NSThread.isMainThread(), "Hiding notifications must occur on the UI Thread.")

        if let activeTimer = notificationTimer {
            activeTimer.invalidate()
            notificationTimer = nil
        }

        self.statusBarHidden = false
        self.notificationView.endAnimation()
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
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.snp_bottomLayoutGuideTop)
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
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.snp_bottomLayoutGuideTop)
            make.top.equalTo(self.snp_topLayoutGuideBottom)
        }
    }
}

// MARK: - Notification Selectors
private extension NotificationRootViewController {
    @objc func didStartSyncing() {
        guard showNotificationForSync else { return }
        showNotificationForSync = false
        showingNotification = true

        dispatch_async(dispatch_get_main_queue()) {
            self.notificationView.titleLabel.text = self.syncTitle ?? Strings.SyncingMessageWithoutEllipsis
            self.showStatusNotification(duration: .Short)
        }
    }

    @objc func didFinishSyncing() {
        guard showingNotification else { return }
        showingNotification = false
        dispatch_async(dispatch_get_main_queue()) {
            self.hideStatusNotification()
        }
    }

    @objc func fxaAccountDidChange() {
        // Only show 'Syncing...' whenever the accounts have changed indicating a first time sync.
        showNotificationForSync = true
        syncTitle = Strings.FirstTimeSyncLongTime
    }

    @objc func userDidInitiateSync() {
        showNotificationForSync = true
        syncTitle = Strings.SyncingMessageWithoutEllipsis
    }

    @objc func didTapNotification() {
        notificationCenter.postNotificationName(NotificationStatusNotificationTapped, object: nil)
    }

    @objc func dismissDurationedNotification() {
        dispatch_async(dispatch_get_main_queue()) {
            self.hideStatusNotification()
        }
    }
}

// MARK: Notification Status View
class NotificationStatusView: UIView {
    lazy var titleLabel: UILabel = self.setupStatusLabel()
    lazy var ellipsisLabel: UILabel = self.setupStatusLabel()
    private var animationTimer: NSTimer?

    private func setupStatusLabel() -> UILabel {
        let label = UILabel()
        label.textColor = .whiteColor()
        label.font = UIConstants.DefaultChromeSmallFontBold
        return label
    }

    private let tapGesture = UITapGestureRecognizer()

    init() {
        super.init(frame: CGRect.zero)
        userInteractionEnabled = true
        addGestureRecognizer(tapGesture)
        backgroundColor = UIConstants.AppBackgroundColor
        addSubview(titleLabel)
        addSubview(ellipsisLabel)
        titleLabel.snp_makeConstraints { make in
            make.center.equalTo(self)
            make.width.lessThanOrEqualTo(self.snp_width)
        }
        ellipsisLabel.snp_makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.left.equalTo(titleLabel.snp_right)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        endAnimation()
    }

    func startAnimation() {
        if animationTimer == nil {
            animationTimer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: #selector(NotificationStatusView.updateEllipsis), userInfo: nil, repeats: true)
            NSRunLoop.mainRunLoop().addTimer(animationTimer!, forMode: NSRunLoopCommonModes)
        }
    }

    func endAnimation() {
        animationTimer?.invalidate()
    }

    func addTarget(target: AnyObject, action: Selector) {
        tapGesture.addTarget(target, action: action)
    }

    @objc func updateEllipsis() {
        let nextCount = ((ellipsisLabel.text?.characters.count ?? 0) + 1) % 4
        ellipsisLabel.text = (0..<nextCount).reduce("") { return $0.0 + "." }
    }
}