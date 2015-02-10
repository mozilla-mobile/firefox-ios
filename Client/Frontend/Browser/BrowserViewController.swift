/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import WebKit

public let StatusBarHeight: CGFloat = 20 // TODO: Can't assume this is correct. Status bar height is dynamic.
public let ToolbarHeight: CGFloat = 44
public let DefaultPadding: CGFloat = 10
private let OKString = NSLocalizedString("OK", comment: "OK button")
private let CancelString = NSLocalizedString("Cancel", comment: "Cancel button")

private let KVOLoading = "loading"
private let KVOEstimatedProgress = "estimatedProgress"

class BrowserViewController: UIViewController {
    private var urlbar: URLBarView!
    private var toolbar: BrowserToolbar!
    private var tabManager: TabManager!
    var profile: Profile!

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        didInit()
    }

    override init() {
        super.init(nibName: nil, bundle: nil)
        didInit()
    }

    private func didInit() {
        let defaultURL = NSURL(string: "http://www.mozilla.org")!
        let defaultRequest = NSURLRequest(URL: defaultURL)
        tabManager = TabManager(defaultNewTabRequest: defaultRequest)
    }

    private func wrapInEffect(view: UIView) -> UIView {
        let effect = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))
        self.view.addSubview(effect);
        view.backgroundColor = UIColor.clearColor()
        effect.addSubview(view)

        view.snp_makeConstraints { make in
            make.edges.equalTo(effect)
            return
        }

        return effect
    }

    override func viewDidLoad() {
        urlbar = URLBarView()
        let URLBarEffect = wrapInEffect(urlbar)
        URLBarEffect.snp_makeConstraints { make in
            make.top.equalTo(self.view.snp_top)
            make.height.equalTo(ToolbarHeight + StatusBarHeight)
            make.leading.trailing.equalTo(self.view)
        }
        urlbar.delegate = self
        tabManager.delegate = self

        toolbar = BrowserToolbar()
        let toolbarEffect = wrapInEffect(toolbar)
        toolbarEffect.snp_makeConstraints { make in
            make.bottom.equalTo(self.view.snp_bottom)
            make.height.equalTo(ToolbarHeight)
            make.leading.trailing.equalTo(self.view)
        }
        toolbar.browserToolbarDelegate = self

        tabManager.addTab()
    }

    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        if object as? WKWebView !== tabManager.selectedTab?.webView {
            return
        }

        switch keyPath {
        case KVOEstimatedProgress:
            urlbar.updateProgressBar(change[NSKeyValueChangeNewKey] as Float)
        case KVOLoading:
            urlbar.updateLoading(change[NSKeyValueChangeNewKey] as Bool)
        default:
            assertionFailure("Unhandled KVO key: \(keyPath)")
        }
    }
}

extension BrowserViewController: UrlBarDelegate {
    func didBeginEditing() {
        let controller = TabBarViewController()
        controller.profile = profile
        controller.delegate = self
        controller.url = tabManager.selectedTab?.url
        controller.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        presentViewController(controller, animated: true, completion: nil)
    }

    override func accessibilityPerformEscape() -> Bool {
        if let selectedTab = tabManager.selectedTab? {
            if selectedTab.canGoBack {
                didClickBack()
                return true
            }
        }
        return false
    }

    func didClickReload() {
        tabManager.selectedTab?.reload()
    }

    func didClickStop() {
        tabManager.selectedTab?.stop()
    }

    func didClickAddTab() {
        let controller = TabTrayController()
        controller.tabManager = tabManager
        presentViewController(controller, animated: true, completion: nil)
    }

    func didClickReaderMode() {
        if let tab = tabManager.selectedTab {
            if let readerMode = tab.getHelper(name: "ReaderMode") as? ReaderMode {
                if readerMode.state == .Available {
                    // TODO: When we persist the style, it can be passed here. This will be part of the UI bug that we already have.
                    //readerMode.style = getStyleFromProfile()
                    readerMode.enableReaderMode()
                } else {
                    readerMode.disableReaderMode()
                }
            }
        }
    }
}

extension BrowserViewController: BrowserToolbarDelegate {
    func didClickBack() {
        tabManager.selectedTab?.goBack()
    }
    func didLongPressBack() {
        let controller = BackForwardListViewController()
        controller.listData = tabManager.selectedTab?.backList
        controller.tabManager = tabManager
        presentViewController(controller, animated: true, completion: nil)
    }

    func didClickForward() {
        tabManager.selectedTab?.goForward()
    }

    func didLongPressForward() {
        let controller = BackForwardListViewController()
        controller.listData = tabManager.selectedTab?.forwardList
        controller.tabManager = tabManager
        presentViewController(controller, animated: true, completion: nil)
    }
}

extension BrowserViewController: TabBarViewControllerDelegate {
    func didEnterURL(url: NSURL) {
        urlbar.updateURL(url)
        tabManager.selectedTab?.loadRequest(NSURLRequest(URL: url))
    }
}

extension BrowserViewController: TabManagerDelegate {
    func didSelectedTabChange(selected: Browser?, previous: Browser?) {
        previous?.webView.hidden = true
        selected?.webView.hidden = false

        previous?.webView.navigationDelegate = nil
        selected?.webView.navigationDelegate = self
        urlbar.updateURL(selected?.url)
        if let selected = selected {
            toolbar.updateBackStatus(selected.canGoBack)
            toolbar.updateFowardStatus(selected.canGoForward)
            urlbar.updateProgressBar(Float(selected.webView.estimatedProgress))
            urlbar.updateLoading(selected.webView.loading)
        }

        if let readerMode = selected?.getHelper(name: ReaderMode.name()) as? ReaderMode {
            urlbar.updateReaderModeState(readerMode.state)
        }
    }

    func didCreateTab(tab: Browser) {
        if let longPressGestureRecognizer = LongPressGestureRecognizer(webView: tab.webView) {
            tab.webView.addGestureRecognizer(longPressGestureRecognizer)
            longPressGestureRecognizer.longPressGestureDelegate = self
        }

        if let readerMode = ReaderMode(browser: tab) {
            readerMode.delegate = self
            tab.addHelper(readerMode, name: ReaderMode.name())

            // TODO: This is a *temporary* way to trigger the reader mode style dialog via 3 taps in the webview. When
            // we know where the Aa button needs to go, all code below can be refactored properly.
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: "SELshowReaderModeStyle:")
            gestureRecognizer.numberOfTapsRequired = 3
            tab.webView.addGestureRecognizer(gestureRecognizer)
        }

        let favicons = FaviconManager(browser: tab, profile: profile)
        favicons.profile = profile
        tab.addHelper(favicons, name: FaviconManager.name())
    }

    func didAddTab(tab: Browser) {
        urlbar.updateTabCount(tabManager.count)

        tab.webView.hidden = true
        view.insertSubview(tab.webView, atIndex: 0)
        tab.webView.scrollView.contentInset = UIEdgeInsetsMake(ToolbarHeight + StatusBarHeight, 0, ToolbarHeight, 0)
        tab.webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(ToolbarHeight + StatusBarHeight, 0, ToolbarHeight, 0)
        tab.webView.snp_makeConstraints { make in
            make.top.equalTo(self.view.snp_top)
            make.leading.trailing.bottom.equalTo(self.view)
        }
        tab.webView.addObserver(self, forKeyPath: KVOEstimatedProgress, options: .New, context: nil)
        tab.webView.addObserver(self, forKeyPath: KVOLoading, options: .New, context: nil)
        tab.webView.UIDelegate = self
    }

    func didRemoveTab(tab: Browser) {
        urlbar.updateTabCount(tabManager.count)

        tab.webView.removeObserver(self, forKeyPath: KVOEstimatedProgress)
        tab.webView.removeObserver(self, forKeyPath: KVOLoading)
        tab.webView.removeFromSuperview()
    }
}


extension BrowserViewController: WKNavigationDelegate {
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // If we are going to navigate to a new page, hide the reader mode button. Unless we
        // are going to a about:reader page. Then we keep it on screen: it will change status
        // (orange color) as soon as the page has loaded.
        if let absoluteString = webView.URL?.absoluteString {
            // TODO String comparison here because NSURL cannot parse about:reader URLs (1123509)
            if absoluteString.hasPrefix("about:reader") == false {
                urlbar.updateReaderModeState(ReaderModeState.Unavailable)
            }
        }
    }

    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        urlbar.updateURL(webView.URL);
        toolbar.updateBackStatus(webView.canGoBack)
        toolbar.updateFowardStatus(webView.canGoForward)
    }

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        var info = [NSObject: AnyObject]()
        info["url"] = webView.URL
        info["title"] = webView.title
        notificationCenter.postNotificationName("LocationChange", object: self, userInfo: info)

        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
        // must be followed by LayoutChanged, as ScreenChanged will make VoiceOver
        // cursor land on the correct initial element, but if not followed by LayoutChanged,
        // VoiceOver will sometimes be stuck on the element, not allowing user to move
        // forward/backward. Strange, but LayoutChanged fixes that.
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
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
        // Show JavaScript alerts.
        let title = frame.request.URL.host
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: OKString, style: UIAlertActionStyle.Default, handler: { _ in
            completionHandler()
        }))
        presentViewController(alertController, animated: true, completion: nil)
    }

    func webView(webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: (Bool) -> Void) {
        // Show JavaScript confirm dialogs.
        let title = frame.request.URL.host
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
        // Show JavaScript input dialogs.
        let title = frame.request.URL.host
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
            urlbar.updateReaderModeState(state)
        }
    }

    func SELshowReaderModeStyle(recognizer: UITapGestureRecognizer) {
        if let readerMode = tabManager.selectedTab?.getHelper(name: "ReaderMode") as? ReaderMode {
            if readerMode.state == ReaderModeState.Active {
                let readerModeStyleViewController = ReaderModeStyleViewController()
                readerModeStyleViewController.delegate = readerMode
                readerModeStyleViewController.readerModeStyle = readerMode.style
                readerModeStyleViewController.modalPresentationStyle = UIModalPresentationStyle.Popover

                let popoverPresentationController = readerModeStyleViewController.popoverPresentationController
                popoverPresentationController?.backgroundColor = UIColor.whiteColor()
                popoverPresentationController?.delegate = self
                popoverPresentationController?.sourceView = self.view
                popoverPresentationController?.sourceRect = CGRect(x: self.view.frame.width/2, y: self.view.frame.height-4, width: 4, height: 4)

                self.presentViewController(readerModeStyleViewController, animated: true, completion: nil)
            }
        }
    }

    // Returning None here makes sure that the Popover is actually presented as a Popover and
    // not as a full-screen modal, which is the default on compact device classes.
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
}

extension BrowserViewController: LongPressGestureDelegate {
    func longPressRecognizer(longPressRecognizer: LongPressGestureRecognizer, didLongPressElements elements: [LongPressElementType: NSURL]) {
        var actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        var dialogTitleURL: NSURL?
        if let linkURL = elements[LongPressElementType.Link] {
            dialogTitleURL = linkURL
            var openNewTabAction =  UIAlertAction(title: "Open In New Tab", style: UIAlertActionStyle.Default) { (action: UIAlertAction!) in
                let request =  NSURLRequest(URL: linkURL)
                let tab = self.tabManager.addTab(request: request)
            }
            actionSheetController.addAction(openNewTabAction)

            var copyAction = UIAlertAction(title: "Copy", style: UIAlertActionStyle.Default) { (action: UIAlertAction!) -> Void in
                var pasteBoard = UIPasteboard.generalPasteboard()
                pasteBoard.string = linkURL.absoluteString
            }
            actionSheetController.addAction(copyAction)
        }
        if let imageURL = elements[LongPressElementType.Image] {
            if dialogTitleURL == nil {
                dialogTitleURL = imageURL
            }
            var saveImageAction = UIAlertAction(title: "Save Image", style: UIAlertActionStyle.Default) { (action: UIAlertAction!) -> Void in
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    var imageData = NSData(contentsOfURL: imageURL)
                    if imageData != nil {
                        UIImageWriteToSavedPhotosAlbum(UIImage(data: imageData!), nil, nil, nil)
                    }
                })
            }
            actionSheetController.addAction(saveImageAction)

            var copyAction = UIAlertAction(title: "Copy Image URL", style: UIAlertActionStyle.Default) { (action: UIAlertAction!) -> Void in
                var pasteBoard = UIPasteboard.generalPasteboard()
                pasteBoard.string = imageURL.absoluteString
            }
            actionSheetController.addAction(copyAction)
        }
        actionSheetController.title = dialogTitleURL!.absoluteString
        var cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, nil)
        actionSheetController.addAction(cancelAction)
        self.presentViewController(actionSheetController, animated: true, completion: nil)
    }
}
