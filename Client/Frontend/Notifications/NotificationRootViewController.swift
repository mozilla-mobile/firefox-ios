/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import Shared

let NotificationStatusNotificationTapped = "NotificationStatusNotificationTapped"

// Notification duration in seconds
enum NotificationDuration: TimeInterval {
    case short = 4
}

/// This view controller wraps around the main UINavigationController of our app that holds the Browser/Tab Tray.
/// It allows us to display notifications/toasts in the top area of the screen while pushing away the status
/// bar to indicate sync status globally.
class NotificationRootViewController: UIViewController {
    var showingNotification: Bool { return notificationTimer != nil }

    fileprivate var rootViewController: UIViewController

    fileprivate let notificationCenter = NotificationCenter.default
    fileprivate(set) var statusBarHidden = false
    fileprivate(set) var showNotificationForSync: Bool = false
    fileprivate(set) var syncTitle: String?
    fileprivate(set) var notificationTimer: Timer?

    fileprivate var lastSyncState: [String: String]?

    lazy var notificationView: NotificationStatusView = {
        let view = NotificationStatusView()
        view.addTarget(self, action: #selector(NotificationRootViewController.didTapNotification))
        view.isHidden = true
        return view
    }()

    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
        super.init(nibName: nil, bundle: nil)

        notificationCenter.addObserver(self, selector: #selector(NotificationRootViewController.didStartSyncing), name: NotificationProfileDidStartSyncing, object: nil)
        notificationCenter.addObserver(self, selector: #selector(NotificationRootViewController.didFinishSyncing(_:)), name: NotificationProfileDidFinishSyncing, object: nil)
        notificationCenter.addObserver(self, selector: #selector(NotificationRootViewController.fxaAccountDidChange), name: NotificationFirefoxAccountChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(NotificationRootViewController.userDidInitiateSync), name: Notification.Name(rawValue: SyncNowSetting.NotificationUserInitiatedSyncManually), object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self, name: NotificationProfileDidStartSyncing, object: nil)
        notificationCenter.removeObserver(self, name: NotificationProfileDidFinishSyncing, object: nil)
        notificationCenter.removeObserver(self, name: NotificationFirefoxAccountChanged, object: nil)
        notificationCenter.removeObserver(self, name: Notification.Name(rawValue: SyncNowSetting.NotificationUserInitiatedSyncManually), object: nil)
    }
}

// MARK: - View Controller Overrides
extension NotificationRootViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        addChildViewController(rootViewController)
        view.addSubview(rootViewController.view)
        rootViewController.didMove(toParentViewController: self)

        view.addSubview(notificationView)

        remakeConstraintsForHiddenNotification()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showingNotification ? remakeConstraintsForVisibleNotification() : remakeConstraintsForHiddenNotification()
        view.setNeedsLayout()
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.setNeedsStatusBarAppearanceUpdate()
        }, completion: nil)
    }

    override var prefersStatusBarHidden: Bool {
        // Always hide status bar when in landscape iPhone
        if traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .compact {
            return true
        }
        return statusBarHidden
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

// MARK: - Notification API
extension NotificationRootViewController {
    func showStatusNotification(_ animated: Bool = true, duration: NotificationDuration = .short, withEllipsis: Bool = false) {
        assert(Thread.isMainThread, "Showing notifications must occur on the UI Thread.")

        if let activeTimer = notificationTimer {
            activeTimer.invalidate()
            notificationTimer = nil
        }

        self.statusBarHidden = true
        self.notificationView.isHidden = false
        self.notificationView.alpha = 0
        self.notificationView.showEllipsis = withEllipsis
        self.notificationView.startAnimation()
        self.view.layoutIfNeeded()

        let animation = {
            self.remakeConstraintsForVisibleNotification()
            self.notificationView.alpha = 1
            self.setNeedsStatusBarAppearanceUpdate()
            self.view.setNeedsUpdateConstraints()
            self.view.layoutIfNeeded()
        }

        animated ?
            UIView.animate(withDuration: 0.33, animations: animation) :
            animation()

        let timer = Timer.scheduledTimer(
            timeInterval: duration.rawValue,
            target: self,
            selector: #selector(NotificationRootViewController.dismissDurationedNotification),
            userInfo: nil,
            repeats: false
        )
        RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
        notificationTimer = timer
    }

    func hideStatusNotification(_ animated: Bool = true) {
        assert(Thread.isMainThread, "Hiding notifications must occur on the UI Thread.")

        if let activeTimer = notificationTimer {
            activeTimer.invalidate()
            notificationTimer = nil
        }

        self.statusBarHidden = false
        if let _ = self.notificationView.layer.animationKeys() {
            self.notificationView.endAnimation()
        }
        self.view.layoutIfNeeded()

        let animation = {
            self.remakeConstraintsForHiddenNotification()
            self.notificationView.alpha = 0
            self.setNeedsStatusBarAppearanceUpdate()
            self.view.setNeedsUpdateConstraints()
            self.view.layoutIfNeeded()
        }

        let completion: (Bool) -> Void = { finished in
            self.notificationView.showEllipsis = false
            self.notificationView.isHidden = true
        }

        if animated {
            UIView.animate(withDuration: 0.33, animations: animation, completion: completion)
        } else {
            animation()
            completion(true)
        }
    }
}

// MARK: - Layout Constraints
private extension NotificationRootViewController {
    func remakeConstraintsForVisibleNotification() {
        self.notificationView.snp.remakeConstraints { make in
            make.height.equalTo(20)
            make.left.right.equalTo(self.view)
            make.top.equalTo(self.topLayoutGuide.snp.bottom)
        }

        self.rootViewController.view.snp.remakeConstraints { make in
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.bottomLayoutGuide.snp.top)
            make.top.equalTo(self.notificationView.snp.bottom)
        }
    }

    func remakeConstraintsForHiddenNotification() {
        self.notificationView.snp.remakeConstraints { make in
            make.height.equalTo(20)
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.topLayoutGuide.snp.top)
        }

        self.rootViewController.view.snp.remakeConstraints { make in
            make.left.right.equalTo(self.view)
            
            make.bottom.equalTo(self.bottomLayoutGuide.snp.top)
            make.top.equalTo(self.topLayoutGuide.snp.bottom)
        }
    }
}

// MARK: - Notification Selectors
private extension NotificationRootViewController {
    @objc func didStartSyncing() {
        guard showNotificationForSync else { return }
        showNotificationForSync = false

        DispatchQueue.main.async {
            self.notificationView.titleLabel.text = self.syncTitle ?? Strings.SyncingMessageWithoutEllipsis
            if self.showingNotification {
                self.hideStatusNotification(false)
                self.showStatusNotification(false, withEllipsis: true)
            } else {
                self.showStatusNotification(withEllipsis: true)
            }
        }
    }

    func syncMessageForNotification(_ notificationObject: AnyObject?) -> NSAttributedString? {
        defer {
            lastSyncState = notificationObject as? [String: String]
        }
        guard let syncDisplayState = notificationObject as? [String: String],
        let state = syncDisplayState["state"],
            let message = syncDisplayState["message"], state != lastSyncState?["state"] || message != lastSyncState?["message"] else {
                return nil
        }
        switch state {
        case "Error":
            return NSAttributedString(string: message, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowErrorTextColor, NSFontAttributeName: notificationView.titleLabel.font])
        case "Warning":
            return NSAttributedString(string: message, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowWarningTextColor, NSFontAttributeName: notificationView.titleLabel.font])
        default: return nil
        }
    }

    @objc func didFinishSyncing(_ notification: Notification) {
        DispatchQueue.main.async {
            defer {
                if let syncMessage = self.notificationView.titleLabel.attributedText {
                        self.showStatusNotification(!self.showingNotification, duration: .short, withEllipsis: false)

                } else if self.showingNotification {
                    self.showNotificationForSync = false
                    self.hideStatusNotification()

                }
            }
            guard let syncMessage = self.syncMessageForNotification(notification.object as AnyObject?) else {
                self.notificationView.titleLabel.text = nil
                self.notificationView.titleLabel.attributedText = nil
                return
            }
            self.notificationView.titleLabel.attributedText = syncMessage
        }
    }

    @objc func fxaAccountDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo, (userInfo[NotificationUserInfoKeyHasSyncableAccount] as? Bool ?? false) else {
            return
        }

        // Only show 'Syncing...' whenever the accounts have changed indicating a first time sync.
        showNotificationForSync = true
        syncTitle = Strings.FirstTimeSyncLongTime
    }

    @objc func userDidInitiateSync() {
        showNotificationForSync = true
        syncTitle = Strings.SyncingMessageWithoutEllipsis
    }

    @objc func didTapNotification() {
        notificationCenter.post(name: Notification.Name(rawValue: NotificationStatusNotificationTapped), object: nil)
    }

    @objc func dismissDurationedNotification() {
        DispatchQueue.main.async {
            self.hideStatusNotification()
        }
    }
}

// MARK: Notification Status View
class NotificationStatusView: UIView {
    var showEllipsis: Bool = false {
        didSet {
            ellipsisLabel.isHidden = !showEllipsis
        }
    }

    lazy var titleLabel: UILabel = self.setupStatusLabel()
    lazy var ellipsisLabel: UILabel = self.setupStatusLabel()
    fileprivate var animationTimer: Timer?

    fileprivate func setupStatusLabel() -> UILabel {
        let label = UILabel()
        label.textColor = .white
        label.font = UIConstants.DefaultChromeSmallFontBold
        return label
    }

    fileprivate let tapGesture = UITapGestureRecognizer()

    init() {
        super.init(frame: CGRect.zero)
        isUserInteractionEnabled = true
        addGestureRecognizer(tapGesture)
        backgroundColor = UIConstants.AppBackgroundColor
        addSubview(titleLabel)
        addSubview(ellipsisLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalTo(self)
            make.width.lessThanOrEqualTo(self.snp.width)
        }
        ellipsisLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.left.equalTo(titleLabel.snp.right)
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
            animationTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(NotificationStatusView.updateEllipsis), userInfo: nil, repeats: true)
            RunLoop.main.add(animationTimer!, forMode: RunLoopMode.commonModes)
        }
    }

    func endAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    func addTarget(_ target: AnyObject, action: Selector) {
        tapGesture.addTarget(target, action: action)
    }

    @objc func updateEllipsis() {
        let nextCount = ((ellipsisLabel.text?.characters.count ?? 0) + 1) % 4
        ellipsisLabel.text = (0..<nextCount).reduce("") { return $0.0 + "." }
    }
}
