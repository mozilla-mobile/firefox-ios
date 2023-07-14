// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

/// laurie - add comment
class StatusBarOverlay: UIView,
                        ThemeApplicable,
                        StatusBarScrollDelegate,
                        SearchBarLocationProvider {
    // Returns a value between 0 and 1 which indicates how far the user has scrolled.
    // This is used as the alpha of the status bar background.
    // 0 = no status bar background shown
    // 1 = status bar background is opaque
    private var scrollOffset: CGFloat = 0
    private var savedBackgroundColor: UIColor?
    var hasTopTabs = false

    private func setScrollOffset(scrollView: UIScrollView,
                                 statusBarFrame: CGRect?) {
        // Status bar height can be 0 on iPhone in landscape mode.
        guard isBottomSearchBar,
              let statusBarHeight: CGFloat = statusBarFrame?.height,
              statusBarHeight > 0
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

    func resetState() {
        scrollOffset = 1
        backgroundColor = savedBackgroundColor?.withAlphaComponent(scrollOffset)
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        savedBackgroundColor = hasTopTabs ? theme.colors.layer3 : theme.colors.layer1
        backgroundColor = savedBackgroundColor?.withAlphaComponent(scrollOffset)
    }

    // MARK: - StatusBarScrollDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView, statusBarFrame: CGRect?, theme: Theme) {
        setScrollOffset(scrollView: scrollView, statusBarFrame: statusBarFrame)
        applyTheme(theme: theme)
    }
}
