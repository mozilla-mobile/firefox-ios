// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

@MainActor
class SwipeUpTabPreviewGestureHandler: NSObject, UIGestureRecognizerDelegate {
    // MARK: - TODO make it weak
    private let tabPreview: SwipeUpTabWebViewPreview
    private let topBlurView: UIView
    private let bottomBlurView: UIView
    private let screenshotHelper: ScreenshotHelper
    private weak var tabManager: TabManager?
    private let themeManager: ThemeManager
    private let windowUUID: WindowUUID
    private weak var gesture: UIPanGestureRecognizer?

    init(tabPreview: SwipeUpTabWebViewPreview,
         bottomBlurView: UIView,
         topBlurView: UIView,
         screenshotHelper: ScreenshotHelper,
         tabManager: TabManager,
         themeManager: ThemeManager,
         windowUUID: WindowUUID) {
        self.tabPreview = tabPreview
        self.bottomBlurView = bottomBlurView
        self.topBlurView = topBlurView
        self.screenshotHelper = screenshotHelper
        self.tabManager = tabManager
        self.themeManager = themeManager
        self.windowUUID = windowUUID
    }

    func setupGesture(on view: UIView) {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        view.addGestureRecognizer(gesture)
        gesture.delegate = self
        self.gesture = gesture
    }

    @objc
    private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let tab = tabManager?.selectedTab else { return }
        switch gesture.state {
        case .began:
            tabPreview.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            screenshotHelper.takeScreenshot(
                tab,
                windowUUID: windowUUID,
                screenshotBounds: CGRect(
                    origin: .zero,
                    size: CGSize(
                        width: tabPreview.bounds.width,
                        // The sum returns the content container viewport height
                        height: tabPreview.bounds.height - topBlurView.bounds.height - bottomBlurView.bounds.height
                    )
                )
            )
            tabPreview.setInitialTransform(
                topPadding: topBlurView.bounds.height,
                bottomPadding: bottomBlurView.bounds.height
            )
        case .changed:
            tabPreview.addTabScreenshot(image: tab.screenshot)
            let translation = gesture.translation(in: gesture.view)
            let fingerLocation = gesture.location(in: tabPreview)
            tabPreview.translate(translation, fingerLocation: fingerLocation)
        case .ended:
            let fingerLocation = gesture.location(in: tabPreview)
            switch tabPreview.releaseOutcome(fingerLocation: fingerLocation) {
            case .closeTab:
                UIView.animate(withDuration: 0.3) { [self] in
                    tabPreview.tossPreview()
                } completion: { [self] _ in
                    store.dispatch(
                        TabPanelViewAction(
                            panelType: .tabs,
                            tabUUID: tabManager?.selectedTab?.tabUUID,
                            windowUUID: windowUUID,
                            actionType: TabPanelViewActionType.closeTab
                        )
                    )
                    UIView.animate(withDuration: 0.3) { [self] in
                        tabPreview.alpha = 0.0
                        tabPreview.layer.zPosition = 0
                    } completion: { [weak self] _ in
                        self?.tabPreview.restore()
                    }
                }
            case .openTabTray:
                let cellBounds = tabPreview.previewCardFrame
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.tabPreview.dismissForTabTray()
                }
                store.dispatch(
                    GeneralBrowserAction(
                        cellBounds: cellBounds,
                        windowUUID: windowUUID,
                        actionType: GeneralBrowserActionType.showTabTray
                    )
                )
            case .cancel:
                tabPreview.restore()
            }
        default:
            break
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }
        let velocity = panGesture.velocity(in: gestureRecognizer.view)
        // Begin this gesture only if the velocity is higher on the y axis otherwise cancel it.
        // We need this check otherwise the gesture collides with swipe tabs gesture.
        return abs(velocity.y) > abs(velocity.x)
    }
}
