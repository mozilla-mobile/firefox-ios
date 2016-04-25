/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

class TrayToBrowserAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        if let bvc = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as? BrowserViewController,
           let tabTray = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as? TabTrayController {
            transitionFromTray(tabTray, toBrowser: bvc, usingContext: transitionContext)
        }
    }

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.4
    }
}

private extension TrayToBrowserAnimator {
    func transitionFromTray(tabTray: TabTrayController, toBrowser bvc: BrowserViewController, usingContext transitionContext: UIViewControllerContextTransitioning) {
        guard let container = transitionContext.containerView() else { return }
        guard let selectedTab = bvc.tabManager.selectedTab else { return }

        // Bug 1205464 - Top Sites tiles blow up or shrink after rotating
        // Force the BVC's frame to match the tab trays since for some reason on iOS 9 the UILayoutContainer in
        // the UINavigationController doesn't rotate the presenting view controller
        let os = NSProcessInfo().operatingSystemVersion
        switch (os.majorVersion, os.minorVersion, os.patchVersion) {
        case (9, _, _):
            bvc.view.frame = UIWindow().frame
        default:
            break
        }

        let tabManager = bvc.tabManager
        let displayedTabs = selectedTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        guard let expandFromIndex = displayedTabs.indexOf(selectedTab) else { return }

        // Hide browser components
        bvc.toggleSnackBarVisibility(show: false)
        toggleWebViewVisibility(show: false, usingTabManager: bvc.tabManager)
        bvc.homePanelController?.view.hidden = true
        bvc.webViewContainerBackdrop.hidden = true

        // Take a snapshot of the collection view that we can scale/fade out. We don't need to wait for screen updates since it's already rendered on the screen
        let tabCollectionViewSnapshot = tabTray.collectionView.snapshotViewAfterScreenUpdates(false)
        tabTray.collectionView.alpha = 0
        tabCollectionViewSnapshot.frame = tabTray.collectionView.frame
        container.insertSubview(tabCollectionViewSnapshot, atIndex: 0)

        // Create a fake cell to use for the upscaling animation
        let startingFrame = calculateCollapsedCellFrameUsingCollectionView(tabTray.collectionView, atIndex: expandFromIndex)
        let cell = createTransitionCellFromTab(bvc.tabManager.selectedTab, withFrame: startingFrame)
        cell.backgroundHolder.layer.cornerRadius = 0

        container.insertSubview(bvc.view, aboveSubview: tabCollectionViewSnapshot)
        container.insertSubview(cell, aboveSubview: bvc.view)

        // Flush any pending layout/animation code in preperation of the animation call
        container.layoutIfNeeded()


        let finalFrame = calculateExpandedCellFrameFromBVC(bvc)
        bvc.footer.alpha = shouldDisplayFooterForBVC(bvc) ? 1 : 0
        bvc.urlBar.isTransitioning = true

        // Re-calculate the starting transforms for header/footer views in case we switch orientation
        resetTransformsForViews([bvc.header, bvc.headerBackdrop, bvc.readerModeBar, bvc.footer, bvc.footerBackdrop])
        transformHeaderFooterForBVC(bvc, toFrame: startingFrame, container: container)

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

            bvc.tabTrayDidDismiss(tabTray)
            tabTray.toolbar.transform = CGAffineTransformMakeTranslation(0, UIConstants.ToolbarHeight)
            tabCollectionViewSnapshot.transform = CGAffineTransformMakeScale(0.9, 0.9)
            tabCollectionViewSnapshot.alpha = 0
        }, completion: { finished in
            // Remove any of the views we used for the animation
            cell.removeFromSuperview()
            tabCollectionViewSnapshot.removeFromSuperview()
            bvc.footer.alpha = 1
            bvc.toggleSnackBarVisibility(show: true)
            toggleWebViewVisibility(show: true, usingTabManager: bvc.tabManager)
            bvc.webViewContainerBackdrop.hidden = false
            bvc.homePanelController?.view.hidden = false
            bvc.urlBar.isTransitioning = false
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

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.4
    }
}

private extension BrowserToTrayAnimator {
    func transitionFromBrowser(bvc: BrowserViewController, toTabTray tabTray: TabTrayController, usingContext transitionContext: UIViewControllerContextTransitioning) {

        guard let container = transitionContext.containerView() else { return }
        guard let selectedTab = bvc.tabManager.selectedTab else { return }

        let tabManager = bvc.tabManager
        let displayedTabs = selectedTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        guard let scrollToIndex = displayedTabs.indexOf(selectedTab) else { return }

        // Insert tab tray below the browser and force a layout so the collection view can get it's frame right
        container.insertSubview(tabTray.view, belowSubview: bvc.view)

        // Force subview layout on the collection view so we can calculate the correct end frame for the animation
        tabTray.view.layoutSubviews()

        tabTray.collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: scrollToIndex, inSection: 0), atScrollPosition: .CenteredVertically, animated: false)

        // Build a tab cell that we will use to animate the scaling of the browser to the tab
        let expandedFrame = calculateExpandedCellFrameFromBVC(bvc)
        let cell = createTransitionCellFromTab(bvc.tabManager.selectedTab, withFrame: expandedFrame)
        cell.backgroundHolder.layer.cornerRadius = TabTrayControllerUX.CornerRadius
        cell.innerStroke.hidden = true

        // Take a snapshot of the collection view to perform the scaling/alpha effect
        let tabCollectionViewSnapshot = tabTray.collectionView.snapshotViewAfterScreenUpdates(true)
        tabCollectionViewSnapshot.frame = tabTray.collectionView.frame
        tabCollectionViewSnapshot.transform = CGAffineTransformMakeScale(0.9, 0.9)
        tabCollectionViewSnapshot.alpha = 0
        tabTray.view.insertSubview(tabCollectionViewSnapshot, belowSubview: tabTray.toolbar)

        container.addSubview(cell)
        cell.layoutIfNeeded()
        cell.title.transform = CGAffineTransformMakeTranslation(0, -cell.title.frame.size.height)

        // Hide views we don't want to show during the animation in the BVC
        bvc.homePanelController?.view.hidden = true
        bvc.toggleSnackBarVisibility(show: false)
        toggleWebViewVisibility(show: false, usingTabManager: bvc.tabManager)
        bvc.urlBar.isTransitioning = true

        // Since we are hiding the collection view and the snapshot API takes the snapshot after the next screen update,
        // the screenshot ends up being blank unless we set the collection view hidden after the screen update happens. 
        // To work around this, we dispatch the setting of collection view to hidden after the screen update is completed.
        dispatch_async(dispatch_get_main_queue()) {
            tabTray.collectionView.hidden = true
            let finalFrame = calculateCollapsedCellFrameUsingCollectionView(tabTray.collectionView,
                atIndex: scrollToIndex)
            tabTray.toolbar.transform = CGAffineTransformMakeTranslation(0, UIConstants.ToolbarHeight)

            UIView.animateWithDuration(self.transitionDuration(transitionContext),
                delay: 0, usingSpringWithDamping: 1,
                initialSpringVelocity: 0,
                options: UIViewAnimationOptions.CurveEaseInOut,
                animations:
            {
                cell.frame = finalFrame
                cell.title.transform = CGAffineTransformIdentity
                cell.layoutIfNeeded()

                transformHeaderFooterForBVC(bvc, toFrame: finalFrame, container: container)

                bvc.urlBar.updateAlphaForSubviews(0)
                bvc.footer.alpha = 0
                tabCollectionViewSnapshot.alpha = 1

                tabTray.toolbar.transform = CGAffineTransformIdentity
                resetTransformsForViews([tabCollectionViewSnapshot])
            }, completion: { finished in
                // Remove any of the views we used for the animation
                cell.removeFromSuperview()
                tabCollectionViewSnapshot.removeFromSuperview()
                tabTray.collectionView.hidden = false

                bvc.toggleSnackBarVisibility(show: true)
                toggleWebViewVisibility(show: true, usingTabManager: bvc.tabManager)
                bvc.homePanelController?.view.hidden = false

                bvc.urlBar.isTransitioning = false
                transitionContext.completeTransition(true)
            })
        }
    }
}

private func transformHeaderFooterForBVC(bvc: BrowserViewController, toFrame finalFrame: CGRect, container: UIView) {
    let footerForTransform = footerTransform(bvc.footer.frame, toFrame: finalFrame, container: container)
    let headerForTransform = headerTransform(bvc.header.frame, toFrame: finalFrame, container: container)

    bvc.footer.transform = footerForTransform
    bvc.footerBackdrop.transform = footerForTransform
    bvc.header.transform = headerForTransform
    bvc.readerModeBar?.transform = headerForTransform
    bvc.headerBackdrop.transform = headerForTransform
}

private func footerTransform( frame: CGRect, toFrame finalFrame: CGRect, container: UIView) -> CGAffineTransform {
    let frame = container.convertRect(frame, toView: container)
    let endY = CGRectGetMaxY(finalFrame) - (frame.size.height / 2)
    let endX = CGRectGetMidX(finalFrame)
    let translation = CGPoint(x: endX - CGRectGetMidX(frame), y: endY - CGRectGetMidY(frame))

    let scaleX = finalFrame.width / frame.width

    var transform = CGAffineTransformIdentity
    transform = CGAffineTransformTranslate(transform, translation.x, translation.y)
    transform = CGAffineTransformScale(transform, scaleX, scaleX)
    return transform
}

private func headerTransform(frame: CGRect, toFrame finalFrame: CGRect, container: UIView) -> CGAffineTransform {
    let frame = container.convertRect(frame, toView: container)
    let endY = CGRectGetMinY(finalFrame) + (frame.size.height / 2)
    let endX = CGRectGetMidX(finalFrame)
    let translation = CGPoint(x: endX - CGRectGetMidX(frame), y: endY - CGRectGetMidY(frame))

    let scaleX = finalFrame.width / frame.width

    var transform = CGAffineTransformIdentity
    transform = CGAffineTransformTranslate(transform, translation.x, translation.y)
    transform = CGAffineTransformScale(transform, scaleX, scaleX)
    return transform
}

//MARK: Private Helper Methods
private func calculateCollapsedCellFrameUsingCollectionView(collectionView: UICollectionView, atIndex index: Int) -> CGRect {
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
    } else if AboutUtils.isAboutURL(bvc.tabManager.selectedTab?.url) && bvc.toolbar == nil {
        frame.size.height += UIConstants.ToolbarHeight
    }

    return frame
}

private func shouldDisplayFooterForBVC(bvc: BrowserViewController) -> Bool {
    return bvc.shouldShowFooterForTraitCollection(bvc.traitCollection) && !AboutUtils.isAboutURL(bvc.tabManager.selectedTab?.url)
}

private func toggleWebViewVisibility(show show: Bool, usingTabManager tabManager: TabManager) {
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
            toolbar?.transform = CGAffineTransformMakeRectToRect(toolbarFrame, toFrame: endRect)
        }
    }
}

private func createTransitionCellFromTab(tab: Tab?, withFrame frame: CGRect) -> TabCell {
    let cell = TabCell(frame: frame)
    cell.background.image = tab?.screenshot
    cell.titleText.text = tab?.displayTitle

    if let tab = tab where tab.isPrivate {
        cell.style = .Dark
    }

    if let favIcon = tab?.displayFavicon {
        cell.favicon.sd_setImageWithURL(NSURL(string: favIcon.url)!)
    } else {
        var defaultFavicon = UIImage(named: "defaultFavicon")
        if tab?.isPrivate ?? false {
            defaultFavicon = defaultFavicon?.imageWithRenderingMode(.AlwaysTemplate)
            cell.favicon.image = defaultFavicon
            cell.favicon.tintColor = (tab?.isPrivate ?? false) ? UIColor.whiteColor() : UIColor.darkGrayColor()
        } else {
            cell.favicon.image = defaultFavicon
        }
    }
    return cell
}
