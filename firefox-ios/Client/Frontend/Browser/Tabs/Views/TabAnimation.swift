// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Shared

extension TabTrayViewController: UIViewControllerTransitioningDelegate {
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

        guard let selectedTab = bvc.tabManager.selectedTab,
              let webView = selectedTab.webView
        else {
            logger.log("Attempted to present the tab tray without having a selected tab",
                       level: .warning,
                       category: .tabs)
            context.completeTransition(true)
            return
        }

        let finalFrame = context.finalFrame(for: destinationController)

        // Tab snapshot animates from web view container on BVC to the cell frame
        let tabSnapshot = UIImageView(image: selectedTab.screenshot ?? .init())
        tabSnapshot.layer.cornerCurve = .continuous
        tabSnapshot.clipsToBounds = true
        tabSnapshot.contentMode = .scaleAspectFill
        tabSnapshot.frame = webView.frame

        // Allow the UI to render to make the snapshotting code more performant

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
        // BVC snapshot animates to the cell
        let bvcSnapshot = UIImageView(image: browserVC.view.snapshot)
        bvcSnapshot.layer.cornerCurve = .continuous
        bvcSnapshot.clipsToBounds = true

        // This background view is needed for animation between the tab tray and the bvc
        let backgroundView = UIView()
        backgroundView.backgroundColor = .init(white: 0.0, alpha: 0.3)
        backgroundView.frame = finalFrame

        context.containerView.addSubview(destinationController.view)
        context.containerView.addSubview(backgroundView)
        context.containerView.addSubview(bvcSnapshot)
        context.containerView.addSubview(tabSnapshot)

        destinationController.view.frame = finalFrame
        destinationController.view.setNeedsLayout()
        destinationController.view.layoutIfNeeded()

        guard let panel = currentPanel as? ThemedNavigationController,
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
            // This is needed otherwise the collection views content offset is incorrect
            cv.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            cv.layoutIfNeeded()
            tabCell = cv.cellForItem(at: indexPath) as? ExperimentTabCell
            if let cell = tabCell {
                cellFrame = cell.backgroundHolder.convert(cell.backgroundHolder.bounds, to: nil)
                // Hide the cell that is being animated since we are making a copy of it to animate in
                cell.isHidden = true
                cell.alpha = 0.0
            }
        }

        cv.transform = .init(scaleX: 1.2, y: 1.2)
        cv.alpha = 0.5
        let animator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 0.825) {
            cv.transform = .identity
            cv.alpha = 1
            if let frame = cellFrame {
                tabSnapshot.frame = frame
                bvcSnapshot.frame = frame
            } else {
                tabSnapshot.alpha = 0.0
                bvcSnapshot.alpha = 0.0
            }
            tabSnapshot.layer.cornerRadius = ExperimentTabCell.UX.cornerRadius
            bvcSnapshot.layer.cornerRadius = ExperimentTabCell.UX.cornerRadius
            backgroundView.alpha = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            tabCell?.isHidden = false
            UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
                tabCell?.alpha = 1
            }.startAnimation()
        }
        animator.addCompletion { _ in
            backgroundView.removeFromSuperview()
            tabSnapshot.removeFromSuperview()
            bvcSnapshot.removeFromSuperview()
            context.completeTransition(true)
        }
        animator.startAnimation()
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
        guard let panel = currentPanel as? ThemedNavigationController,
              let panelViewController = panel.viewControllers.first as? TabDisplayPanelViewController,
              let webView = selectedTab.webView
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
        backgroundView.backgroundColor = .init(white: 0.0, alpha: 0.3)
        backgroundView.alpha = 0
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
        let animator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1.0) {
            cv.transform = .init(scaleX: 1.2, y: 1.2)
            cv.alpha = 0.5

            tabSnapshot.frame = webView.frame
            tabSnapshot.layer.cornerRadius = 0
            toVCSnapshot.frame = finalFrame
            toVCSnapshot.layer.cornerRadius = 0
            backgroundView.alpha = 1
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
