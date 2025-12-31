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

        static let presentDuration: TimeInterval = 0.275
        static let dismissDuration: TimeInterval = 0.275

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

        DispatchQueue.main.async { [self] in
            runPresentationAnimation(
                context: context,
                browserVC: bvc,
                destinationController: destinationController,
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

        let finalFrame = context.finalFrame(for: toViewController)
        toView.frame = finalFrame

        // Allow the UI to render to make the snapshotting code more performant
        DispatchQueue.main.async { [self] in
            runDismissalAnimation(
                context: context,
                toView: toView,
                browserVC: bvc,
                finalFrame: finalFrame,
                selectedTab: selectedTab
            )
        }
    }

    private func runPresentationAnimation(
        context: UIViewControllerContextTransitioning,
        browserVC: BrowserViewController,
        destinationController: UIViewController,
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

        destinationController.view.frame = finalFrame
        destinationController.view.layoutIfNeeded()

        guard let panel = currentExperimentPanel as? ThemedNavigationController,
              let panelViewController = panel.viewControllers.first as? TabDisplayPanelViewController
        else { return }

        let cv = panelViewController.tabDisplayView.collectionView
        guard let dataSource = cv.dataSource as? TabDisplayDiffableDataSource,
              let item = findItem(by: selectedTab.tabUUID, dataSource: dataSource)
        else { return }
        guard let tabCell = panelViewController.tabDisplayView.selectedTabCell else { return }

        var cellFrame: CGRect?
        if let indexPath = dataSource.indexPath(for: item) {
            cv.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        }
        // TODO: FXIOS-14550 Look into if we can find an alternative to calling layoutIfNeeded() here
        cv.layoutIfNeeded()
        cellFrame = tabCell.backgroundHolder.convert(tabCell.backgroundHolder.bounds, to: nil)
        tabCell.isHidden = true
        tabCell.setUnselectedState(theme: theme)
        tabCell.alpha = UX.clearAlpha

        // Animate
        cv.transform = CGAffineTransform(scaleX: UX.cvScalingFactor, y: UX.cvScalingFactor)
        cv.alpha = UX.halfAlpha

        CATransaction.begin()
        CATransaction.setAnimationDuration(UX.presentDuration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
        CATransaction.setCompletionBlock { [weak self, weak tabCell] in
            snapshotContainer.removeFromSuperview()
            self?.unhideCellBorder(tabCell: tabCell, isPrivate: selectedTab.isPrivate, theme: theme)
        }

        // IMPORTANT NOTE FOR SIMULATOR TESTING
        // The Debug > Slow Animations setting on the simulator does not render this border animation correctly on XCode 16.2
        // Alternative: Make recording of the simulator animation and play it back at a reduced speed or go frame-by-frame.
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
                snapshotContainer.frame = frame
                bvcSnapshot.frame = snapshotContainer.bounds

                snapshotContainer.layer.cornerRadius = ExperimentTabCell.UX.cornerRadius
                bvcSnapshot.layer.cornerRadius = ExperimentTabCell.UX.cornerRadius
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
                snapshotContainer.alpha = UX.clearAlpha
            }
            cv.transform = .identity
            cv.alpha = UX.opaqueAlpha
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
            borderLayer.removeFromSuperlayer()
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
            dismissWithoutTabScreenshot(panelViewController: panelViewController,
                                        contentContainer: contentContainer,
                                        toView: toView,
                                        context: context)
        } else {
            dismissWithTabScreenshot(panelViewController: panelViewController,
                                     contentContainer: contentContainer,
                                     toView: toView,
                                     context: context,
                                     selectedTab: selectedTab,
                                     browserVC: browserVC)
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

        contentContainer.isHidden = true

        toView.layer.cornerCurve = .continuous
        toView.layer.cornerRadius = ExperimentTabCell.UX.cornerRadius
        toView.clipsToBounds = true
        toView.alpha = UX.clearAlpha

        context.containerView.addSubview(toView)
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
            options: .curveEaseOut) {
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
