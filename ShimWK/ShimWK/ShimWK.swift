/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

// TODO: Eventually add methods to swap the factory, which will allow us to use UIWebView.
let factory: ShimWKFactory = WKShimWKFactory()

protocol ShimWKFactory {
    func wrapWKProcessPool() -> ShimWKProcessPoolImpl
    func wrapWKWebView(wrapper: ShimWKWebView, frame: CGRect, configuration: ShimWKWebViewConfiguration) -> ShimWKWebViewImpl
    func wrapWKWebViewConfiguration(wrapper: ShimWKWebViewConfiguration) -> ShimWKWebViewConfigurationImpl
    func wrapWKUserContentController(wrapper: ShimWKUserContentController) -> ShimWKUserContentControllerImpl
    func wrapWKUserScript(source: String, injectionTime: ShimWKUserScriptInjectionTime, forMainFrameOnly: Bool) -> ShimWKUserScriptImpl
    func wrapWKWebsiteDataStore(persistent persistent: Bool) -> ShimWKWebsiteDataStoreImpl
    func wrapWKPreferences() -> ShimWKPreferencesImpl
}

protocol ShimWKWebViewImpl {
    var navigationDelegate: ShimWKNavigationDelegate? { get set }
    var UIDelegate: ShimWKUIDelegate? { get set }
    var configuration: ShimWKWebViewConfiguration { get }
    var backForwardList: ShimWKBackForwardList { get }
    var allowsLinkPreview: Bool { get set }
    var view: UIView { get }
    var scrollView: UIScrollView { get }
    var allowsBackForwardNavigationGestures: Bool { get set }
    var customUserAgent: String? { get set }
    func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> ())?)
    func loadRequest(request: NSURLRequest) -> ShimWKNavigation?
    func reload() -> ShimWKNavigation?
    func reloadFromOrigin() -> ShimWKNavigation?
    func stopLoading()
    func goToBackForwardListItem(item: ShimWKBackForwardListItem) -> ShimWKNavigation?
    func goBack() -> ShimWKNavigation?
    func goForward() -> ShimWKNavigation?
}

/*!
 A WKWebView object displays interactive Web content.
 @helperclass @link WKWebViewConfiguration @/link
 Used to configure @link WKWebView @/link instances.
 */
public class ShimWKWebView: NSObject, ShimWKWebViewImpl {
    var _impl: ShimWKWebViewImpl!

    /*! @abstract Returns a web view initialized with a specified frame and
     configuration.
     @param frame The frame for the new web view.
     @param configuration The configuration for the new web view.
     @result An initialized web view, or nil if the object could not be
     initialized.
     @discussion This is a designated initializer. You can use
     @link -initWithFrame: @/link to initialize an instance with the default
     configuration. The initializer copies the specified configuration, so
     mutating the configuration after invoking the initializer has no effect
     on the web view.
     */
    public init(frame: CGRect, configuration: ShimWKWebViewConfiguration) {
        super.init()
        _impl = factory.wrapWKWebView(self, frame: frame, configuration: configuration)
    }

    override public convenience init() {
        self.init(frame: CGRectZero, configuration: ShimWKWebViewConfiguration())
    }

    /// Returns a web view initialized with the specified configuration using
    /// the given closure to create the web view instance.
    public init(configuration: ShimWKWebViewConfiguration, makeInnerWKWebView: (WKWebViewConfiguration -> WKWebView)? = nil, makeInnerUIWebView: (() -> UIWebView)? = nil) {
        super.init()

        if let factory = factory as? WKShimWKFactory {
            _impl = factory.wrapWKWebView(self, configuration: configuration, makeInnerWKWebView: makeInnerWKWebView)
        } else {
            // TODO: Support UIShimWKFactory.
            _impl = factory.wrapWKWebView(self, frame: CGRectZero, configuration: configuration)
        }
    }

    /*! @abstract The web view's navigation delegate. */
    public var navigationDelegate: ShimWKNavigationDelegate? {
        get {
            return _impl.navigationDelegate
        }
        set {
            _impl.navigationDelegate = newValue
        }
    }

    /*! @abstract The web view's user interface delegate. */
    public var UIDelegate: ShimWKUIDelegate? {
        get {
            return _impl.UIDelegate
        }
        set {
            _impl.UIDelegate = newValue
        }
    }

    /*! @abstract A copy of the configuration with which the web view was
     initialized. */
    public var configuration: ShimWKWebViewConfiguration {
        return _impl.configuration
    }

    /*! @abstract The active URL.
     @discussion This is the URL that should be reflected in the user
     interface.
     @link WKWebView @/link is key-value observing (KVO) compliant for this
     property.
     */
    internal(set) public dynamic var URL: NSURL? = nil

    /*! @abstract The page title.
     @discussion @link WKWebView @/link is key-value observing (KVO) compliant
     for this property.
     */
    internal(set) public dynamic var title: String? = nil

    /*! @abstract A Boolean value indicating whether the view is currently
     loading content.
     @discussion @link WKWebView @/link is key-value observing (KVO) compliant
     for this property.
     */
    internal(set) public dynamic var loading: Bool = false

    /*! @abstract A Boolean value indicating whether there is a back item in
     the back-forward list that can be navigated to.
     @discussion @link WKWebView @/link is key-value observing (KVO) compliant
     for this property.
     @seealso backForwardList.
     */
    internal(set) public dynamic var canGoBack: Bool = false

    /*! @abstract A Boolean value indicating whether there is a forward item in
     the back-forward list that can be navigated to.
     @discussion @link WKWebView @/link is key-value observing (KVO) compliant
     for this property.
     @seealso backForwardList.
     */
    internal(set) public dynamic var canGoForward: Bool = false

    /*! @abstract An estimate of what fraction of the current navigation has been completed.
     @discussion This value ranges from 0.0 to 1.0 based on the total number of
     bytes expected to be received, including the main document and all of its
     potential subresources. After a navigation completes, the value remains at 1.0
     until a new navigation starts, at which point it is reset to 0.0.
     @link WKWebView @/link is key-value observing (KVO) compliant for this
     property.
     */
    internal(set) public dynamic var estimatedProgress: Double = 0

    /*! @abstract The web view's back-forward list. */
    public var backForwardList: ShimWKBackForwardList {
        return _impl.backForwardList
    }

    /*! @abstract A Boolean value indicating whether link preview is allowed for any
     links inside this WKWebView.
     @discussion The default value is YES on Mac and iOS.
     */
    public var allowsLinkPreview: Bool {
        get {
            return _impl.allowsLinkPreview
        }
        set {
            _impl.allowsLinkPreview = newValue
        }
    }

    public var view: UIView {
        return _impl.view
    }

    /*! @abstract The scroll view associated with the web view.
     */
    public var scrollView: UIScrollView {
        return _impl.scrollView
    }

    /*! @abstract A Boolean value indicating whether horizontal swipe gestures
     will trigger back-forward list navigations.
     @discussion The default value is NO.
     */
    public var allowsBackForwardNavigationGestures: Bool {
        get {
            return _impl.allowsBackForwardNavigationGestures
        }
        set {
            _impl.allowsBackForwardNavigationGestures = newValue
        }
    }

    /*! @abstract The custom user agent string or nil if no custom user agent string has been set.
     */
    public var customUserAgent: String? {
        get {
            return _impl.customUserAgent
        }
        set {
            _impl.customUserAgent = newValue
        }
    }

    /* @abstract Evaluates the given JavaScript string.
     @param javaScriptString The JavaScript string to evaluate.
     @param completionHandler A block to invoke when script evaluation completes or fails.
     @discussion The completionHandler is passed the result of the script evaluation or an error.
     */
    public func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> ())? = nil) {
        _impl.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }

    /*! @abstract Navigates to a requested URL.
     @param request The request specifying the URL to which to navigate.
     @result A new navigation for the given request.
     */
    public func loadRequest(request: NSURLRequest) -> ShimWKNavigation? {
        return _impl.loadRequest(request)
    }

    /*! @abstract Reloads the current page.
     @result A new navigation representing the reload.
     */
    public func reload() -> ShimWKNavigation? {
        return _impl.reload()
    }

    /*! @abstract Reloads the current page, performing end-to-end revalidation
     using cache-validating conditionals if possible.
     @result A new navigation representing the reload.
     */
    public func reloadFromOrigin() -> ShimWKNavigation?  {
        return _impl.reloadFromOrigin()
    }

    /*! @abstract Stops loading all resources on the current page.
     */
    public func stopLoading() {
        _impl.stopLoading()
    }

    public func goToBackForwardListItem(item: ShimWKBackForwardListItem) -> ShimWKNavigation?  {
        return _impl.goToBackForwardListItem(item)
    }

    /*! @abstract Navigates to the back item in the back-forward list.
     @result A new navigation to the requested item, or nil if there is no back
     item in the back-forward list.
     */
    public func goBack() -> ShimWKNavigation?  {
        return _impl.goBack()
    }

    /*! @abstract Navigates to the forward item in the back-forward list.
     @result A new navigation to the requested item, or nil if there is no
     forward item in the back-forward list.
     */
    public func goForward() -> ShimWKNavigation?  {
        return _impl.goForward()
    }
}

/*! A WKNavigation object can be used for tracking the loading progress of a webpage.
 @discussion A navigation is returned from the web view load methods, and is
 also passed to the navigation delegate methods, to uniquely identify a webpage
 load from start to finish.
 */
public class ShimWKNavigation: NSObject {}

/*!
 A WKNavigationAction object contains information about an action that may cause a navigation, used for making policy decisions.
 */
@objc public protocol ShimWKNavigationAction {
    /*! @abstract The frame requesting the navigation.
     */
    var sourceFrame: ShimWKFrameInfo { get }

    /*! @abstract The target frame, or nil if this is a new window navigation.
     */
    var targetFrame: ShimWKFrameInfo? { get }

    /*! @abstract The type of action that triggered the navigation.
     @discussion The value is one of the constants of the enumerated type WKNavigationType.
     */
    var navigationType: ShimWKNavigationType { get }

    /*! @abstract The navigation's request.
     */
    var request: NSURLRequest { get }
}

@objc public protocol ShimWKWindowFeatures {}

protocol ShimWKWebViewConfigurationImpl {
    var processPool: ShimWKProcessPool { get set }
    var preferences: ShimWKPreferences { get set }
    var userContentController: ShimWKUserContentController { get set }
    var websiteDataStore: ShimWKWebsiteDataStore { get set }
    var applicationNameForUserAgent: String? { get set }
}

/*! A WKWebViewConfiguration object is a collection of properties with
 which to initialize a web view.
 @helps Contains properties used to configure a @link WKWebView @/link.
 */
public class ShimWKWebViewConfiguration: NSObject, ShimWKWebViewConfigurationImpl {
    var _impl: ShimWKWebViewConfigurationImpl!

    public override init() {
        super.init()
        _impl = factory.wrapWKWebViewConfiguration(self)
    }

    init(impl: ShimWKWebViewConfigurationImpl) {
        _impl = impl
    }

    /*! @abstract The process pool from which to obtain the view's web content
     process.
     @discussion When a web view is initialized, a new web content process
     will be created for it from the specified pool, or an existing process in
     that pool will be used.
     */
    public var processPool: ShimWKProcessPool {
        get {
            return _impl.processPool
        }
        set {
            _impl.processPool = newValue
        }
    }

    /*! @abstract The preference settings to be used by the web view.
     */
    public var preferences: ShimWKPreferences {
        get {
            return _impl.preferences
        }
        set {
            _impl.preferences = newValue
        }
    }

    /*! @abstract The user content controller to associate with the web view.
     */
    public var userContentController: ShimWKUserContentController {
        get {
            return _impl.userContentController
        }
        set {
            _impl.userContentController = newValue
        }
    }

    /*! @abstract The website data store to be used by the web view.
     */
    public var websiteDataStore: ShimWKWebsiteDataStore {
        get {
            return _impl.websiteDataStore
        }
        set {
            _impl.websiteDataStore = newValue
        }
    }

    /*! @abstract The name of the application as used in the user agent string.
     */
    public var applicationNameForUserAgent: String? {
        get {
            return _impl.applicationNameForUserAgent
        }
        set {
            _impl.applicationNameForUserAgent = newValue
        }
    }
}

/*! A WKFrameInfo object contains information about a frame on a webpage.
 @discussion An instance of this class is a transient, data-only object;
 it does not uniquely identify a frame across multiple delegate method
 calls.
 */
@objc public protocol ShimWKFrameInfo {
    /*! @abstract A Boolean value indicating whether the frame is the main frame
     or a subframe.
     */
    var mainFrame: Bool { get }

    /*! @abstract The frame's current request.
     */
    var request: NSURLRequest { get }

    /*! @abstract The frame's current security origin.
     */
    var securityOrigin: ShimWKSecurityOrigin { get }
}

/*! A WKSecurityOrigin object contains information about a security origin.
 @discussion An instance of this class is a transient, data-only object;
 it does not uniquely identify a security origin across multiple delegate method
 calls.
 */
@objc public protocol ShimWKSecurityOrigin {
    /*! @abstract The security origin's protocol.
     */
    var `protocol`: String { get }

    /*! @abstract The security origin's host.
     */
    var host: String { get }

    /*! @abstract The security origin's port.
     */
    var port: Int { get }
}

/*! A WKScriptMessage object contains information about a message sent from
 a webpage.
 */
public protocol ShimWKScriptMessage {
    /*! @abstract The body of the message.
     @discussion Allowed types are NSNumber, NSString, NSDate, NSArray,
     NSDictionary, and NSNull.
     */
    var body: AnyObject { get }

    /*! @abstract The web view sending the message. */
    var webView: ShimWKWebView? { get }

    /*! @abstract The frame sending the message. */
    var frameInfo: ShimWKFrameInfo { get }

    /*! @abstract The name of the message handler to which the message is sent.
     */
    var name: String { get }
}

/*! Contains information about a navigation response, used for making policy decisions.
 */
@objc public protocol ShimWKNavigationResponse {
    /*! @abstract A Boolean value indicating whether the frame being navigated is the main frame.
     */
    var isForMainFrame: Bool { get }

    /*! @abstract The frame's response.
     */
    var response: NSURLResponse { get }

    /*! @abstract A Boolean value indicating whether WebKit can display the response's MIME type natively.
     @discussion Allowing a navigation response with a MIME type that can't be shown will cause the navigation to fail.
     */
    var canShowMIMEType: Bool { get }
}

protocol ShimWKUserContentControllerImpl {
    var userScripts: [ShimWKUserScript] { get }
    func addUserScript(userScript: ShimWKUserScript)
    func removeAllUserScripts()
    func addScriptMessageHandler(handler: ShimWKScriptMessageHandler, name: String)
    func removeScriptMessageHandler(forName name: String)
}

/*! A WKUserContentController object provides a way for JavaScript to post
 messages to a web view.
 The user content controller associated with a web view is specified by its
 web view configuration.
 */
public class ShimWKUserContentController: NSObject, ShimWKUserContentControllerImpl {
    var _impl: ShimWKUserContentControllerImpl!

    public override init() {
        super.init()
        _impl = factory.wrapWKUserContentController(self)
    }

    init(impl: ShimWKUserContentControllerImpl) {
        super.init()
        _impl = impl
    }

    /*! @abstract The user scripts associated with this user content
     controller.
     */
    public var userScripts: [ShimWKUserScript] {
        return _impl.userScripts
    }

    /*! @abstract Adds a user script.
     @param userScript The user script to add.
     */
    public func addUserScript(userScript: ShimWKUserScript) {
        _impl.addUserScript(userScript)
    }

    /*! @abstract Removes all associated user scripts.
     */
    public func removeAllUserScripts() {
        _impl.removeAllUserScripts()
    }

    /*! @abstract Adds a script message handler.
     @param scriptMessageHandler The message handler to add.
     @param name The name of the message handler.
     @discussion Adding a scriptMessageHandler adds a function
     window.webkit.messageHandlers.<name>.postMessage(<messageBody>) for all
     frames.
     */
    public func addScriptMessageHandler(handler: ShimWKScriptMessageHandler, name: String) {
        _impl.addScriptMessageHandler(handler, name: name)
    }

    /*! @abstract Removes a script message handler.
     @param name The name of the message handler to remove.
     */
    public func removeScriptMessageHandler(forName name: String) {
        _impl.removeScriptMessageHandler(forName: name)
    }
}

public protocol ShimWKBackForwardList {
    /*! @abstract The current item.
     */
    var currentItem: ShimWKBackForwardListItem? { get }

    /*! @abstract The item immediately preceding the current item, or nil
     if there isn't one.
     */
    var backItem: ShimWKBackForwardListItem? { get }

    /*! @abstract The item immediately following the current item, or nil
     if there isn't one.
     */
    var forwardItem: ShimWKBackForwardListItem? { get }

    /*! @abstract The portion of the list preceding the current item.
     @discussion The items are in the order in which they were originally
     visited.
     */
    var backList: [ShimWKBackForwardListItem] { get }

    /*! @abstract The portion of the list following the current item.
     @discussion The items are in the order in which they were originally
     visited.
     */
    var forwardList: [ShimWKBackForwardListItem] { get }

    /*! @abstract Returns the item at a specified distance from the current
     item.
     @param index Index of the desired list item relative to the current item:
     0 for the current item, -1 for the immediately preceding item, 1 for the
     immediately following item, and so on.
     @result The item at the specified distance from the current item, or nil
     if the index parameter exceeds the limits of the list.
     */
    func itemAtIndex(index: Int) -> ShimWKBackForwardListItem?
}

public protocol ShimWKBackForwardListItem {
    /*! @abstract The URL of the webpage represented by this item.
     */
    var URL: NSURL { get }

    /*! @abstract The title of the webpage represented by this item.
     */
    var title: String? { get }

    /*! @abstract The URL of the initial request that created this item.
     */
    var initialURL: NSURL { get }
}

protocol ShimWKProcessPoolImpl {}

public class ShimWKProcessPool: NSObject {
    let _impl: ShimWKProcessPoolImpl

    public override init() {
        _impl = factory.wrapWKProcessPool()
    }

    init(impl: ShimWKProcessPoolImpl) {
        _impl = impl
    }
}

protocol ShimWKPreferencesImpl {
    var javaScriptCanOpenWindowsAutomatically: Bool { get set }
}

/*! A WKPreferences object encapsulates the preference settings for a web
 view. The preferences object associated with a web view is specified by
 its web view configuration.
 */
public class ShimWKPreferences: NSObject, ShimWKPreferencesImpl {
    var _impl: ShimWKPreferencesImpl

    public override init() {
        _impl = factory.wrapWKPreferences()
    }

    init(impl: ShimWKPreferencesImpl) {
        _impl = impl
    }

    /*! @abstract A Boolean value indicating whether JavaScript can open
     windows without user interaction.
     @discussion The default value is NO in iOS and YES in OS X.
     */
    public var javaScriptCanOpenWindowsAutomatically: Bool {
        get {
            return _impl.javaScriptCanOpenWindowsAutomatically
        }
        set {
            _impl.javaScriptCanOpenWindowsAutomatically = newValue
        }
    }
}

protocol ShimWKUserScriptImpl {
    var source: String { get }
    var injectionTime: ShimWKUserScriptInjectionTime { get }
    var isForMainFrameOnly: Bool { get }
    init(source: String, injectionTime: ShimWKUserScriptInjectionTime, forMainFrameOnly: Bool)
}

public class ShimWKUserScript: ShimWKUserScriptImpl {
    var _impl: ShimWKUserScriptImpl

    /*! @abstract Returns an initialized user script that can be added to a @link WKUserContentController @/link.
     @param source The script source.
     @param injectionTime When the script should be injected.
     @param forMainFrameOnly Whether the script should be injected into all frames or just the main frame.
     */
    public required init(source: String, injectionTime: ShimWKUserScriptInjectionTime, forMainFrameOnly: Bool) {
        _impl = factory.wrapWKUserScript(source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly)
    }

    /* @abstract The script source code. */
    public var source: String {
        return _impl.source
    }

    /* @abstract When the script should be injected. */
    public var injectionTime: ShimWKUserScriptInjectionTime {
        return _impl.injectionTime
    }

    /* @abstract Whether the script should be injected into all frames or just the main frame. */
    public var isForMainFrameOnly: Bool {
        return _impl.isForMainFrameOnly
    }
}

protocol ShimWKWebsiteDataStoreImpl {
    func removeDataOfTypes(websiteDataTypes: Set<String>, modifiedSince date: NSDate, completionHandler: () -> ())
}

public class ShimWKWebsiteDataStore: NSObject, ShimWKWebsiteDataStoreImpl {
    var _impl: ShimWKWebsiteDataStoreImpl

    private static var defaultStore = ShimWKWebsiteDataStore(persistent: true)

    private init(persistent: Bool) {
        _impl = factory.wrapWKWebsiteDataStore(persistent: persistent)
    }

    init(impl: ShimWKWebsiteDataStoreImpl) {
        _impl = impl
    }

    /* @abstract Returns the default data store. */
    public static func defaultDataStore() -> ShimWKWebsiteDataStore {
        return defaultStore
    }

    /** @abstract Returns a new non-persistent data store.
     @discussion If a WKWebView is associated with a non-persistent data store, no data will
     be written to the file system. This is useful for implementing "private browsing" in a web view.
     */
    public static func nonPersistent() -> ShimWKWebsiteDataStore {
        return ShimWKWebsiteDataStore(persistent: false)
    }

    /*! @abstract Removes all website data of the given types that has been modified since the given date.
     @param dataTypes The website data types that should be removed.
     @param date A date. All website data modified after this date will be removed.
     @param completionHandler A block to invoke when the website data has been removed.
     */
    public func removeDataOfTypes(websiteDataTypes: Set<String>, modifiedSince date: NSDate, completionHandler: () -> ()) {
        _impl.removeDataOfTypes(websiteDataTypes, modifiedSince: date, completionHandler: completionHandler)
    }
}

public protocol ShimWKWebsiteDataRecord {
    /*! @abstract The display name for the data record. This is usually the domain name. */
    var displayName: String { get }

    /*! @abstract The various types of website data that exist for this data record. */
    var dataTypes: Set<String> { get }
}

public protocol ShimWKScriptMessageHandler: class {
    /*! @abstract Invoked when a script message is received from a webpage.
     @param userContentController The user content controller invoking the
     delegate method.
     @param message The script message received.
     */
    func userContentController(userContentController: ShimWKUserContentController, didReceiveScriptMessage message: ShimWKScriptMessage)
}

@objc public protocol ShimWKNavigationDelegate: NSObjectProtocol {
    /*! @abstract Decides whether to allow or cancel a navigation.
     @param webView The web view invoking the delegate method.
     @param navigationAction Descriptive information about the action
     triggering the navigation request.
     @param decisionHandler The decision handler to call to allow or cancel the
     navigation. The argument is one of the constants of the enumerated type WKNavigationActionPolicy.
     @discussion If you do not implement this method, the web view will load the request or, if appropriate, forward it to another application.
     */
    optional func webView(webView: ShimWKWebView, decidePolicyForNavigationAction navigationAction: ShimWKNavigationAction, decisionHandler: ShimWKNavigationActionPolicy -> ())

    /*! @abstract Decides whether to allow or cancel a navigation after its
     response is known.
     @param webView The web view invoking the delegate method.
     @param navigationResponse Descriptive information about the navigation
     response.
     @param decisionHandler The decision handler to call to allow or cancel the
     navigation. The argument is one of the constants of the enumerated type WKNavigationResponsePolicy.
     @discussion If you do not implement this method, the web view will allow the response, if the web view can show it.
     */
    optional func webView(webView: ShimWKWebView, decidePolicyForNavigationResponse navigationResponse: ShimWKNavigationResponse, decisionHandler: ShimWKNavigationResponsePolicy -> ())

    /*! @abstract Invoked when a main frame navigation starts.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     */
    optional func webView(webView: ShimWKWebView, didStartProvisionalNavigation navigation: ShimWKNavigation!)

    /*! @abstract Invoked when a server redirect is received for the main
     frame.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     */
    optional func webView(webView: ShimWKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: ShimWKNavigation!)

    /*! @abstract Invoked when an error occurs while starting to load data for
     the main frame.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     @param error The error that occurred.
     */
    optional func webView(webView: ShimWKWebView, didFailProvisionalNavigation navigation: ShimWKNavigation!, withError error: NSError)

    /*! @abstract Invoked when content starts arriving for the main frame.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     */
    optional func webView(webView: ShimWKWebView, didCommitNavigation navigation: ShimWKNavigation!)

    /*! @abstract Invoked when a main frame navigation completes.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     */
    optional func webView(webView: ShimWKWebView, didFinishNavigation navigation: ShimWKNavigation!)

    /*! @abstract Invoked when an error occurs during a committed main frame
     navigation.
     @param webView The web view invoking the delegate method.
     @param navigation The navigation.
     @param error The error that occurred.
     */
    optional func webView(webView: ShimWKWebView, didFailNavigation navigation: ShimWKNavigation!, withError error: NSError)

    /*! @abstract Invoked when the web view needs to respond to an authentication challenge.
     @param webView The web view that received the authentication challenge.
     @param challenge The authentication challenge.
     @param completionHandler The completion handler you must invoke to respond to the challenge. The
     disposition argument is one of the constants of the enumerated type
     NSURLSessionAuthChallengeDisposition. When disposition is NSURLSessionAuthChallengeUseCredential,
     the credential argument is the credential to use, or nil to indicate continuing without a
     credential.
     @discussion If you do not implement this method, the web view will respond to the authentication challenge with the NSURLSessionAuthChallengeRejectProtectionSpace disposition.
     */
    optional func webView(webView: ShimWKWebView, didReceiveAuthenticationChallenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> ())

    /*! @abstract Invoked when the web view's web content process is terminated.
     @param webView The web view whose underlying web content process was terminated.
     */
    optional func webViewWebContentProcessDidTerminate(webView: ShimWKWebView)
}

@objc public protocol ShimWKUIDelegate: class {
    /*! @abstract Creates a new web view.
     @param webView The web view invoking the delegate method.
     @param configuration The configuration to use when creating the new web
     view.
     @param navigationAction The navigation action causing the new web view to
     be created.
     @param windowFeatures Window features requested by the webpage.
     @result A new web view or nil.
     @discussion The web view returned must be created with the specified configuration. WebKit will load the request in the returned web view.

     If you do not implement this method, the web view will cancel the navigation.
     */
    optional func webView(webView: ShimWKWebView, createWebViewWithConfiguration configuration: ShimWKWebViewConfiguration, forNavigationAction navigationAction: ShimWKNavigationAction, windowFeatures: ShimWKWindowFeatures) -> ShimWKWebView?


    /*! @abstract Notifies your app that the DOM window object's close() method completed successfully.
     @param webView The web view invoking the delegate method.
     @discussion Your app should remove the web view from the view hierarchy and update
     the UI as needed, such as by closing the containing browser tab or window.
     */
    optional func webViewDidClose(webView: ShimWKWebView)

    /*! @abstract Displays a JavaScript alert panel.
     @param webView The web view invoking the delegate method.
     @param message The message to display.
     @param frame Information about the frame whose JavaScript initiated this
     call.
     @param completionHandler The completion handler to call after the alert
     panel has been dismissed.
     @discussion For user security, your app should call attention to the fact
     that a specific website controls the content in this panel. A simple forumla
     for identifying the controlling website is frame.request.URL.host.
     The panel should have a single OK button.

     If you do not implement this method, the web view will behave as if the user selected the OK button.
     */
    optional func webView(webView: ShimWKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: ShimWKFrameInfo, completionHandler: () -> ())


    /*! @abstract Displays a JavaScript confirm panel.
     @param webView The web view invoking the delegate method.
     @param message The message to display.
     @param frame Information about the frame whose JavaScript initiated this call.
     @param completionHandler The completion handler to call after the confirm
     panel has been dismissed. Pass YES if the user chose OK, NO if the user
     chose Cancel.
     @discussion For user security, your app should call attention to the fact
     that a specific website controls the content in this panel. A simple forumla
     for identifying the controlling website is frame.request.URL.host.
     The panel should have two buttons, such as OK and Cancel.

     If you do not implement this method, the web view will behave as if the user selected the Cancel button.
     */
    optional func webView(webView: ShimWKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: ShimWKFrameInfo, completionHandler: Bool -> ())


    /*! @abstract Displays a JavaScript text input panel.
     @param webView The web view invoking the delegate method.
     @param message The message to display.
     @param defaultText The initial text to display in the text entry field.
     @param frame Information about the frame whose JavaScript initiated this call.
     @param completionHandler The completion handler to call after the text
     input panel has been dismissed. Pass the entered text if the user chose
     OK, otherwise nil.
     @discussion For user security, your app should call attention to the fact
     that a specific website controls the content in this panel. A simple forumla
     for identifying the controlling website is frame.request.URL.host.
     The panel should have two buttons, such as OK and Cancel, and a field in
     which to enter text.

     If you do not implement this method, the web view will behave as if the user selected the Cancel button.
     */
    optional func webView(webView: ShimWKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: ShimWKFrameInfo, completionHandler: String? -> ())
}

public typealias ShimWKNavigationActionPolicy = WKNavigationActionPolicy
public typealias ShimWKNavigationResponsePolicy = WKNavigationResponsePolicy
public typealias ShimWKUserScriptInjectionTime = WKUserScriptInjectionTime
public typealias ShimWKNavigationType = WKNavigationType

public let ShimWKWebsiteDataTypeDiskCache = WKWebsiteDataTypeDiskCache
public let ShimWKWebsiteDataTypeMemoryCache = WKWebsiteDataTypeMemoryCache
public let ShimWKWebsiteDataTypeOfflineWebApplicationCache = WKWebsiteDataTypeOfflineWebApplicationCache
public let ShimWKWebsiteDataTypeCookies = WKWebsiteDataTypeCookies
public let ShimWKWebsiteDataTypeSessionStorage = WKWebsiteDataTypeSessionStorage
public let ShimWKWebsiteDataTypeLocalStorage = WKWebsiteDataTypeLocalStorage
public let ShimWKWebsiteDataTypeWebSQLDatabases = WKWebsiteDataTypeWebSQLDatabases
public let ShimWKWebsiteDataTypeIndexedDBDatabases = WKWebsiteDataTypeIndexedDBDatabases
