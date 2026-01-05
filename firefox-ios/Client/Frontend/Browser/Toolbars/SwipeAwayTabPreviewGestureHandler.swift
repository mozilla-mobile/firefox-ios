// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

@MainActor
class SwipeAwayTabPreviewGestureHandler: NSObject, UIGestureRecognizerDelegate {
    // MARK: - TODO make it weak
    private let tabPreview: SwipeAwayTabPreview
    private weak var tabManager: TabManager?
    private let themeManager: ThemeManager
    private let windowUUID: WindowUUID
    private weak var gesture: UIPanGestureRecognizer?

    init(tabPreview: SwipeAwayTabPreview,
         tabManager: TabManager,
         themeManager: ThemeManager,
         windowUUID: WindowUUID) {
        self.tabPreview = tabPreview
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
        switch gesture.state {
        case .began:
            tabPreview.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            UIView.animate(withDuration: 0.3) { [self] in
                tabPreview.addImage(url: tabManager?.selectedTab?.url?.absoluteString ?? "",
                                    startingPoint: 10.0)
                tabPreview.alpha = 1
                tabPreview.layer.zPosition = 1000
            }

        case .changed:
            let translation = gesture.translation(in: gesture.view)
            tabPreview.translate(position: translation)
        case .ended:
            let velocity = gesture.velocity(in: gesture.view)
            let translation = gesture.translation(in: gesture.view)
            if velocity.y < -500 || translation.y < -(gesture.view?.bounds.height ?? 0.0 / 2.7) {
                UIView.animate(withDuration: 0.1) { [self] in
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
            } else {
                if abs(translation.y) > 130 {
//                    navigationHandler?.showTabTray(selectedPanel: .tabs)
                }
                UIView.animate(withDuration: 0.3) { [self] in
                    tabPreview.alpha = 0
                    tabPreview.layer.zPosition = 0
                } completion: { [weak self] _ in
                    self?.tabPreview.restore()
                }
            }
        default:
            break
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        let velocity = panGesture.velocity(in: gestureRecognizer.view)
        // Begin this gesture only if the velocity is higher on the y axis otherwise cancel it.
        return abs(velocity.y) > abs(velocity.x)
    }
}
