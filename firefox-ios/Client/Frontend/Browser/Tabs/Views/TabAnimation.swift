// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension TabTrayViewController: UIViewControllerTransitioningDelegate {
    func animationController(
      forPresented presented: UIViewController,
      presenting: UIViewController,
      source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
      return nil
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}

extension TabTrayViewController: BasicAnimationControllerDelegate {
  func animatePresentation(context: UIViewControllerContextTransitioning) {
    guard
      let containerController = context.viewController(forKey: .from) as? UINavigationController,
      let bvc = containerController.topViewController as? BrowserViewController,
      let destinationController = context.viewController(forKey: .to)
    else {
      logger.module.error(
        """
            Attempted to present the tab tray on something that is not a BrowserViewController which is
            currently unsupported.
        """
      )
      context.completeTransition(true)
      return
    }

    guard let selectedTab = tabManager.selectedTab else {
      logger.module.error("Attempted to present the tab tray without having a selected tab")
      context.completeTransition(true)
      return
    }

    let finalFrame = context.finalFrame(for: destinationController)

    // Tab snapshot animates from web view container on BVC to the cell frame
    let tabSnapshot = UIImageView(image: selectedTab.screenshot ?? .init())
    tabSnapshot.layer.cornerCurve = .continuous
    tabSnapshot.clipsToBounds = true
    tabSnapshot.contentMode = .scaleAspectFill
    tabSnapshot.frame = bvc.webViewContainer.frame

    // Allow the UI to render to make the snapshotting code more performant
    // swiftlint:disable closure_body_length
    DispatchQueue.main.async { [self] in
      // BVC snapshot animates to the cell
      let bvcSnapshot = UIImageView(image: bvc.view.snapshot)
      bvcSnapshot.layer.cornerCurve = .continuous
      bvcSnapshot.clipsToBounds = true

      // Just a small background view for animation sake between the tab tray and the bvc
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

      let cv = tabTrayView.collectionView
      cv.reloadData()
      var tabCell: TabCell?
      var cellFrame: CGRect?
      var cellTitleSnapshot: UIView?
      if let indexPath = dataSource.indexPath(for: selectedTab) {
        // This is needed for some reason otherwise the collection views content offset is
        // incorrect.
        cv.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        cv.layoutIfNeeded()
        tabCell = cv.cellForItem(at: indexPath) as? TabCell
        if let cell = tabCell {
          // Hide the cell that is being animated too since we are making a copy of it to animate in
          cellFrame = cv.convert(cell.frame, to: view)

          // For animations sake we are also making a copy of the title and animating it in closer to
          // the animation finish
          let titleSnapshot = UIImageView(image: cell.titleBackgroundView.snapshot)
          titleSnapshot.contentMode = .scaleToFill
          titleSnapshot.clipsToBounds = true
          tabSnapshot.addSubview(titleSnapshot)
          titleSnapshot.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
          }
          titleSnapshot.alpha = 0.0
          cellTitleSnapshot = titleSnapshot

          tabSnapshot.setNeedsLayout()
          tabSnapshot.layoutIfNeeded()

          cell.isHidden = true
          cell.alpha = 0.0
        }
      }

      // Just for flourish, scaling the collection view a bit
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
        tabSnapshot.layer.cornerRadius = TabCell.UX.cornerRadius
        bvcSnapshot.layer.cornerRadius = TabCell.UX.cornerRadius
        backgroundView.alpha = 0
      }
      // Need delayed animation for these
      animator.addAnimations(
        {
          cellTitleSnapshot?.alpha = 1.0
        },
        delayFactor: 0.5
      )
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
    // swiftlint:enable closure_body_length
  }

  func animateDismissal(context: UIViewControllerContextTransitioning) {
    guard let toViewController = context.viewController(forKey: .to),
      let toView = context.view(forKey: .to)
    else {
      Logger.module.error(
        """
            Attempted to dismiss the tab tray without a view to dismiss from.

            Likely the `modalPresentationStyle` was changed away from `fullScreen` and should be changed
            back if using this custom animation.
        """
      )
      context.completeTransition(true)
      return
    }

    guard let containerController = toViewController as? UINavigationController,
      let bvc = containerController.topViewController as? BrowserViewController
    else {
      Logger.module.error(
        """
            Attempted to dismiss the tab tray from something that is not a BrowserViewController which is
            currently unsupported.
        """
      )
      context.completeTransition(true)
      return
    }

    // Tab screenshot will animate from the cell to the bvc web container
    let tabSnapshot = UIImageView(image: tabManager.selectedTab?.screenshot ?? .init())
    tabSnapshot.layer.cornerCurve = .continuous
    tabSnapshot.clipsToBounds = true
    tabSnapshot.contentMode = .scaleAspectFill
    tabSnapshot.layer.cornerRadius = TabCell.UX.cornerRadius
    tabSnapshot.isHidden = true

    let finalFrame = context.finalFrame(for: toViewController)

    toView.frame = finalFrame

    // Allow the UI to render to make the snapshotting code more performant
    // swiftlint:disable closure_body_length
    DispatchQueue.main.async { [self] in
      // Just a small background view for animation sake between the tab tray and the bvc
      let backgroundView = UIView()
      backgroundView.backgroundColor = .init(white: 0.0, alpha: 0.3)
      backgroundView.alpha = 0
      backgroundView.frame = finalFrame

      context.containerView.addSubview(toView)
      context.containerView.addSubview(backgroundView)

      toView.setNeedsLayout()
      toView.layoutIfNeeded()

      // BVC snapshot animates from the cell to its final resting spot
      let toVCSnapshot: UIView =
        toView.snapshotView(afterScreenUpdates: true) ?? UIImageView(image: toView.snapshot)
      toVCSnapshot.layer.cornerCurve = .continuous
      toVCSnapshot.layer.cornerRadius = TabCell.UX.cornerRadius
      toVCSnapshot.clipsToBounds = true

      context.containerView.addSubview(toVCSnapshot)
      context.containerView.addSubview(tabSnapshot)

      // Hide the destination as we're animating a snapshot into place
      toView.isHidden = true

      let cv = tabTrayView.collectionView
      cv.reloadData()

      var tabCell: TabCell?
      var cellTitleSnapshot: UIView?
      if let tab = tabManager.selectedTab, let indexPath = dataSource.indexPath(for: tab) {
        // This is needed for some reason otherwise the collection views content offest is
        // incorrect.
        cv.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        cv.layoutIfNeeded()

        if let cell = cv.cellForItem(at: indexPath) as? TabCell {
          tabCell = cell

          tabSnapshot.frame = cv.convert(cell.frame, to: view)
          toVCSnapshot.frame = tabSnapshot.frame

          let titleSnapshot = UIImageView(image: cell.titleBackgroundView.snapshot)
          titleSnapshot.contentMode = .scaleToFill
          titleSnapshot.clipsToBounds = true
          tabSnapshot.addSubview(titleSnapshot)
          titleSnapshot.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
          }
          cellTitleSnapshot = titleSnapshot
          tabSnapshot.setNeedsLayout()
          tabSnapshot.layoutIfNeeded()

          cell.isHidden = true
        }
      }
      tabSnapshot.isHidden = false
      let animator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1.0) {
        // For some flourish
        cv.transform = .init(scaleX: 1.2, y: 1.2)
        cv.alpha = 0.5

        tabSnapshot.frame = bvc.webViewContainer.frame
        tabSnapshot.layer.cornerRadius = 0
        toVCSnapshot.frame = finalFrame
        toVCSnapshot.layer.cornerRadius = 0
        backgroundView.alpha = 1
      }
      if let titleSnapshot = cellTitleSnapshot {
        // Need a quicker animation for this one
        UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
          titleSnapshot.alpha = 0
        }
        .startAnimation()
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
    // swiftlint:enable closure_body_length
  }
}
