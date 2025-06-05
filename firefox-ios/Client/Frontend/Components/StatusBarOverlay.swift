// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

protocol StatusBarScrollDelegate: AnyObject {
    func scrollViewDidScroll(_ scrollView: UIScrollView, statusBarFrame: CGRect?, theme: Theme)
}

protocol BrowserStatusBarScrollDelegate: AnyObject {
    func homepageScrollViewDidScroll(scrollOffset: CGFloat)
}

/// The status bar overlay is the view that appears under the status bar on top of the device.
/// In our case, the status bar overlay has different behavior in the cases of:
/// - On homepage with bottom URL bar, the status bar overlay alpha changes when the user scrolls.
/// - In all other cases apart from this one, the status bar should be opaque
/// - With top tabs, the status bar overlay has a different color than without it
class StatusBarOverlay: UIView,
                        ThemeApplicable,
                        StatusBarScrollDelegate,
                        SearchBarLocationProvider,
                        Notifiable {
    private struct UX {
        static let overlayAppearanceAnimationDuration: TimeInterval = 0.2
    }

    private var savedBackgroundColor: UIColor?
    private var savedIsHomepage: Bool?
    private var wallpaperManager: WallpaperManagerInterface = WallpaperManager()
    private var toolbarHelper: ToolbarHelperInterface = ToolbarHelper()
    weak var scrollDelegate: BrowserStatusBarScrollDelegate?
    var notificationCenter: NotificationProtocol = NotificationCenter.default
    var hasTopTabs = false

    private var isToolbarRefactorEnabled: Bool {
        toolbarHelper.isToolbarRefactorEnabled
    }

    /// Returns a value between 0 and 1 which indicates how far the user has scrolled.
    /// This is used as the alpha of the status bar background.
    /// 0 = no status bar background shown
    /// 1 = status bar background is opaque
    private(set) var scrollOffset: CGFloat = 1

    // MARK: Initializer

    convenience init(frame: CGRect,
                     scrollDelegate: BrowserStatusBarScrollDelegate? = nil,
                     notificationCenter: NotificationProtocol = NotificationCenter.default,
                     wallpaperManager: WallpaperManagerInterface = WallpaperManager(),
                     toolbarHelper: ToolbarHelperInterface = ToolbarHelper()) {
        self.init(frame: frame)

        self.notificationCenter = notificationCenter
        self.wallpaperManager = wallpaperManager
        self.scrollDelegate = scrollDelegate
        self.toolbarHelper = toolbarHelper
        setupNotifications(forObserver: self,
                           observing: [.WallpaperDidChange,
                                       .SearchBarPositionDidChange])
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupNotifications(forObserver: self,
                           observing: [.WallpaperDidChange,
                                       .SearchBarPositionDidChange])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    func resetState(isHomepage: Bool) {
        savedIsHomepage = isHomepage

        // We only need no status bar for one edge case
        var needsNoStatusBar = isHomepage && isBottomSearchBar
        if !isToolbarRefactorEnabled {
            needsNoStatusBar = needsNoStatusBar && wallpaperManager.currentWallpaper.hasImage
        }
        scrollOffset = needsNoStatusBar ? 0 : 1

        let translucencyBackgroundAlpha = toolbarHelper.backgroundAlpha()
        let alpha = scrollOffset > translucencyBackgroundAlpha ? translucencyBackgroundAlpha : scrollOffset
        backgroundColor = savedBackgroundColor?.withAlphaComponent(alpha)
    }

    func showOverlay(animated: Bool) {
        guard animated else {
            scrollDelegate?.homepageScrollViewDidScroll(scrollOffset: 1.0)
            backgroundColor = savedBackgroundColor?.withAlphaComponent(toolbarHelper.backgroundAlpha())
            return
        }
        UIView.animate(
            withDuration: UX.overlayAppearanceAnimationDuration,
            delay: 0,
            options: .curveEaseIn
        ) {
            self.scrollDelegate?.homepageScrollViewDidScroll(scrollOffset: 1.0)
            self.backgroundColor = self.savedBackgroundColor?.withAlphaComponent(self.toolbarHelper.backgroundAlpha())
        }
    }

    func restoreOverlay(animated: Bool, isHomepage: Bool) {
        guard animated else {
            scrollDelegate?.homepageScrollViewDidScroll(scrollOffset: scrollOffset)
            resetState(isHomepage: isHomepage)
            return
        }
        UIView.animate(
            withDuration: UX.overlayAppearanceAnimationDuration,
            delay: 0,
            options: .curveEaseIn
        ) {
            self.scrollDelegate?.homepageScrollViewDidScroll(scrollOffset: self.scrollOffset)
            self.resetState(isHomepage: isHomepage)
        }
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        savedBackgroundColor = (hasTopTabs || isToolbarRefactorEnabled) ? theme.colors.layer3 : theme.colors.layer1
        let translucencyBackgroundAlpha = toolbarHelper.backgroundAlpha()

        // We only need no status bar for one edge case
        let isHomepage = savedIsHomepage ?? false
        let isWallpaperedHomepage = isHomepage && wallpaperManager.currentWallpaper.hasImage
        var needsNoStatusBar: Bool

        if isToolbarRefactorEnabled {
            needsNoStatusBar = isHomepage && isBottomSearchBar
        } else {
            needsNoStatusBar = isWallpaperedHomepage && isBottomSearchBar
        }

        if needsNoStatusBar {
            let alpha = scrollOffset > translucencyBackgroundAlpha ? translucencyBackgroundAlpha : scrollOffset
            backgroundColor = savedBackgroundColor?.withAlphaComponent(alpha)
        } else {
            backgroundColor = savedBackgroundColor?.withAlphaComponent(translucencyBackgroundAlpha)
        }
    }

    // MARK: - StatusBarScrollDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView, statusBarFrame: CGRect?, theme: Theme) {
        setScrollOffset(scrollView: scrollView, statusBarFrame: statusBarFrame)
        applyTheme(theme: theme)
        scrollDelegate?.homepageScrollViewDidScroll(scrollOffset: scrollOffset)
    }

    private func setScrollOffset(scrollView: UIScrollView,
                                 statusBarFrame: CGRect?) {
        // Status bar height can be 0 on iPhone in landscape mode.
        guard isBottomSearchBar,
              let statusBarHeight: CGFloat = statusBarFrame?.height,
              statusBarHeight > 0,
              savedIsHomepage ?? false
        else {
            scrollOffset = 1
            return
        }

        // The scrollview content offset is automatically adjusted to account for the status bar.
        // We want to start showing the status bar background as soon as the user scrolls.
        var offset: CGFloat
        offset = scrollView.contentOffset.y / statusBarHeight

        if offset > 1 {
            offset = 1
        } else if offset < 0 {
            offset = 0
        }
        scrollOffset = offset
    }

    // MARK: Notifiable

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .WallpaperDidChange, .SearchBarPositionDidChange:
            ensureMainThread {
                self.resetState(isHomepage: self.savedIsHomepage ?? false)
            }
        default: break
        }
    }
}
