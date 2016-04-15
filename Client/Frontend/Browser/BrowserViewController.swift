/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import WebKit
import Storage
import Snap

private let OKString = NSLocalizedString("OK", comment: "OK button")
private let CancelString = NSLocalizedString("Cancel", comment: "Cancel button")

private let KVOLoading = "loading"
private let KVOEstimatedProgress = "estimatedProgress"
private let HomeURL = "about:home"

class BrowserViewController: UIViewController {
    private var urlBar: URLBarView!
    private var readerModeBar: ReaderModeBarView!
    private var toolbar: BrowserToolbar?
    private var tabManager: TabManager!
    private var homePanelController: HomePanelViewController?
    private var searchController: SearchViewController?
    private var webViewContainer: UIView!
    private let uriFixup = URIFixup()
    private var screenshotHelper: ScreenshotHelper!
    private var homePanelIsInline: Bool = false

    var profile: Profile!

    // These views wrap the urlbar and toolbar to provide background effects on them
    private var header: UIView!
    private var footer: UIView!
    private var footerBackground: UIView?
    private var previousScroll: CGPoint? = nil

    init() {
        super.init(nibName: nil, bundle: nil)
        didInit()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        didInit()
    }

    private func didInit() {
        let defaultURL = NSURL(string: HomeURL)!
        let defaultRequest = NSURLRequest(URL: defaultURL)
        tabManager = TabManager(defaultNewTabRequest: defaultRequest)
        screenshotHelper = BrowserScreenshotHelper(controller: self)
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        if header == nil {
            return UIStatusBarStyle.LightContent
        }
        if header.transform.ty == 0 {
            return UIStatusBarStyle.LightContent
        }
        return UIStatusBarStyle.Default
    }

    private func shouldShowToolbar() -> Bool {
        return traitCollection.verticalSizeClass != .Compact && traitCollection.horizontalSizeClass != .Regular
    }

    private func updateToolbarState() {
        let showToolbar = shouldShowToolbar()

        urlBar.setShowToolbar(!showToolbar)
        toolbar?.removeFromSuperview()
        toolbar?.browserToolbarDelegate = nil
        footerBackground?.removeFromSuperview()
        footerBackground = nil
        toolbar = nil

        if showToolbar {
            toolbar = BrowserToolbar()
            toolbar?.browserToolbarDelegate = self
            footerBackground = wrapInEffect(toolbar!, parent: footer)
        }

        view.setNeedsUpdateConstraints()
        if let home = homePanelController {
            home.view.setNeedsUpdateConstraints()
        }

        if let tab = tabManager.selectedTab {
            tab.webView.scrollView.contentInset = UIEdgeInsetsMake(AppConstants.ToolbarHeight + AppConstants.StatusBarHeight, 0, toolbar?.frame.height ?? 0, 0)
        }
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        updateToolbarState()
        super.traitCollectionDidChange(previousTraitCollection)
    }

    override func viewDidLoad() {
        webViewContainer = UIView()
        view.addSubview(webViewContainer)

        // Setup the URL bar, wrapped in a view to get transparency effect
        urlBar = URLBarView()
        urlBar.setTranslatesAutoresizingMaskIntoConstraints(false)
        urlBar.delegate = self
        header = wrapInEffect(urlBar, parent: view)
        urlBar.browserToolbarDelegate = self

        // Setup the reader mode control bar. This bar starts not visible with a zero height.
        readerModeBar = ReaderModeBarView(frame: CGRectZero)
        readerModeBar.delegate = self
        view.addSubview(readerModeBar)
        readerModeBar.hidden = true

        footer = UIView()
        self.view.addSubview(footer)

        tabManager.delegate = self
        tabManager.addTab()
        super.viewDidLoad()
    }

    override func updateViewConstraints() {
        webViewContainer.snp_remakeConstraints { make in
            make.edges.equalTo(self.view)
            return
        }

        urlBar.snp_remakeConstraints { make in
            make.edges.equalTo(self.header)
            return
        }

        header.snp_remakeConstraints { make in
            make.top.equalTo(self.view.snp_top)
            make.height.equalTo(AppConstants.ToolbarHeight + AppConstants.StatusBarHeight)
            make.leading.trailing.equalTo(self.view)
        }
        header.setNeedsUpdateConstraints()

        readerModeBar.snp_remakeConstraints { make in
            make.top.equalTo(self.header.snp_bottom)
            make.height.equalTo(AppConstants.ToolbarHeight)
            make.leading.trailing.equalTo(self.view)
        }

        // Setup the bottom toolbar
        toolbar?.snp_remakeConstraints { make in
            make.edges.equalTo(self.footerBackground!)
            make.height.equalTo(AppConstants.ToolbarHeight)
        }

        adjustFooterSize()
        footerBackground?.snp_remakeConstraints { make in
            make.bottom.left.right.equalTo(self.footer)
            make.height.equalTo(AppConstants.ToolbarHeight)
        }
        urlBar.setNeedsUpdateConstraints()

        // Remake constraints even if we're already showing the home controller.
        // The home controller may change sizes if we tap the URL bar while on about:home.
        homePanelController?.view.snp_remakeConstraints { make in
            make.top.equalTo(self.urlBar.snp_bottom)
            make.left.right.equalTo(self.view)
            let url = self.tabManager.selectedTab?.url
            if url?.absoluteString == HomeURL && self.homePanelIsInline {
                make.bottom.equalTo(self.toolbar?.snp_top ?? self.view.snp_bottom)
            } else {
                make.bottom.equalTo(self.view.snp_bottom)
            }
        }

        super.updateViewConstraints()
    }

    private func wrapInEffect(view: UIView, parent: UIView) -> UIView {
        let effect = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))
        effect.setTranslatesAutoresizingMaskIntoConstraints(false)

        view.backgroundColor = UIColor.clearColor()
        effect.addSubview(view)

        parent.addSubview(effect)
        return effect
    }

    private func showHomePanelController(#inline: Bool) {
        homePanelIsInline = inline

        if homePanelController == nil {
            homePanelController = HomePanelViewController()
            homePanelController!.profile = profile
            homePanelController!.delegate = self
            homePanelController!.url = tabManager.selectedTab?.displayURL

            view.addSubview(homePanelController!.view)
            addChildViewController(homePanelController!)
        }
        view.setNeedsUpdateConstraints()
    }

    private func hideHomePanelController() {
        if let controller = homePanelController {
            controller.view.removeFromSuperview()
            controller.removeFromParentViewController()
            homePanelController = nil
        }
    }

    private func updateInContentHomePanel(url: NSURL?) {
        if !urlBar.isEditing {
            if url?.absoluteString == HomeURL {
                showHomePanelController(inline: true)
            } else {
                hideHomePanelController()
            }
        }
    }

    private func showSearchController() {
        if searchController != nil {
            return
        }

        searchController = SearchViewController()
        searchController!.searchEngines = profile.searchEngines
        searchController!.searchDelegate = self
        searchController!.profile = self.profile

        view.addSubview(searchController!.view)
        searchController!.view.snp_makeConstraints { make in
            make.top.equalTo(self.urlBar.snp_bottom)
            make.left.right.bottom.equalTo(self.view)
            return
        }

        addChildViewController(searchController!)
    }

    private func hideSearchController() {
        if let searchController = searchController {
            searchController.view.removeFromSuperview()
            searchController.removeFromParentViewController()
            self.searchController = nil
        }
    }

    private func finishEditingAndSubmit(var url: NSURL) {
        urlBar.updateURL(url)
        urlBar.finishEditing()

        if let tab = tabManager.selectedTab {
            tab.loadRequest(NSURLRequest(URL: url))
        }
    }

    private func addBookmark(url: String, title: String?) {
        let shareItem = ShareItem(url: url, title: title, favicon: nil)
        profile.bookmarks.shareItem(shareItem)

        // Dispatch to the main thread to update the UI
        dispatch_async(dispatch_get_main_queue()) { _ in
            self.toolbar?.updateBookmarkStatus(true)
            self.urlBar.updateBookmarkStatus(true)
        }
    }

    private func removeBookmark(url: String) {
        var bookmark = BookmarkItem(guid: "", title: "", url: url)
        profile.bookmarks.remove(bookmark, success: { success in
            self.toolbar?.updateBookmarkStatus(!success)
            self.urlBar.updateBookmarkStatus(!success)
        }, failure: { err in
                println("Err removing bookmark \(err)")
        })
    }

    override func accessibilityPerformEscape() -> Bool {
        if let selectedTab = tabManager.selectedTab {
            if selectedTab.canGoBack {
                tabManager.selectedTab?.goBack()
                return true
            }
        }
        return false
    }

    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        if object as? WKWebView !== tabManager.selectedTab?.webView {
            return
        }

        switch keyPath {
        case KVOEstimatedProgress:
            urlBar.updateProgressBar(change[NSKeyValueChangeNewKey] as! Float)
        case KVOLoading:
            toolbar?.updateReloadStatus(change[NSKeyValueChangeNewKey] as! Bool)
            urlBar.updateReloadStatus(change[NSKeyValueChangeNewKey] as! Bool)
        default:
            assertionFailure("Unhandled KVO key: \(keyPath)")
        }
    }
}


extension BrowserViewController: URLBarDelegate {
    func urlBarDidPressReload(urlBar: URLBarView) {
        tabManager.selectedTab?.reload()
    }

    func urlBarDidPressStop(urlBar: URLBarView) {
        tabManager.selectedTab?.stop()
    }

    func urlBarDidPressTabs(urlBar: URLBarView) {
        let controller = TabTrayController()
        controller.profile = profile
        controller.tabManager = tabManager
        controller.transitioningDelegate = self
        controller.modalPresentationStyle = .Custom
        controller.screenshotHelper = screenshotHelper
        presentViewController(controller, animated: true, completion: nil)
    }

    func urlBarDidPressReaderMode(urlBar: URLBarView) {
        if let tab = tabManager.selectedTab {
            if let readerMode = tab.getHelper(name: "ReaderMode") as? ReaderMode {
                switch readerMode.state {
                case .Available:
                    enableReaderMode()
                case .Active:
                    disableReaderMode()
                case .Unavailable:
                    break
                }
            }
        }
    }

    func urlBarDidLongPressReaderMode(urlBar: URLBarView) {
        if let tab = tabManager.selectedTab {
            if var url = tab.displayURL {
                if let absoluteString = url.absoluteString {
                    profile.readingList.add(item: ReadingListItem(url: absoluteString, title: tab.title)) { (success) -> Void in
                        if success {
                            // TODO Update reading view bar when that has been hooked up
                        }
                    }
                }
            }
        }
    }

    func urlBarDidLongPressLocation(urlBar: URLBarView) {
        let longPressAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

        let pasteboardContents = UIPasteboard.generalPasteboard().string

        // Check if anything is on the pasteboard
        if pasteboardContents != nil {
            let pasteAndGoAction = UIAlertAction(title: NSLocalizedString("Paste & Go", comment: "Paste the URL into the location bar and visit"), style: .Default, handler: { (alert: UIAlertAction!) -> Void in
                self.urlBar(urlBar, didSubmitText: pasteboardContents!)
            })
            longPressAlertController.addAction(pasteAndGoAction)

            let pasteAction = UIAlertAction(title: NSLocalizedString("Paste", comment: "Paste the URL into the location bar"), style: .Default, handler: { (alert: UIAlertAction!) -> Void in
                urlBar.updateURLBarText(pasteboardContents!)
            })
            longPressAlertController.addAction(pasteAction)
        }

        let copyAddressAction = UIAlertAction(title: NSLocalizedString("Copy Address", comment: "Copy the URL from the location bar"), style: .Default, handler: { (alert: UIAlertAction!) -> Void in
            UIPasteboard.generalPasteboard().string = urlBar.currentURL().absoluteString
        })
        longPressAlertController.addAction(copyAddressAction)

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel alert view"), style: .Cancel, handler: nil)
        longPressAlertController.addAction(cancelAction)

        if let popoverPresentationController = longPressAlertController.popoverPresentationController {
            popoverPresentationController.sourceView = urlBar
            popoverPresentationController.sourceRect = urlBar.frame
            popoverPresentationController.permittedArrowDirections = .Any
        }
        self.presentViewController(longPressAlertController, animated: true, completion: nil)
    }

    func urlBar(urlBar: URLBarView, didEnterText text: String) {
        if text.isEmpty {
            hideSearchController()
        } else {
            showSearchController()
            searchController!.searchQuery = text
        }
    }

    func urlBar(urlBar: URLBarView, didSubmitText text: String) {
        var url = uriFixup.getURL(text)

        // If we can't make a valid URL, do a search query.
        if url == nil {
            url = profile.searchEngines.defaultEngine.searchURLForQuery(text)
        }

        // If we still don't have a valid URL, something is broken. Give up.
        if url == nil {
            println("Error handling URL entry: " + text)
            return
        }

        finishEditingAndSubmit(url!)
    }

    func urlBarDidBeginEditing(urlBar: URLBarView) {
        showHomePanelController(inline: false)
    }

    func urlBarDidEndEditing(urlBar: URLBarView) {
        hideSearchController()
        updateInContentHomePanel(tabManager.selectedTab?.url)
    }
}

extension BrowserViewController: BrowserToolbarDelegate {
    func browserToolbarDidPressBack(browserToolbar: BrowserToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.goBack()
    }

    func browserToolbarDidLongPressBack(browserToolbar: BrowserToolbarProtocol, button: UIButton) {
        let controller = BackForwardListViewController()
        controller.listData = tabManager.selectedTab?.backList
        controller.tabManager = tabManager
        presentViewController(controller, animated: true, completion: nil)
    }

    func browserToolbarDidPressReload(browserToolbar: BrowserToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.reload()
    }

    func browserToolbarDidPressStop(browserToolbar: BrowserToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.stop()
    }

    func browserToolbarDidPressForward(browserToolbar: BrowserToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.goForward()
    }

    func browserToolbarDidLongPressForward(browserToolbar: BrowserToolbarProtocol, button: UIButton) {
        let controller = BackForwardListViewController()
        controller.listData = tabManager.selectedTab?.forwardList
        controller.tabManager = tabManager
        presentViewController(controller, animated: true, completion: nil)
    }

    func browserToolbarDidPressBookmark(browserToolbar: BrowserToolbarProtocol, button: UIButton) {
        if let tab = tabManager.selectedTab {
            if let url = tab.displayURL?.absoluteString {
                profile.bookmarks.isBookmarked(url,
                    success: { isBookmarked in
                        if isBookmarked {
                            self.removeBookmark(url)
                        } else {
                            self.addBookmark(url, title: tab.title)
                        }
                    },
                    failure: { err in
                        println("Bookmark error: \(err)")
                    }
                )
            } else {
                println("Bookmark error: Couldn't find a URL for this tab")
            }
        } else {
            println("Bookmark error: No tab is selected")
        }
    }

    func browserToolbarDidLongPressBookmark(browserToolbar: BrowserToolbarProtocol, button: UIButton) {
    }

    func browserToolbarDidPressShare(browserToolbar: BrowserToolbarProtocol, button: UIButton) {
        if let selected = tabManager.selectedTab {
            if let url = selected.displayURL {
                var activityViewController = UIActivityViewController(activityItems: [selected.title ?? url.absoluteString!, url], applicationActivities: nil)
                // Hide 'Add to Reading List' which currently uses Safari
                activityViewController.excludedActivityTypes = [UIActivityTypeAddToReadingList]
                if let popoverPresentationController = activityViewController.popoverPresentationController {
                    // Using the button for the sourceView here results in this not showing on iPads.
                    popoverPresentationController.sourceView = toolbar ?? urlBar
                    popoverPresentationController.sourceRect = button.frame ?? button.frame
                    popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirection.Up
                }
                presentViewController(activityViewController, animated: true, completion: nil)
            }
        }
    }
}


extension BrowserViewController: BrowserDelegate {
    private func findSnackbar(bars: [AnyObject], barToFind: SnackBar) -> Int? {
        for (index, bar) in enumerate(bars) {
            if bar === barToFind {
                return index
            }
        }
        return nil
    }

    private func adjustFooterSize(top: UIView? = nil) {
        footer.snp_remakeConstraints { make in
            let bars = self.footer.subviews
            make.bottom.equalTo(self.view.snp_bottom)

            if let top = top {
                make.top.equalTo(top.snp_top)
            } else if bars.count > 0 {
                if let bar = bars[bars.count-1] as? SnackBar {
                    make.top.equalTo(bar.snp_top)
                } else {
                    make.top.equalTo(self.toolbar?.snp_top ?? self.view.snp_bottom)
                }
            }

            make.leading.trailing.equalTo(self.view)
        }
    }

    // This removes the bar from its superview and updates constraints appropriately
    private func finishRemovingBar(bar: SnackBar) {
        // If there was a bar above this one, we need to remake its constraints so that it doesn't
        // try to sit about "this" bar anymore.
        let bars = footer.subviews
        if let index = findSnackbar(bars, barToFind: bar) {
            if index < bars.count-1 {
                if var nextbar = bars[index+1] as? SnackBar {
                    nextbar.snp_remakeConstraints { make in
                        if index > 1 {
                            if let bar = bars[index-1] as? SnackBar {
                                make.bottom.equalTo(bar.snp_top)
                            }
                        } else {
                            make.bottom.equalTo(self.toolbar?.snp_top ?? self.view.snp_bottom)
                        }
                        make.left.width.equalTo(self.footer)
                    }
                    nextbar.setNeedsUpdateConstraints()
                }
            }
        }

        // Really remove the bar
        bar.removeFromSuperview()
    }

    private func finishAddingBar(bar: SnackBar) {
        footer.addSubview(bar)
        bar.snp_makeConstraints({ make in
            // If there are already bars showing, add this on top of them
            let bars = self.footer.subviews
            if bars.count > 1 {
                if let view = bars[bars.count - 2] as? UIView {
                    make.bottom.equalTo(view.snp_top)
                }
            }
            make.left.width.equalTo(self.footer)
        })
    }

    func showBar(bar: SnackBar, animated: Bool) {
        finishAddingBar(bar)
        adjustFooterSize(top: bar)

        bar.hide()
        UIView.animateWithDuration(animated ? 0.25 : 0, animations: { () -> Void in
            bar.show()
        })
    }

    func removeBar(bar: SnackBar, animated: Bool) {
        bar.show()

        let bars = footer.subviews
        let index = findSnackbar(bars, barToFind: bar)!
        UIView.animateWithDuration(animated ? 0.25 : 0, animations: { () -> Void in
            bar.hide()
            // Make sure all the bars above it slide down as well
            for i in index..<bars.count {
                if let sibling = bars[i] as? SnackBar {
                    sibling.transform = CGAffineTransformMakeTranslation(0, bar.frame.height)
                }
            }
        }) { success in
            // Undo all the animation transforms
            for i in index..<bars.count {
                if let bar = bars[i] as? SnackBar {
                    bar.transform = CGAffineTransformIdentity
                }
            }

            // Really remove the bar
            self.finishRemovingBar(bar)

            // Adjust the footer size to only contain the bars
            self.adjustFooterSize()
        }
    }

    func removeAllBars() {
        let bars = footer.subviews
        for bar in bars {
            if let bar = bar as? SnackBar {
                bar.removeFromSuperview()
            }
        }
        self.adjustFooterSize()
    }

    func browser(browser: Browser, didAddSnackbar bar: SnackBar) {
        showBar(bar, animated: true)
    }

    func browser(browser: Browser, didRemoveSnackbar bar: SnackBar) {
        removeBar(bar, animated: true)
    }
}

extension BrowserViewController: HomePanelViewControllerDelegate {
    func homePanelViewController(homePanelViewController: HomePanelViewController, didSelectURL url: NSURL) {
        finishEditingAndSubmit(url)
    }
}

extension BrowserViewController: SearchViewControllerDelegate {
    func searchViewController(searchViewController: SearchViewController, didSelectURL url: NSURL) {
        finishEditingAndSubmit(url)
    }
}

extension BrowserViewController: UIScrollViewDelegate {
    private func clamp(y: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        if y >= max {
            return max
        } else if y <= min {
            return min
        }
        return y
    }

    private func scrollUrlBar(dy: CGFloat) {
        let newY = clamp(header.transform.ty + dy, min: -AppConstants.ToolbarHeight, max: 0)
        header.transform = CGAffineTransformMakeTranslation(0, newY)

        let percent = 1 - newY / -AppConstants.ToolbarHeight
        urlBar.alpha = percent
        self.setNeedsStatusBarAppearanceUpdate()
    }

    private func scrollReaderModeBar(dy: CGFloat) {
        let newY = clamp(readerModeBar.transform.ty + dy, min: -AppConstants.ToolbarHeight, max: 0)
        readerModeBar.transform = CGAffineTransformMakeTranslation(0, newY)

        let percent = 1 - newY / -AppConstants.ToolbarHeight
        readerModeBar.alpha = percent
    }

    private func scrollToolbar(dy: CGFloat) {
        let newY = clamp(footer.transform.ty - dy, min: 0, max: toolbar?.frame.height ?? 0)
        footer.transform = CGAffineTransformMakeTranslation(0, newY)
    }

    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        previousScroll = scrollView.contentOffset
    }

    // Careful! This method can be called multiple times concurrently.
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if var prev = previousScroll {
            if let tab = tabManager.selectedTab {
                if tab.loading {
                    return
                }

                let offset = scrollView.contentOffset
                var delta = CGPoint(x: prev.x - offset.x, y: prev.y - offset.y)
                previousScroll = offset

                if let tab = self.tabManager.selectedTab {
                    let inset = tab.webView.scrollView.contentInset
                    let newInset = clamp(inset.top + delta.y, min: AppConstants.StatusBarHeight, max: AppConstants.ToolbarHeight + AppConstants.StatusBarHeight)

                    tab.webView.scrollView.contentInset = UIEdgeInsetsMake(newInset,
                        0,
                        clamp(newInset - AppConstants.StatusBarHeight, min: 0, max: toolbar?.frame.height ?? 0),
                        0)
                    tab.webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(newInset - AppConstants.StatusBarHeight, 0, clamp(newInset, min: 0, max: toolbar?.frame.height ?? 0), 0)

                    // Adjusting the contentInset will change the scroll position of the page.
                    // We account for that by also adjusting the previousScroll position
                    delta.y += inset.top - newInset
                }

                scrollUrlBar(delta.y)
                scrollReaderModeBar(delta.y)
                scrollToolbar(delta.y)
            }
        }
    }

    func scrollViewWillEndDragging(scrollView: UIScrollView,
            withVelocity velocity: CGPoint,
            targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        previousScroll = nil
        if tabManager.selectedTab?.loading ?? false {
            return
        }

        let offset = scrollView.contentOffset
        // If we're moving up, or the header is half onscreen, hide the toolbars
        if velocity.y < 0 || self.header.transform.ty > -self.header.frame.height / 2 {
            showToolbars(animated: true)
        } else {
            hideToolbars(animated: true)
        }
    }

    func scrollViewDidScrollToTop(scrollView: UIScrollView) {
        showToolbars(animated: true)
    }

    private func hideToolbars(#animated: Bool, completion: ((finished: Bool) -> Void)? = nil) {
        UIView.animateWithDuration(animated ? 0.5 : 0.0, animations: { () -> Void in
            self.scrollUrlBar(CGFloat(-1*MAXFLOAT))
            self.scrollToolbar(CGFloat(-1*MAXFLOAT))

            self.header.transform = CGAffineTransformMakeTranslation(0, -self.urlBar.frame.height + AppConstants.StatusBarHeight)
            self.footer.transform = CGAffineTransformMakeTranslation(0, self.toolbar?.frame.height ?? 0)

            // Reset the insets so that clicking works on the edges of the screen
            if let tab = self.tabManager.selectedTab {
                tab.webView.scrollView.contentInset = UIEdgeInsets(top: AppConstants.StatusBarHeight, left: 0, bottom: 0, right: 0)
                tab.webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: AppConstants.StatusBarHeight, left: 0, bottom: 0, right: 0)
            }
            self.setNeedsStatusBarAppearanceUpdate()
        }, completion: completion)
    }

    private func showToolbars(#animated: Bool, completion: ((finished: Bool) -> Void)? = nil) {
        UIView.animateWithDuration(animated ? 0.5 : 0.0, animations: { () -> Void in
            self.scrollUrlBar(CGFloat(MAXFLOAT))
            self.scrollToolbar(CGFloat(MAXFLOAT))

            self.header.transform = CGAffineTransformIdentity
            self.footer.transform = CGAffineTransformIdentity
            // Reset the insets so that clicking works on the edges of the screen
            if let tab = self.tabManager.selectedTab {
                tab.webView.scrollView.contentInset = UIEdgeInsets(top: self.header.frame.height + (self.readerModeBar.hidden ? 0 : self.readerModeBar.frame.height), left: 0, bottom: self.toolbar?.frame.height ?? 0, right: 0)
                tab.webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: self.header.frame.height + (self.readerModeBar.hidden ? 0 : self.readerModeBar.frame.height), left: 0, bottom: self.toolbar?.frame.height ?? 0, right: 0)
            }
            self.setNeedsStatusBarAppearanceUpdate()
        }, completion: completion)
    }
}

extension BrowserViewController: TabManagerDelegate {
    func tabManager(tabManager: TabManager, didSelectedTabChange selected: Browser?, previous: Browser?) {
        // Remove the old accessibilityLabel. Since this webview shouldn't be visible, it doesn't need it
        // and having multiple views with the same label confuses tests.
        if let wv = previous?.webView {
            wv.accessibilityLabel = nil
        }

        if let wv = selected?.webView {
            wv.accessibilityLabel = NSLocalizedString("Web content", comment: "Accessibility label for the web view")
            webViewContainer.addSubview(wv)
            if let url = wv.URL?.absoluteString {
                profile.bookmarks.isBookmarked(url, success: { bookmarked in
                    self.toolbar?.updateBookmarkStatus(bookmarked)
                    self.urlBar.updateBookmarkStatus(bookmarked)
                }, failure: { err in
                    println("Error getting bookmark status: \(err)")
                })
            }
        }

        removeAllBars()
        urlBar.updateURL(selected?.displayURL)
        if let bars = selected?.bars {
            for bar in bars {
                showBar(bar, animated: true)
            }
        }
        showToolbars(animated: false)

        toolbar?.updateBackStatus(selected?.canGoBack ?? false)
        toolbar?.updateFowardStatus(selected?.canGoForward ?? false)
        toolbar?.updateReloadStatus(selected?.webView.loading ?? false)
        self.urlBar.updateBackStatus(selected?.canGoBack ?? false)
        self.urlBar.updateFowardStatus(selected?.canGoForward ?? false)
        self.urlBar.updateProgressBar(Float(selected?.webView.estimatedProgress ?? 0))

        if let readerMode = selected?.getHelper(name: ReaderMode.name()) as? ReaderMode {
            urlBar.updateReaderModeState(readerMode.state)
            if readerMode.state == .Active {
                showReaderModeBar(animated: false)
            } else {
                hideReaderModeBar(animated: false)
            }
        } else {
            urlBar.updateReaderModeState(ReaderModeState.Unavailable)
        }

        updateInContentHomePanel(selected?.displayURL)
    }

    func tabManager(tabManager: TabManager, didCreateTab tab: Browser) {
        if let readerMode = ReaderMode(browser: tab) {
            readerMode.delegate = self
            tab.addHelper(readerMode, name: ReaderMode.name())
        }

        let favicons = FaviconManager(browser: tab, profile: profile)
        tab.addHelper(favicons, name: FaviconManager.name())

        let pm = PasswordHelper(browser: tab, profile: profile)
        tab.addHelper(pm, name: PasswordHelper.name())
        
        let longPressBrowserHelper = LongPressBrowserHelper(browser: tab)
        longPressBrowserHelper.delegate = self
        tab.addHelper(longPressBrowserHelper, name: LongPressBrowserHelper.name())
    }

    func tabManager(tabManager: TabManager, didAddTab tab: Browser) {
        urlBar.updateTabCount(tabManager.count)

        webViewContainer.insertSubview(tab.webView, atIndex: 0)
        tab.webView.scrollView.contentInset = UIEdgeInsetsMake(AppConstants.ToolbarHeight + AppConstants.StatusBarHeight, 0, toolbar?.frame.height ?? 0, 0)
        tab.webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(AppConstants.ToolbarHeight + AppConstants.StatusBarHeight, 0, toolbar?.frame.height ?? 0, 0)
        tab.webView.snp_makeConstraints { make in
            make.top.equalTo(self.view.snp_top)
            make.leading.trailing.bottom.equalTo(self.view)
        }

        // Observers that live as long as the tab. Make sure these are all cleared
        // in didRemoveTab below!
        tab.webView.addObserver(self, forKeyPath: KVOEstimatedProgress, options: .New, context: nil)
        tab.webView.addObserver(self, forKeyPath: KVOLoading, options: .New, context: nil)
        tab.webView.UIDelegate = self
        tab.browserDelegate = self
        tab.webView.navigationDelegate = self
        tab.webView.scrollView.delegate = self
    }

    func tabManager(tabManager: TabManager, didRemoveTab tab: Browser) {
        urlBar.updateTabCount(tabManager.count)

        tab.webView.removeObserver(self, forKeyPath: KVOEstimatedProgress)
        tab.webView.removeObserver(self, forKeyPath: KVOLoading)
        tab.webView.UIDelegate = nil
        tab.browserDelegate = nil
        tab.webView.navigationDelegate = nil
        tab.webView.scrollView.delegate = nil

        tab.webView.removeFromSuperview()
    }
}

extension BrowserViewController: WKNavigationDelegate {
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if tabManager.selectedTab?.webView !== webView {
            return
        }

        // If we are going to navigate to a new page, hide the reader mode button. Unless we
        // are going to a about:reader page. Then we keep it on screen: it will change status
        // (orange color) as soon as the page has loaded.
        if let url = webView.URL {
            if !ReaderModeUtils.isReaderModeURL(url) {
                urlBar.updateReaderModeState(ReaderModeState.Unavailable)
            }
        }
    }

    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.URL
        if url == nil {
            return
        }

        var openExternally = false
        
        if let scheme = url!.scheme {
            switch scheme {
            case "about", "http", "https":
                openExternally = false
            case "mailto", "tel", "facetime", "sms":
                openExternally = true
            default:
                // Filter out everything we can't open.
                decisionHandler(WKNavigationActionPolicy.Cancel)
                return
            }
        }
        
        if openExternally {
            if UIApplication.sharedApplication().canOpenURL(url!) {
                // Ask the user if it's okay to open the url with UIApplication.
                let alert = UIAlertController(
                    title: String(format: NSLocalizedString("Opening %@", comment:"Opening an external URL"), url!),
                    message: NSLocalizedString("This will open in another application", comment: "Opening an external app"),
                    preferredStyle: UIAlertControllerStyle.Alert
                )

                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment:"Alert Cancel Button"), style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction!) in
                    // NOP
                }))
                
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment:"Alert OK Button"), style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) in
                    UIApplication.sharedApplication().openURL(url!)
                    return
                }))

                presentViewController(alert, animated: true, completion: nil)
            }
            decisionHandler(WKNavigationActionPolicy.Cancel)
        } else {
            decisionHandler(WKNavigationActionPolicy.Allow)
        }
    }
    
    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        if let tab = tabManager.selectedTab {
            if tab.webView == webView {
                urlBar.updateURL(tab.displayURL);
                toolbar?.updateBackStatus(webView.canGoBack)
                toolbar?.updateFowardStatus(webView.canGoForward)
                urlBar.updateBackStatus(webView.canGoBack)
                urlBar.updateFowardStatus(webView.canGoForward)
                showToolbars(animated: false)

                if let url = tab.displayURL?.absoluteString {
                    profile.bookmarks.isBookmarked(url, success: { bookmarked in
                        self.toolbar?.updateBookmarkStatus(bookmarked)
                        self.urlBar.updateBookmarkStatus(bookmarked)
                    }, failure: { err in
                        println("Error getting bookmark status: \(err)")
                    })
                }

                if let url = tab.url {
                    if ReaderModeUtils.isReaderModeURL(url) {
                        showReaderModeBar(animated: false)
                    } else {
                        hideReaderModeBar(animated: false)
                    }
                }

                updateInContentHomePanel(tab.displayURL)
            }
        }
    }

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        let tab: Browser! = tabManager.getTab(webView)

        tab.expireSnackbars()

        let notificationCenter = NSNotificationCenter.defaultCenter()
        var info = [NSObject: AnyObject]()
        info["url"] = tab.displayURL
        info["title"] = tab.title
        notificationCenter.postNotificationName("LocationChange", object: self, userInfo: info)

        if let url = webView.URL {
            // The screenshot immediately after didFinishNavigation is actually a screenshot of the
            // previous page, presumably due to some iOS bug. Adding a small delay seems to fix this,
            // and the current page gets captured as expected.
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(100 * NSEC_PER_MSEC))
            dispatch_after(time, dispatch_get_main_queue()) {
                if webView.URL != url {
                    // The page changed during the delay, so we missed our chance to get a thumbnail.
                    return
                }

                if let screenshot = self.screenshotHelper.takeScreenshot(tab, aspectRatio: CGFloat(ThumbnailCellUX.ImageAspectRatio), quality: 0.5) {
                    let thumbnail = Thumbnail(image: screenshot)
                    self.profile.thumbnails.set(url, thumbnail: thumbnail, complete: nil)
                }
            }
        }

        if tab == tabManager.selectedTab {
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
            // must be followed by LayoutChanged, as ScreenChanged will make VoiceOver
            // cursor land on the correct initial element, but if not followed by LayoutChanged,
            // VoiceOver will sometimes be stuck on the element, not allowing user to move
            // forward/backward. Strange, but LayoutChanged fixes that.
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
        }
    }
}

extension BrowserViewController: WKUIDelegate {
    func webView(webView: WKWebView, createWebViewWithConfiguration configuration: WKWebViewConfiguration, forNavigationAction navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // If the page uses window.open() or target="_blank", open the page in a new tab.
        // TODO: This doesn't work for window.open() without user action (bug 1124942).
        let tab = tabManager.addTab(request: navigationAction.request, configuration: configuration)
        return tab.webView
    }

    func webView(webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: () -> Void) {
        tabManager.selectTab(tabManager.getTab(webView))

        // Show JavaScript alerts.
        let title = frame.request.URL!.host
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: OKString, style: UIAlertActionStyle.Default, handler: { _ in
            completionHandler()
        }))
        presentViewController(alertController, animated: true, completion: nil)
    }

    func webView(webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: (Bool) -> Void) {
        tabManager.selectTab(tabManager.getTab(webView))

        // Show JavaScript confirm dialogs.
        let title = frame.request.URL!.host
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: OKString, style: UIAlertActionStyle.Default, handler: { _ in
            completionHandler(true)
        }))
        alertController.addAction(UIAlertAction(title: CancelString, style: UIAlertActionStyle.Cancel, handler: { _ in
            completionHandler(false)
        }))
        presentViewController(alertController, animated: true, completion: nil)
    }

    func webView(webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: (String!) -> Void) {
        tabManager.selectTab(tabManager.getTab(webView))

        // Show JavaScript input dialogs.
        let title = frame.request.URL!.host
        let alertController = UIAlertController(title: title, message: prompt, preferredStyle: UIAlertControllerStyle.Alert)
        var input: UITextField!
        alertController.addTextFieldWithConfigurationHandler({ (textField: UITextField!) in
            textField.text = defaultText
            input = textField
        })
        alertController.addAction(UIAlertAction(title: OKString, style: UIAlertActionStyle.Default, handler: { _ in
            completionHandler(input.text)
        }))
        alertController.addAction(UIAlertAction(title: CancelString, style: UIAlertActionStyle.Cancel, handler: { _ in
            completionHandler(nil)
        }))
        presentViewController(alertController, animated: true, completion: nil)
    }
}

extension BrowserViewController: ReaderModeDelegate, UIPopoverPresentationControllerDelegate {
    func readerMode(readerMode: ReaderMode, didChangeReaderModeState state: ReaderModeState, forBrowser browser: Browser) {
        // If this reader mode availability state change is for the tab that we currently show, then update
        // the button. Otherwise do nothing and the button will be updated when the tab is made active.
        if tabManager.selectedTab == browser {
            println("DEBUG: New readerModeState: \(state.rawValue)")
            urlBar.updateReaderModeState(state)
        }
    }

    func readerMode(readerMode: ReaderMode, didDisplayReaderizedContentForBrowser browser: Browser) {
        self.showReaderModeBar(animated: true)
        browser.showContent(animated: true)
    }

    // Returning None here makes sure that the Popover is actually presented as a Popover and
    // not as a full-screen modal, which is the default on compact device classes.
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
}

extension BrowserViewController: ReaderModeStyleViewControllerDelegate {
    func readerModeStyleViewController(readerModeStyleViewController: ReaderModeStyleViewController, didConfigureStyle style: ReaderModeStyle) {
        // Persist the new style to the profile
        let encodedStyle: [String:AnyObject] = style.encode()
        profile.prefs.setObject(encodedStyle, forKey: ReaderModeProfileKeyStyle)
        // Change the reader mode style on all tabs that have reader mode active
        for tabIndex in 0..<tabManager.count {
            if let readerMode = tabManager.getTab(tabIndex).getHelper(name: "ReaderMode") as? ReaderMode {
                if readerMode.state == ReaderModeState.Active {
                    readerMode.style = style
                }
            }
        }
    }
}

extension BrowserViewController: LongPressDelegate {
    func longPressBrowserHelper(longPressBrowserHelper: LongPressBrowserHelper, didLongPressElements elements: [LongPressElementType : NSURL]) {
        var actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        var dialogTitleURL: NSURL?
        if let linkURL = elements[LongPressElementType.Link] {
            dialogTitleURL = linkURL
            let newTabTitle = NSLocalizedString("Open In New Tab", comment: "Context menu option")
            var openNewTabAction = UIAlertAction(title: newTabTitle, style: UIAlertActionStyle.Default) { (action: UIAlertAction!) in
                let request =  NSURLRequest(URL: linkURL)
                let tab = self.tabManager.addTab(request: request)
            }
            actionSheetController.addAction(openNewTabAction)

            let copyTitle = NSLocalizedString("Copy", comment: "Context menu option")
            var copyAction = UIAlertAction(title: copyTitle, style: UIAlertActionStyle.Default) { (action: UIAlertAction!) -> Void in
                var pasteBoard = UIPasteboard.generalPasteboard()
                pasteBoard.string = linkURL.absoluteString
            }
            actionSheetController.addAction(copyAction)
        }
        if let imageURL = elements[LongPressElementType.Image] {
            if dialogTitleURL == nil {
                dialogTitleURL = imageURL
            }

            let saveImageTitle = NSLocalizedString("Save Image", comment: "Context menu option")
            var saveImageAction = UIAlertAction(title: saveImageTitle, style: UIAlertActionStyle.Default) { (action: UIAlertAction!) -> Void in
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    var imageData = NSData(contentsOfURL: imageURL)
                    if imageData != nil {
                        UIImageWriteToSavedPhotosAlbum(UIImage(data: imageData!), nil, nil, nil)
                    }
                })
            }
            actionSheetController.addAction(saveImageAction)

            let copyImageTitle = NSLocalizedString("Copy Image URL", comment: "Context menu option")
            var copyAction = UIAlertAction(title: copyImageTitle, style: UIAlertActionStyle.Default) { (action: UIAlertAction!) -> Void in
                var pasteBoard = UIPasteboard.generalPasteboard()
                pasteBoard.string = imageURL.absoluteString
            }
            actionSheetController.addAction(copyAction)
        }

        actionSheetController.title = dialogTitleURL!.absoluteString
        var cancelAction = UIAlertAction(title: CancelString, style: UIAlertActionStyle.Cancel, handler: nil)
        actionSheetController.addAction(cancelAction)

        if let popoverPresentationController = actionSheetController.popoverPresentationController {
            popoverPresentationController.sourceView = self.view
            popoverPresentationController.sourceRect = CGRectInset(CGRect(origin: longPressBrowserHelper.longPressGestureRecognizer.locationInView(self.view), size: CGSizeZero), -8, -8)
            popoverPresentationController.permittedArrowDirections = .Any
        }
        
        self.presentViewController(actionSheetController, animated: true, completion: nil)
    }
}

extension BrowserViewController : UIViewControllerTransitioningDelegate {
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return TransitionManager(show: false)
    }

    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return TransitionManager(show: true)
    }
}

extension BrowserViewController : Transitionable {
    func transitionableWillShow(transitionable: Transitionable, options: TransitionOptions) {
        view.transform = CGAffineTransformIdentity
        view.alpha = 1
        // Move all the webview's off screen
        for i in 0..<tabManager.count {
            let tab = tabManager.getTab(i)
            tab.webView.frame = CGRect(x: tab.webView.frame.width, y: 0, width: tab.webView.frame.width, height: tab.webView.frame.height)
        }
    }

    func transitionableWillHide(transitionable: Transitionable, options: TransitionOptions) {
        if let cell = options.moving {
            view.transform = CGAffineTransformMakeTranslation(0, cell.frame.origin.y - (toolbar?.frame.height ?? 0))
        }
        view.alpha = 0
        // Move all the webview's off screen
        for i in 0..<tabManager.count {
            let tab = tabManager.getTab(i)
            tab.webView.frame = CGRect(x: tab.webView.frame.width, y: 0, width: tab.webView.frame.width, height: tab.webView.frame.height)
        }
    }

    func transitionableWillComplete(transitionable: Transitionable, options: TransitionOptions) {
        // Move all the webview's back on screen
        for i in 0..<tabManager.count {
            let tab = tabManager.getTab(i)
            tab.webView.frame = CGRect(x: 0, y: 0, width: tab.webView.frame.width, height: tab.webView.frame.height)
        }
    }
}

extension BrowserViewController {
    private func updateScrollbarInsets() {
        if let tab = self.tabManager.selectedTab {
            tab.webView.scrollView.contentInset = UIEdgeInsets(top: self.header.frame.height + (self.readerModeBar.hidden ? 0 : self.readerModeBar.frame.height), left: 0, bottom: toolbar?.frame.height ?? 0, right: 0)
            tab.webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: self.header.frame.height + (self.readerModeBar.hidden ? 0 : self.readerModeBar.frame.height), left: 0, bottom: toolbar?.frame.height ?? 0, right: 0)
        }
    }

    func showReaderModeBar(#animated: Bool) {
        // TODO This needs to come from the database
        readerModeBar.unread = true
        readerModeBar.added = false
        readerModeBar.hidden = false
        updateScrollbarInsets()
    }

    func hideReaderModeBar(#animated: Bool) {
        readerModeBar.hidden = true
        updateScrollbarInsets()
    }

    /// There are two ways we can enable reader mode. In the simplest case we open a URL to our internal reader mode
    /// and be done with it. In the more complicated case, reader mode was already open for this page and we simply
    /// navigated away from it. So we look to the left and right in the BackForwardList to see if a readerized version
    /// of the current page is there. And if so, we go there.

    func enableReaderMode() {
        if let webView = tabManager.selectedTab?.webView {
            let backList = webView.backForwardList.backList as! [WKBackForwardListItem]
            let forwardList = webView.backForwardList.forwardList as! [WKBackForwardListItem]

            if let currentURL = webView.backForwardList.currentItem?.URL {
                if let readerModeURL = ReaderModeUtils.encodeURL(currentURL) {
                    if backList.count > 1 && backList.last?.URL == readerModeURL {
                        webView.goToBackForwardListItem(backList.last!)
                    } else if forwardList.count > 0 && forwardList.first?.URL == readerModeURL {
                        webView.goToBackForwardListItem(forwardList.first!)
                    } else {
                        // Store the readability result in the cache and load it. This will later move to the ReadabilityHelper.
                        webView.evaluateJavaScript("\(ReaderModeNamespace).readerize()", completionHandler: { (object, error) -> Void in
                            if let readabilityResult = ReadabilityResult(object: object) {
                                ReaderModeCache.sharedInstance.put(currentURL, readabilityResult, error: nil)
                                webView.loadRequest(NSURLRequest(URL: readerModeURL))
                            }
                        })
                    }
                }
            }
        }
    }

    /// Disabling reader mode can mean two things. In the simplest case we were opened from the reading list, which
    /// means that there is nothing in the BackForwardList except the internal url for the reader mode page. In that
    /// case we simply open a new page with the original url. In the more complicated page, the non-readerized version
    /// of the page is either to the left or right in the BackForwardList. If that is the case, we navigate there.

    func disableReaderMode() {
        if let webView = tabManager.selectedTab?.webView {
            let backList = webView.backForwardList.backList as! [WKBackForwardListItem]
            let forwardList = webView.backForwardList.forwardList as! [WKBackForwardListItem]

            if let currentURL = webView.backForwardList.currentItem?.URL {
                if let originalURL = ReaderModeUtils.decodeURL(currentURL) {
                    if backList.count > 1 && backList.last?.URL == originalURL {
                        webView.goToBackForwardListItem(backList.last!)
                    } else if forwardList.count > 0 && forwardList.first?.URL == originalURL {
                        webView.goToBackForwardListItem(forwardList.first!)
                    } else {
                        webView.loadRequest(NSURLRequest(URL: originalURL))
                    }
                }
            }
        }
    }
}

extension BrowserViewController: ReaderModeBarViewDelegate {
    func readerModeBar(readerModeBar: ReaderModeBarView, didSelectButton buttonType: ReaderModeBarButtonType) {
        switch buttonType {
        case .Settings:
            if let readerMode = tabManager.selectedTab?.getHelper(name: "ReaderMode") as? ReaderMode {
                if readerMode.state == ReaderModeState.Active {
                    var readerModeStyle = DefaultReaderModeStyle
                    if let dict = profile.prefs.dictionaryForKey(ReaderModeProfileKeyStyle) {
                        if let style = ReaderModeStyle(dict: dict) {
                            readerModeStyle = style
                        }
                    }

                    let readerModeStyleViewController = ReaderModeStyleViewController()
                    readerModeStyleViewController.delegate = self
                    readerModeStyleViewController.readerModeStyle = readerModeStyle
                    readerModeStyleViewController.modalPresentationStyle = UIModalPresentationStyle.Popover

                    let popoverPresentationController = readerModeStyleViewController.popoverPresentationController
                    popoverPresentationController?.backgroundColor = UIColor.whiteColor()
                    popoverPresentationController?.delegate = self
                    popoverPresentationController?.sourceView = readerModeBar
                    popoverPresentationController?.sourceRect = CGRect(x: readerModeBar.frame.width/2, y: AppConstants.ToolbarHeight, width: 1, height: 1)
                    popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Up

                    self.presentViewController(readerModeStyleViewController, animated: true, completion: nil)
                }
            }

        case .MarkAsRead:
            // TODO Persist to database
            readerModeBar.unread = false
        case .MarkAsUnread:
            // TODO Persist to database
            readerModeBar.unread = true

        case .AddToReadingList:
            // TODO Persist to database - The code below needs an update to talk to improved storage layer
            if let tab = tabManager.selectedTab,
               let url = tab.url where ReaderModeUtils.isReaderModeURL(url) {
                if let url = ReaderModeUtils.decodeURL(url) {
                    if let absoluteString = url.absoluteString {
                        profile.readingList.add(item: ReadingListItem(url: absoluteString, title: tab.title)) { (success) -> Void in
                            //readerModeBar.added = true
                        }
                    }
                }
            }
            break
        case .RemoveFromReadingList:
            // TODO Persist to database
            break
        }
    }
}

private class BrowserScreenshotHelper: ScreenshotHelper {
    private weak var controller: BrowserViewController?

    init(controller: BrowserViewController) {
        self.controller = controller
    }

    func takeScreenshot(tab: Browser, aspectRatio: CGFloat, quality: CGFloat) -> UIImage? {
        if let url = tab.url {
            if url.absoluteString == HomeURL {
                if let homePanel = controller?.homePanelController {
                    return homePanel.view.screenshot(aspectRatio, quality: quality)
                }
            } else {
                let offset = CGPointMake(0, -tab.webView.scrollView.contentInset.top)
                return tab.webView.screenshot(aspectRatio, offset: offset, quality: quality)
            }
        }

        return nil
    }
}
