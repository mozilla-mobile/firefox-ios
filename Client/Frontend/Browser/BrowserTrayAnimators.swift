/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class TrayToBrowserAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        if let bvc = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as? BrowserViewController,
           let tabTray = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as? TabTrayController {
            transitionFromTray(tabTray, toBrowser: bvc, usingContext: transitionContext)
        }
    }

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.4
    }
}

private extension TrayToBrowserAnimator {
    func transitionFromTray(tabTray: TabTrayController, toBrowser bvc: BrowserViewController, usingContext transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView()

        // Hide browser components
        toggleWebViewVisibility(show: false, usingTabManager: bvc.tabManager)
        bvc.homePanelController?.view.hidden = true

        // Take a snapshot of the collection view that we can scale/fade out. We don't need to wait for screen updates since it's already rendered on the screen
        let tabCollectionViewSnapshot = tabTray.collectionView.snapshotViewAfterScreenUpdates(false)
        tabTray.collectionView.alpha = 0
        tabCollectionViewSnapshot.frame = tabTray.collectionView.frame
        container.insertSubview(tabCollectionViewSnapshot, aboveSubview: tabTray.view)

        // Create a fake cell to use for the upscaling animation
        let cell = createTransitionCellFromBrowser(bvc.tabManager.selectedTab, withFrame: calculateCollapsedCellFrameUsingCollectionView(tabTray.collectionView, atIndex: bvc.tabManager.selectedIndex))
        cell.backgroundHolder.layer.cornerRadius = 0

        container.insertSubview(bvc.view, aboveSubview: tabCollectionViewSnapshot)
        container.insertSubview(cell, aboveSubview: bvc.view)

        // Flush any pending layout/animation code in preperation of the animation call
        container.layoutIfNeeded()

        // Reset any transform we had previously on the header and transform them to where the cell will be animating from
        transformToolbarsToFrame([bvc.header, bvc.footer, bvc.readerModeBar], toRect: cell.frame)

        let finalFrame = calculateExpandedCellFrameFromBVC(bvc)
        bvc.footer.alpha = shouldDisplayFooterForBVC(bvc) ? 1 : 0

        UIView.animateWithDuration(self.transitionDuration(transitionContext),
            delay: 0, usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: UIViewAnimationOptions.CurveEaseInOut,
            animations:
        {
            // Scale up the cell and reset the transforms for the header/footers
            cell.frame = finalFrame
            container.layoutIfNeeded()
            cell.title.transform = CGAffineTransformMakeTranslation(0, -cell.title.frame.height)
            resetTransformsForViews([bvc.header, bvc.footer, bvc.readerModeBar])

            bvc.urlBar.updateAlphaForSubviews(1)

            tabCollectionViewSnapshot.transform = CGAffineTransformMakeScale(0.9, 0.9)
            tabCollectionViewSnapshot.alpha = 0

            // Push out the navigation bar buttons
            let buttonOffset = tabTray.addTabButton.frame.width + TabTrayControllerUX.ToolbarButtonOffset
            tabTray.addTabButton.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, buttonOffset , 0)
            tabTray.settingsButton.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, -buttonOffset , 0)
        }, completion: { finished in
            // Remove any of the views we used for the animation
            cell.removeFromSuperview()
            tabCollectionViewSnapshot.removeFromSuperview()
            bvc.footer.alpha = 1
            bvc.startTrackingAccessibilityStatus()
            toggleWebViewVisibility(show: true, usingTabManager: bvc.tabManager)
            bvc.homePanelController?.view.hidden = false
            transitionContext.completeTransition(true)
        })
    }
}

class BrowserToTrayAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        if let bvc = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as? BrowserViewController,
           let tabTray = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as? TabTrayController {
            transitionFromBrowser(bvc, toTabTray: tabTray, usingContext: transitionContext)
        }
    }

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.4
    }
}

private extension BrowserToTrayAnimator {
    func transitionFromBrowser(bvc: BrowserViewController, toTabTray tabTray: TabTrayController, usingContext transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView()

        // Insert tab tray below the browser and force a layout so the collection view can get it's frame right
        container.insertSubview(tabTray.view, belowSubview: bvc.view)

        // Force subview layout on the collection view so we can calculate the correct end frame for the animation
        tabTray.view.layoutSubviews()
        if tabTray.collectionView.numberOfItemsInSection(0) > bvc.tabManager.selectedIndex {
            tabTray.collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: bvc.tabManager.selectedIndex, inSection: 0), atScrollPosition: .CenteredVertically, animated: false)
        }

        // Build a tab cell that we will use to animate the scaling of the browser to the tab
        let expandedFrame = calculateExpandedCellFrameFromBVC(bvc)
        let cell = createTransitionCellFromBrowser(bvc.tabManager.selectedTab, withFrame: expandedFrame)
        cell.backgroundHolder.layer.cornerRadius = TabTrayControllerUX.CornerRadius
        cell.innerStroke.hidden = true

        // Take a snapshot of the collection view to perform the scaling/alpha effect
        let tabCollectionViewSnapshot = tabTray.collectionView.snapshotViewAfterScreenUpdates(true)
        tabCollectionViewSnapshot.frame = tabTray.collectionView.frame
        tabCollectionViewSnapshot.transform = CGAffineTransformMakeScale(0.9, 0.9)
        tabCollectionViewSnapshot.alpha = 0
        tabTray.view.addSubview(tabCollectionViewSnapshot)

        container.addSubview(cell)
        cell.layoutIfNeeded()
        cell.title.transform = CGAffineTransformMakeTranslation(0, -cell.title.frame.size.height)

        // Hide views we don't want to show during the animation in the BVC
        bvc.homePanelController?.view.hidden = true
        toggleWebViewVisibility(show: false, usingTabManager: bvc.tabManager)

        // Since we are hiding the collection view and the snapshot API takes the snapshot after the next screen update,
        // the screenshot ends up being blank unless we set the collection view hidden after the screen update happens. 
        // To work around this, we dispatch the setting of collection view to hidden after the screen update is completed.
        dispatch_async(dispatch_get_main_queue()) {
            tabTray.collectionView.hidden = true

            let finalFrame = calculateCollapsedCellFrameUsingCollectionView(tabTray.collectionView, atIndex: bvc.tabManager.selectedIndex)

            UIView.animateWithDuration(self.transitionDuration(transitionContext),
                delay: 0, usingSpringWithDamping: 1,
                initialSpringVelocity: 0,
                options: UIViewAnimationOptions.CurveEaseInOut,
                animations:
            {
                cell.frame = finalFrame
                cell.title.transform = CGAffineTransformIdentity
                cell.layoutIfNeeded()
                transformToolbarsToFrame([bvc.header, bvc.footer, bvc.readerModeBar], toRect: finalFrame)

                bvc.urlBar.updateAlphaForSubviews(0)
                bvc.footer.alpha = 0
                tabCollectionViewSnapshot.alpha = 1

                resetTransformsForViews([tabCollectionViewSnapshot, tabTray.addTabButton, tabTray.settingsButton])
            }, completion: { finished in
                // Remove any of the views we used for the animation
                cell.removeFromSuperview()
                tabCollectionViewSnapshot.removeFromSuperview()
                tabTray.collectionView.hidden = false

                toggleWebViewVisibility(show: true, usingTabManager: bvc.tabManager)
                bvc.homePanelController?.view.hidden = false
                bvc.stopTrackingAccessibilityStatus()

                transitionContext.completeTransition(true)
            })
        }
    }
}

//MARK: Private Helper Methods
private func calculateCollapsedCellFrameUsingCollectionView(collectionView: UICollectionView, atIndex index: Int) -> CGRect {
    var frame: CGRect?
    if let attr = collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0)) {
        return collectionView.convertRect(attr.frame, toView: collectionView.superview)
    } else {
        return CGRectZero
    }
}

private func calculateExpandedCellFrameFromBVC(bvc: BrowserViewController) -> CGRect {
    var frame = bvc.webViewContainer.frame

    // If we're navigating to a home panel and we were expecting to show the toolbar, add more height to end frame since
    // there is no toolbar for home panels
    if !bvc.shouldShowFooterForTraitCollection(bvc.traitCollection) {
        return frame
    } else if AboutUtils.isAboutURL(bvc.tabManager.selectedTab?.url) {
        frame.size.height += UIConstants.ToolbarHeight
    }

    return frame
}

private func shouldDisplayFooterForBVC(bvc: BrowserViewController) -> Bool {
    return bvc.shouldShowFooterForTraitCollection(bvc.traitCollection) && !AboutUtils.isAboutURL(bvc.tabManager.selectedTab?.url)
}

private func toggleWebViewVisibility(#show: Bool, usingTabManager tabManager: TabManager) {
    for i in 0..<tabManager.count {
        if let tab = tabManager[i] {
            tab.webView?.hidden = !show
        }
    }
}

private func resetTransformsForViews(views: [UIView?]) {
    for view in views {
        // Reset back to origin
        view?.transform = CGAffineTransformIdentity
    }
}

private func transformToolbarsToFrame(toolbars: [UIView?], toRect endRect: CGRect) {
    for toolbar in toolbars {
        // Reset back to origin
        toolbar?.transform = CGAffineTransformIdentity

        // Transform from origin to where we want them to end up
        if let toolbarFrame = toolbar?.frame {
            toolbar?.transform = CGAffineTransformMakeRectToRect(toolbarFrame, endRect)
        }
    }
}

private func createTransitionCellFromBrowser(browser: Browser?, withFrame frame: CGRect) -> TabCell {
    let cell = TabCell(frame: frame)
    cell.background.image = browser?.screenshot
    cell.titleText.text = browser?.displayTitle
    if let favIcon = browser?.displayFavicon {
        cell.favicon.sd_setImageWithURL(NSURL(string: favIcon.url)!)
    } else {
        cell.favicon.image = UIImage(named: "defaultFavicon")
    }
    return cell
}