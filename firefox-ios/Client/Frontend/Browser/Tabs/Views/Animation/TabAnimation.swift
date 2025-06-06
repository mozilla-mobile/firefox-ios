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

        static let presentDuration: TimeInterval = 0.3
        static let dismissDuration: TimeInterval = 0.3

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

        // Tab snapshot animates from web view container on BVC to the cell frame
        var tempScreenshot = UIImage()
        if selectedTab.screenshot == nil {
            // When we first open a tab we do not have a screenshot before this animation runs
            // We can fix this to run in a sequence where the tab has a snapshot by the time we get here
            // if we roll out the .tabTrayUIExperiments fully
            let contentView = bvc.contentContainer.contentView
            tempScreenshot = contentView?.screenshot(quality: UIConstants.ActiveScreenshotQuality) ?? UIImage()
        }
        let tabSnapshot = UIImageView(image: selectedTab.screenshot ?? tempScreenshot)
        tabSnapshot.layer.cornerCurve = .continuous
        tabSnapshot.clipsToBounds = true
        tabSnapshot.contentMode = .scaleAspectFill
        let contentContainer = bvc.contentContainer
        tabSnapshot.frame = contentContainer.convert(contentContainer.bounds, to: bvc.view)

        DispatchQueue.main.async { [self] in
            runPresentationAnimation(
                context: context,
                browserVC: bvc,
                destinationController: destinationController,
                tabSnapshot: tabSnapshot,
                finalFrame: finalFrame,
                selectedTab: selectedTab
            )
        }
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

        // Tab screenshot will animate from the cell to the bvc web container
        let tabSnapshot = UIImageView(image: selectedTab.screenshot ?? .init())
        tabSnapshot.layer.cornerCurve = .continuous
        tabSnapshot.clipsToBounds = true
        tabSnapshot.contentMode = .scaleAspectFill
        tabSnapshot.layer.cornerRadius = ExperimentTabCell.UX.cornerRadius
        tabSnapshot.isHidden = true

        let finalFrame = context.finalFrame(for: toViewController)

        toView.frame = finalFrame

        // Allow the UI to render to make the snapshotting code more performant
        DispatchQueue.main.async { [self] in
            runDismissalAnimation(
                context: context,
                toViewController: toViewController,
                toView: toView,
                browserVC: bvc,
                tabSnapshot: tabSnapshot,
                finalFrame: finalFrame,
                selectedTab: selectedTab
            )
        }
    }

    private func runPresentationAnimation(
        context: UIViewControllerContextTransitioning,
        browserVC: BrowserViewController,
        destinationController: UIViewController,
        tabSnapshot: UIImageView,
        finalFrame: CGRect,
        selectedTab: Tab
    ) {
        // Snapshot of the BVC view
        let bvcSnapshot = UIImageView(image: browserVC.view.snapshot)
        bvcSnapshot.layer.cornerCurve = .continuous
        bvcSnapshot.layer.cornerRadius = ExperimentTabCell.UX.cornerRadius
        bvcSnapshot.clipsToBounds = true
        bvcSnapshot.contentMode = .scaleAspectFill

        // Wrap bvcSnapshot in a container to support external border
        let snapshotContainer = UIView(frame: bvcSnapshot.frame)
        snapshotContainer.layer.cornerRadius = bvcSnapshot.layer.cornerRadius
        snapshotContainer.layer.cornerCurve = .continuous
        snapshotContainer.clipsToBounds = false
        bvcSnapshot.frame = snapshotContainer.bounds

        // Create border layer
        let theme = retrieveTheme()
        // This borderWidth multiplier needed for smooth transition between end of animation and final selected state
        let borderWidth: CGFloat = ExperimentTabCell.UX.selectedBorderWidth * 2

        let borderColor = selectedTab.isPrivate ? theme.colors.borderAccentPrivate : theme.colors.borderAccent
        let borderLayer = CAShapeLayer()
        borderLayer.path = UIBezierPath(
            roundedRect: snapshotContainer.bounds,
            cornerRadius: ExperimentTabCell.UX.cornerRadius
        ).cgPath
        borderLayer.strokeColor = borderColor.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = borderWidth
        borderLayer.opacity = Float(UX.finalOpacity)

        snapshotContainer.layer.addSublayer(borderLayer)
        snapshotContainer.addSubview(bvcSnapshot)

        // Dimmed background view
        let backgroundView = UIView()
        backgroundView.backgroundColor = .init(white: UX.dimmedWhiteValue, alpha: UX.dimmedAlpha)
        backgroundView.frame = finalFrame

        // Add views to container
        context.containerView.addSubview(destinationController.view)
        context.containerView.addSubview(backgroundView)
        context.containerView.addSubview(snapshotContainer)
        context.containerView.addSubview(tabSnapshot)

        destinationController.view.frame = finalFrame
        destinationController.view.setNeedsLayout()
        destinationController.view.layoutIfNeeded()

        guard let panel = currentExperimentPanel as? ThemedNavigationController,
              let panelViewController = panel.viewControllers.first as? TabDisplayPanelViewController
        else { return }

        let cv = panelViewController.tabDisplayView.collectionView
        guard let dataSource = cv.dataSource as? TabDisplayDiffableDataSource,
              let item = findItem(by: selectedTab.tabUUID, dataSource: dataSource)
        else { return }

        cv.reloadData()
        var tabCell: ExperimentTabCell?
        var cellFrame: CGRect?

        if let indexPath = dataSource.indexPath(for: item) {
            cv.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            cv.layoutIfNeeded()
            if let cell = cv.cellForItem(at: indexPath) as? ExperimentTabCell {
                tabCell = cell
                cellFrame = cell.backgroundHolder.convert(cell.backgroundHolder.bounds, to: nil)
                cell.isHidden = true
                cell.setUnselectedState(theme: theme)
                cell.alpha = UX.clearAlpha
            }
        }

        // Animate
        cv.transform = CGAffineTransform(scaleX: UX.cvScalingFactor, y: UX.cvScalingFactor)
        cv.alpha = UX.halfAlpha

        CATransaction.begin()
        CATransaction.setAnimationDuration(UX.presentDuration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
        CATransaction.setCompletionBlock { [weak self] in
            snapshotContainer.removeFromSuperview()
            self?.unhideCellBorder(tabCell: tabCell, isPrivate: selectedTab.isPrivate, theme: theme)
        }

        let lineWidthAnimation = CABasicAnimation(keyPath: UX.lineWidthKeyPath)
        lineWidthAnimation.fromValue = UX.initialBorderWidth
        lineWidthAnimation.toValue = borderWidth
        lineWidthAnimation.duration = UX.presentDuration
        lineWidthAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        borderLayer.add(lineWidthAnimation, forKey: UX.lineWidthKeyPath)
        borderLayer.lineWidth = borderWidth

        let fadeAnimation = CABasicAnimation(keyPath: UX.opacityKeyPath)
        fadeAnimation.fromValue = UX.initialOpacity
        fadeAnimation.toValue = UX.finalOpacity
        fadeAnimation.duration = UX.presentDuration
        fadeAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        borderLayer.add(fadeAnimation, forKey: UX.opacityKeyPath)

        let animator = UIViewPropertyAnimator(duration: UX.presentDuration, curve: .easeOut) {
            if let frame = cellFrame {
                tabSnapshot.frame = frame
                snapshotContainer.frame = frame
                bvcSnapshot.frame = snapshotContainer.bounds

                snapshotContainer.layer.cornerRadius = ExperimentTabCell.UX.cornerRadius
                bvcSnapshot.layer.cornerRadius = ExperimentTabCell.UX.cornerRadius
                tabSnapshot.layer.cornerRadius = ExperimentTabCell.UX.cornerRadius
                // Animate path to match new size
                let oldPath = borderLayer.path
                let newPath = UIBezierPath(
                    roundedRect: snapshotContainer.bounds,
                    cornerRadius: ExperimentTabCell.UX.cornerRadius
                ).cgPath

                let pathAnimation = CABasicAnimation(keyPath: UX.animationPath)
                pathAnimation.fromValue = oldPath
                pathAnimation.toValue = newPath
                pathAnimation.duration = UX.presentDuration
                pathAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

                borderLayer.add(pathAnimation, forKey: UX.animationPath)
                borderLayer.path = newPath
            } else {
                tabSnapshot.alpha = UX.clearAlpha
                snapshotContainer.alpha = UX.clearAlpha
            }
            cv.transform = .identity
            cv.alpha = UX.opaqueAlpha
            backgroundView.alpha = UX.clearAlpha
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            tabCell?.isHidden = false
            UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
                tabCell?.alpha = UX.opaqueAlpha
            }.startAnimation()
        }

        animator.addCompletion { _ in
            backgroundView.removeFromSuperview()
            tabSnapshot.removeFromSuperview()
            context.completeTransition(true)
        }

        animator.startAnimation()

        CATransaction.commit()
    }

    private func unhideCellBorder(tabCell: ExperimentTabCell?, isPrivate: Bool, theme: Theme) {
        guard let tab = tabCell else { return }
        tab.setSelectedState(isPrivate: isPrivate, theme: theme)
    }

    private func runDismissalAnimation(
        context: UIViewControllerContextTransitioning,
        toViewController: UIViewController,
        toView: UIView,
        browserVC: BrowserViewController,
        tabSnapshot: UIImageView,
        finalFrame: CGRect,
        selectedTab: Tab
    ) {
        guard let panel = currentExperimentPanel as? ThemedNavigationController,
              let panelViewController = panel.viewControllers.first as? TabDisplayPanelViewController
        else {
            context.completeTransition(true)
            return
        }

        let cv = panelViewController.tabDisplayView.collectionView
        guard let dataSource = cv.dataSource as? TabDisplayDiffableDataSource,
              let item = findItem(by: selectedTab.tabUUID, dataSource: dataSource)
        else {
            // We don't have a collection view when the view is empty (ex: in private tabs)
            context.completeTransition(true)
            return
        }

        // This background view is needed for animation between the tab tray and the bvc
        let backgroundView = UIView()
        backgroundView.backgroundColor = .init(white: UX.dimmedWhiteValue, alpha: UX.dimmedAlpha)
        backgroundView.alpha = UX.clearAlpha
        backgroundView.frame = finalFrame

        context.containerView.addSubview(toView)
        context.containerView.addSubview(backgroundView)

        toView.setNeedsLayout()
        toView.layoutIfNeeded()

        // BVC snapshot animates from the cell to it's final position
        let toVCSnapshot: UIView =
        toView.snapshotView(afterScreenUpdates: true) ?? UIImageView(image: toView.snapshot)
        toVCSnapshot.layer.cornerCurve = .continuous
        toVCSnapshot.layer.cornerRadius = ExperimentTabCell.UX.cornerRadius
        toVCSnapshot.clipsToBounds = true

        context.containerView.addSubview(toVCSnapshot)
        context.containerView.addSubview(tabSnapshot)

        // Hide the destination as we're animating a snapshot into place
        toView.isHidden = true

        cv.reloadData()

        var tabCell: ExperimentTabCell?
        if let indexPath = dataSource.indexPath(for: item) {
            // This is needed otherwise the collection views content offset is incorrect
            cv.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            cv.layoutIfNeeded()

            if let cell = cv.cellForItem(at: indexPath) as? ExperimentTabCell {
                tabCell = cell
                tabSnapshot.frame = cv.convert(cell.frame, to: view)
                toVCSnapshot.frame = tabSnapshot.frame

                tabSnapshot.setNeedsLayout()
                tabSnapshot.layoutIfNeeded()

                cell.isHidden = true
            }
        }
        tabSnapshot.isHidden = false
        let animator = UIViewPropertyAnimator(duration: UX.dismissDuration, dampingRatio: 1.0) {
            cv.transform = .init(scaleX: UX.cvScalingFactor, y: UX.cvScalingFactor)
            cv.alpha = UX.halfAlpha

            let contentContainer = browserVC.contentContainer
            tabSnapshot.frame = contentContainer.convert(contentContainer.bounds, to: browserVC.view)
            tabSnapshot.layer.cornerRadius = UX.zeroCornerRadius
            toVCSnapshot.frame = finalFrame
            toVCSnapshot.layer.cornerRadius = UX.zeroCornerRadius
            backgroundView.alpha = UX.opaqueAlpha
        }

        animator.addCompletion { _ in
            tabCell?.isHidden = false
            toView.isHidden = false
            self.view.removeFromSuperview()
            tabSnapshot.removeFromSuperview()
            toVCSnapshot.removeFromSuperview()
            backgroundView.removeFromSuperview()
            context.completeTransition(true)
        }
        animator.startAnimation()
    }

    private func findItem(by id: String, dataSource: TabDisplayDiffableDataSource) -> TabDisplayDiffableDataSource.TabItem? {
        return dataSource.snapshot().itemIdentifiers.first { item in
            switch item {
            case .tab(let model):
                return model.id == id
            case .inactiveTab(let model):
                return model.id == id
            }
        }
    }
}
