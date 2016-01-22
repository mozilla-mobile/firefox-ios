/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import WebKit
import Storage

/**
 Data API accessibile to pages inside a WebViewPanel

 - GetBookmarkModelForID: Returns the bookmark model for the given GUID
 - GetRootBookmarkFolder: Returns the root bookmark model
 - getSitesByLastVisit:   Returns history items ordered by last visit
 - getTopSites:           Returns top sites ordered by frecency limited to the given limit
 - getClientsAndTabs:     Returns all cached remote clients and tabs
 - Undefined:             Default case for any message not recognized
 */
private enum DataMethod: String {

    /* 
    getSitesByLastVisit
        {
            method: "getSitesByLastVisit",
            params: {
                limit: <Int>
            },
            callback: <CallbackFunc>
        }
    */
    case getSitesByLastVisit        = "getSitesByLastVisit"

    /* 
    getTopSites
        {
            method: "getTopSites",
            params: {
                limit: <Int>
            },
            callback: <CallbackFunc>
        }
    */
    case getTopSites                = "getTopSites"

    /* 
    getLocalBookmarks
        {
            method: "getLocalBookmarks",
            params: {
                limit: <Int>
            },
            callback: <CallbackFunc>
        }
    */
    case getLocalBookmarks          = "getLocalBookmarks"
    case Undefined
}

private class WebPanelDataAPI: NSObject, WKScriptMessageHandler {
    typealias DataAPIHandler = (params: [String: AnyObject], callback: String?) -> Void

    unowned let profile: Profile

    unowned let webView: WKWebView

    private var handlers = [DataMethod: DataAPIHandler]()

    init(webView: WKWebView, profile: Profile) {
        self.webView = webView
        self.profile = profile
        super.init()
    }

    func registerHandlerForMethod(method: DataMethod, handler: DataAPIHandler) {
        handlers[method] = handler
    }

    @objc func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let messageDict = message.body as? [String: AnyObject],
              let methodName = messageDict["method"] as? String,
        let params = messageDict["params"] as? [String: AnyObject] else {
            return
        }

        let callback = messageDict["callback"] as? String
        let method = DataMethod(rawValue: methodName) ?? .Undefined
        handlers[method]?(params: params, callback: callback)
    }
}

// MARK: DictionaryView extension for data models

protocol DictionaryView {
    func toDictionary() -> [String: AnyObject]
}

extension BookmarksModel: DictionaryView {
    func toDictionary() -> [String: AnyObject] {
        return [String: String]()
    }
}

extension Site: DictionaryView {
    func toDictionary() -> [String: AnyObject] {
        let iconURL = icon?.url != nil ? icon?.url : ""
        return [
            "title": title,
            "url": url,
            "date": NSNumber(unsignedLongLong: (latestVisit?.date)!),
            "iconURL": iconURL!,
        ]
    }
}

extension RemoteTab: DictionaryView {
    func toDictionary() -> [String: AnyObject] {
        return [String: String]()
    }
}

class WebViewPanel: UIViewController, HomePanel {

    weak var homePanelDelegate: HomePanelDelegate?

    private let url: NSURL
    private let profile: Profile

    private lazy var webView: WKWebView = {
        let webView = WKWebView()
        let dataAPI = WebPanelDataAPI(webView: webView, profile: self.profile)
        webView.configuration.userContentController.addScriptMessageHandler(dataAPI, name: "mozAPI")

        dataAPI.registerHandlerForMethod(DataMethod.getSitesByLastVisit) { params, callback in
            guard let limit = params["limit"] as? Int,
                  let callback = callback else {
                return
            }

            self.profile.history.getSitesByLastVisit(limit).uponQueue(dispatch_get_main_queue()) { result in
                let callbackInvocation: String
                do {
                    if let sites = result.successValue {
                        let data: [NSDictionary] = sites.map { $0!.toDictionary() }
                        let jsonData = try NSJSONSerialization.dataWithJSONObject(data, options: [])
                        let jsonString = String(data: jsonData, encoding: NSUTF8StringEncoding)!
                        callbackInvocation = "\(callback)(null, \(jsonString))"
                    } else {
                        var err = [String: AnyObject]()
                        err["message"] = result.failureValue?.description ?? "No description"
                        let jsonData = try NSJSONSerialization.dataWithJSONObject(err, options: [])
                        let jsonString = String(data: jsonData, encoding: NSUTF8StringEncoding)!
                        callbackInvocation = "\(callback)(\(jsonString)), null)"
                    }
                } catch _ {
                    callbackInvocation = "\(callback)(null, null)"
                }

                self.webView.evaluateJavaScript(callbackInvocation, completionHandler: nil)
            }
        }

        dataAPI.registerHandlerForMethod(DataMethod.getTopSites) { params, callback in
            guard let limit = params["limit"] as? Int,
                  let callback = callback else {
                return
            }

            self.profile.history.getTopSitesWithLimit(limit).uponQueue(dispatch_get_main_queue()) { result in
                let callbackInvocation: String
                do {
                    if let sites = result.successValue {
                        let data: [NSDictionary] = sites.map { $0!.toDictionary() }
                        let jsonData = try NSJSONSerialization.dataWithJSONObject(data, options: [])
                        let jsonString = String(data: jsonData, encoding: NSUTF8StringEncoding)!
                        callbackInvocation = "\(callback)(null, \(jsonString))"
                    } else {
                        var err = [String: AnyObject]()
                        err["message"] = result.failureValue?.description ?? "No description"
                        let jsonData = try NSJSONSerialization.dataWithJSONObject(err, options: [])
                        let jsonString = String(data: jsonData, encoding: NSUTF8StringEncoding)!
                        callbackInvocation = "\(callback)(\(jsonString)), null)"
                    }
                } catch _ {
                    callbackInvocation = "\(callback)(null, null)"
                }

                self.webView.evaluateJavaScript(callbackInvocation, completionHandler: nil)
            }
        }

        return webView
    }()

    init(profile: Profile, url: String) {
        self.profile = profile
        self.url = url.asURL!
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(webView)
        webView.snp_makeConstraints { make in
            make.edges.equalTo(view)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let request = NSURLRequest(URL: url)
        webView.loadRequest(request)
    }
}