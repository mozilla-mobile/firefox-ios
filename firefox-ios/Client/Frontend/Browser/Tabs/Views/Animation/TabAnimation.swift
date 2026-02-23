// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit
import Shared

extension TabTrayViewController: UIViewControllerTransitioningDelegate {
    private struct UX {
        // Animation keyPaths
        static let lineWidthKeyPath = "lineWidth"
        static let opacityKeyPath = "opacity"
        static let animationPath = "path"

        // Animation Variables
        static let clearAlpha = 0.0
        static let dimmedAlpha = 0.3
        static let halfAlpha = 0.5
        static let opaqueAlpha = 1.0

        static let dimmedWhiteValue = 0.0

        static let presentDuration: TimeInterval = 0.2
        static let dismissDuration: TimeInterval = 0.2
        static let bvcScreenshotQuality: CGFloat = 1.0

        static let cvScalingFactor = 1.2
        static let initialOpacity = 0.0
        static let finalOpacity = 1.0
        static let initialBorderWidth = 0.0

        static let zeroCornerRadius = 0.0
    }
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return BasicAnimationController(delegate: self, direction: .presenting)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BasicAnimationController(delegate: self, direction: .dismissing)
    }
}

extension TabTrayViewController: BasicAnimationControllerDelegate {
    func animatePresentation(context: UIViewControllerContextTransitioning) {
        guard
            let containerController = context.viewController(forKey: .from) as? UINavigationController,
            let bvc = containerController.topViewController as? BrowserViewController,
            let destinationController = context.viewController(forKey: .to)
        else {
            logger.log(
        """
            Attempted to present the tab tray on something that is not a BrowserViewController which is
            currently unsupported.
        """,
        level: .warning,
        category: .tabs
            )
            context.completeTransition(true)
            return
        }

        guard let selectedTab = bvc.tabManager.selectedTab
        else {
            logger.log("Attempted to present the tab tray without having a selected tab",
                       level: .warning,
                       category: .tabs)
            context.completeTransition(true)
            return
        }

        let finalFrame = context.finalFrame(for: destinationController)

        self.runPresentationAnimation(
            context: context,
            browserVC: bvc,
            destinationController: destinationController,
            finalFrame: finalFrame,
            selectedTab: selectedTab
        )
    }

    func animateDismissal(context: UIViewControllerContextTransitioning) {
        guard let toViewController = context.viewController(forKey: .to),
              let toView = context.view(forKey: .to)
        else {
            logger.log(
        """
            Attempted to dismiss the tab tray without a view to dismiss from.
            Likely the `modalPresentationStyle` was changed away from `fullScreen` and should be changed
            back if using this custom animation.
        """,
        level: .warning,
        category: .tabs)
            context.completeTransition(true)
            return
        }

        guard let containerController = toViewController as? UINavigationController,
              let bvc = containerController.topViewController as? BrowserViewController
        else {
            logger.log(
        """
            Attempted to dismiss the tab tray from something that is not a BrowserViewController which is
            currently unsupported.
        """,
        level: .warning,
        category: .tabs)
            context.completeTransition(true)
            return
        }

        guard let selectedTab = bvc.tabManager.selectedTab
        else {
            logger.log("Attempted to dismiss the tab tray without having a selected tab",
                       level: .warning,
                       category: .tabs)
            context.completeTransition(true)
            return
        }

        let finalFrame = context.finalFrame(for: toViewController)
        toView.frame = finalFrame

        runDismissalAnimation(
            context: context,
            toView: toView,
            browserVC: bvc,
            finalFrame: finalFrame,
            selectedTab: selectedTab
        )
    }

    private func runPresentationAnimation(
        context: UIViewControllerContextTransitioning,
        browserVC: BrowserViewController,
        destinationController: UIViewController,
        finalFrame: CGRect,
        selectedTab: Tab
    ) {
        let bvcSnapshot = UIImageView(image: browserVC.view.screenshot(quality: UX.bvcScreenshotQuality))
        bvcSnapshot.contentMode = .scaleAspectFill
        bvcSnapshot.frame = browserVC.view.frame
        bvcSnapshot.clipsToBounds = true

        // Dimmed background view
        let backgroundView = UIView()
        backgroundView.backgroundColor = .init(white: UX.dimmedWhiteValue, alpha: UX.dimmedAlpha)
        backgroundView.frame = finalFrame

        // Add views to container
        context.containerView.addSubview(destinationController.view)
        context.containerView.addSubview(backgroundView)
        context.containerView.addSubview(bvcSnapshot)

        guard let panel = currentExperimentPanel as? ThemedNavigationController,
              let panelViewController = panel.viewControllers.first as? TabDisplayPanelViewController
        else { return }

        // Don't block the UI rendering with the animation to make the snapshotting code more performant
        DispatchQueue.main.async {
            let cv = panelViewController.tabDisplayView.collectionView
            guard let dataSource = cv.dataSource as? TabDisplayDiffableDataSource,
                  let item = self.findItem(by: selectedTab.tabUUID, dataSource: dataSource)
            else { return }

            var tabCell: ExperimentTabCell?
            var cellFrame: CGRect?
            let theme = self.retrieveTheme()

            if let indexPath = dataSource.indexPath(for: item) {
                cv.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
                // TODO: FXIOS-14550 Look into if we can find an alternative to calling layoutIfNeeded() here
                cv.layoutIfNeeded()
                if let cell = cv.cellForItem(at: indexPath) as? ExperimentTabCell {
                    tabCell = cell
                    cellFrame = cell.convert(cell.backgroundHolder.bounds, to: nil)
                    cell.isHidden = true
                    cell.setUnselectedState(theme: theme)
                    cell.alpha = UX.clearAlpha
                }
            }
            // Animate
            cv.transform = CGAffineTransform(scaleX: UX.cvScalingFactor, y: UX.cvScalingFactor)
            cv.alpha = UX.halfAlpha

            destinationController.view.frame = finalFrame
            destinationController.view.layoutIfNeeded()
            self.performPresentationAnimation(
                cellFrame: cellFrame,
                tabCell: tabCell,
                bvcSnapshot: bvcSnapshot,
                collectionView: cv,
                backgroundView: backgroundView,
                context: context,
                selectedTab: selectedTab,
                theme: theme
            )
        }
    }

    private func performPresentationAnimation(
        cellFrame: CGRect?,
        tabCell: ExperimentTabCell?,
        bvcSnapshot: UIView,
        collectionView: UICollectionView,
        backgroundView: UIView,
        context: UIViewControllerContextTransitioning,
        selectedTab: Tab,
        theme: Theme
    ) {
        let animator = UIViewPropertyAnimator(duration: UX.presentDuration, curve: .easeOut) {
            if let cellFrame {
                bvcSnapshot.frame = cellFrame
                bvcSnapshot.layer.cornerRadius = ExperimentTabCell.UX.cornerRadius
            } else {
                bvcSnapshot.alpha = UX.clearAlpha
            }
            collectionView.transform = .identity
            collectionView.alpha = UX.opaqueAlpha
            backgroundView.alpha = UX.clearAlpha
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak tabCell] in
            tabCell?.isHidden = false
            UIView.animate(withDuration: 0.1) {
                tabCell?.alpha = UX.opaqueAlpha
            }
        }

        animator.addCompletion { _ in
            backgroundView.removeFromSuperview()
            bvcSnapshot.removeFromSuperview()
            context.completeTransition(true)
            self.unhideCellBorder(tabCell: tabCell, isPrivate: selectedTab.isPrivate, theme: theme)
        }
        animator.startAnimation()
    }

    private func unhideCellBorder(tabCell: ExperimentTabCell?, isPrivate: Bool, theme: Theme) {
        guard let tab = tabCell else { return }
        tab.setSelectedState(isPrivate: isPrivate, theme: theme)
    }

    private func runDismissalAnimation(
        context: UIViewControllerContextTransitioning,
        toView: UIView,
        browserVC: BrowserViewController,
        finalFrame: CGRect,
        selectedTab: Tab
    ) {
        guard let panel = currentExperimentPanel as? ThemedNavigationController,
              let panelViewController = panel.viewControllers.first as? TabDisplayPanelViewController
        else {
            context.completeTransition(true)
            return
        }

        let contentContainer = browserVC.contentContainer

        // if the selectedTab screenshot is nil we assume we have tapped the new tab button
        // from the tab tray, learn more in private, or opened a tab from the sync'd tabs
        if selectedTab.screenshot == nil {
            dismissWithoutTabScreenshot(
                panelViewController: panelViewController,
                contentContainer: contentContainer,
                toView: toView,
                context: context
            )
        } else {
            dismissWithTabScreenshot(
                panelViewController: panelViewController,
                contentContainer: contentContainer,
                toView: toView,
                context: context,
                selectedTab: selectedTab,
                browserVC: browserVC
            )
        }
    }

    private func dismissWithTabScreenshot(
        panelViewController: TabDisplayPanelViewController,
        contentContainer: UIView,
        toView: UIView,
        context: UIViewControllerContextTransitioning,
        selectedTab: Tab,
        browserVC: BrowserViewController
    ) {
        let cv = panelViewController.tabDisplayView.collectionView
        guard let dataSource = cv.dataSource as? TabDisplayDiffableDataSource,
              let item = findItem(by: selectedTab.tabUUID, dataSource: dataSource)
        else {
            // We don't have a collection view when the view is empty (ex: in private tabs)
            context.completeTransition(true)
            return
        }

        contentContainer.isHidden = true

        toView.layer.cornerCurve = .continuous
        toView.layer.cornerRadius = ExperimentTabCell.UX.cornerRadius
        toView.clipsToBounds = true
        toView.alpha = UX.clearAlpha

        context.containerView.addSubview(toView)

        // Trigger animation async to be non blocking and allow UI to render
        DispatchQueue.main.async {
            let tabSnapshot = self.buildTabSnapshot(selectedTab: selectedTab, contentContainer: contentContainer)
            context.containerView.addSubview(tabSnapshot)

            var tabCell: ExperimentTabCell?
            if let indexPath = dataSource.indexPath(for: item),
               let cell = cv.cellForItem(at: indexPath) as? ExperimentTabCell {
                tabCell = cell
                tabSnapshot.frame = cv.convert(cell.frame, to: browserVC.view)

                cell.isHidden = true
            }

            UIView.animate(
                withDuration: UX.dismissDuration,
                delay: 0.0,
                options: .curveEaseOut
            ) {
                cv.transform = .init(scaleX: UX.cvScalingFactor, y: UX.cvScalingFactor)
                cv.alpha = UX.opaqueAlpha

                tabSnapshot.frame = contentContainer.frame
                toView.alpha = UX.opaqueAlpha
                toView.layer.cornerRadius = UX.zeroCornerRadius
                tabSnapshot.layer.cornerRadius = UX.zeroCornerRadius
            } completion: { _ in
                contentContainer.isHidden = false
                tabCell?.isHidden = false
                self.view.removeFromSuperview()
                tabSnapshot.removeFromSuperview()
                toView.removeFromSuperview()
                context.completeTransition(true)
            }
        }
    }

    private func buildTabSnapshot(selectedTab: Tab, contentContainer: UIView) -> UIView {
        let tabSnapshot = UIImageView(image: selectedTab.screenshot)
        // crop the tab screenshot to the contentContainer frame so the animation
        // and the initial transform doesn't stutter
        if let image = tabSnapshot.image, let croppedImage = image.cgImage?.cropping(
            to: CGRect(
                x: contentContainer.frame.origin.x * image.scale,
                y: contentContainer.frame.origin.y * image.scale,
                width: contentContainer.frame.width * image.scale,
                height: contentContainer.frame.height * image.scale
            )
        ) {
            tabSnapshot.image = UIImage(cgImage: croppedImage)
        }

        tabSnapshot.clipsToBounds = true
        tabSnapshot.contentMode = .scaleAspectFill
        tabSnapshot.layer.cornerCurve = .continuous
        tabSnapshot.layer.cornerRadius = ExperimentTabCell.UX.cornerRadius
        return tabSnapshot
    }

    private func dismissWithoutTabScreenshot(
        panelViewController: UIViewController,
        contentContainer: UIView,
        toView: UIView,
        context: UIViewControllerContextTransitioning
    ) {
        let snapshot = panelViewController.view.snapshot
        let tabTraySnapshot = UIImageView(image: snapshot)
        tabTraySnapshot.frame = view.bounds
        tabTraySnapshot.contentMode = .scaleToFill

        contentContainer.alpha = UX.clearAlpha
        toView.alpha = UX.clearAlpha

        context.containerView.addSubview(tabTraySnapshot)
        context.containerView.addSubview(toView)

        UIView.animate(
            withDuration: UX.dismissDuration,
            delay: 0.0,
            options: .curveEaseOut
        ) {
            tabTraySnapshot.transform = CGAffineTransform(scaleX: UX.cvScalingFactor, y: UX.cvScalingFactor)
            toView.alpha = UX.opaqueAlpha
            contentContainer.alpha = UX.opaqueAlpha
        } completion: { _ in
            self.view.removeFromSuperview()
            tabTraySnapshot.removeFromSuperview()
            toView.removeFromSuperview()
            context.completeTransition(true)
        }
    }

    private func findItem(by id: String, dataSource: TabDisplayDiffableDataSource) -> TabDisplayDiffableDataSource.TabItem? {
        return dataSource.snapshot().itemIdentifiers.first { item in
            switch item {
            case .tab(let model):
                return model.id == id
            }
        }
    }
}
