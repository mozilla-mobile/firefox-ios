/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol LocalContentBlockerDelegate: class {
    func localContentBlocker(_ localContentBlocker: LocalContentBlocker, didReceiveDataForMainDocumentURL url: URL?)
}

class LocalContentBlocker: URLProtocol, URLSessionDelegate, URLSessionDataDelegate {
    static weak var delegate: LocalContentBlockerDelegate?

    private static var blockList = BlockList(lists: Utils.getEnabledLists())

    private var dataTask: URLSessionDataTask?

    static func reload() {
        DispatchQueue.global().async {
            let blockList = BlockList(lists: Utils.getEnabledLists())
            DispatchQueue.main.async {
                self.blockList = blockList
            }
        }
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override func startLoading() {
        guard !LocalContentBlocker.blockList.isBlocked(request) else {
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Length": "0"])
            client?.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        var mutableRequest = request
        mutableRequest.addValue("1", forHTTPHeaderField: "DNT")

        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        dataTask = session.dataTask(with: mutableRequest)
        dataTask?.resume()
    }

    override func stopLoading() {
        dataTask?.cancel()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        // urlSession:willPerformHTTPRedirection doesn't catch all request updates (e.g., HSTS),
        // so handle them here instead.
        if let originalRequest = dataTask.originalRequest,
           let currentRequest = dataTask.currentRequest,
           originalRequest.url != currentRequest.url {
                let response = URLResponse()
                client?.urlProtocol(self, wasRedirectedTo: currentRequest, redirectResponse: response)
                completionHandler(.cancel)
                return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowedInMemoryOnly)
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let mainDocumentURL = self.request.mainDocumentURL
        DispatchQueue.main.async {
            LocalContentBlocker.delegate?.localContentBlocker(self, didReceiveDataForMainDocumentURL: mainDocumentURL)
        }

        client?.urlProtocol(self, didLoad: data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            guard let request = task.currentRequest,
                  let url = request.url,
                  url == request.mainDocumentURL else {
                client?.urlProtocol(self, didFailWithError: error)
                session.finishTasksAndInvalidate()
                return
            }

            // Loading error pages here over the UIWebView delegate ensures the page gets added to
            // the UIWebView's back/forward list.
            let errorPage = ErrorPage(error: error).data
            client?.urlProtocol(self, didReceive: URLResponse(), cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: errorPage)
        }

        client?.urlProtocolDidFinishLoading(self)
        session.finishTasksAndInvalidate()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
        completionHandler(request)
    }
}

private enum LoadType {
    case all
    case thirdParty
}

private enum ResourceType {
    case all
    case font
}

private let fontExtensions = ["woff", "woff2", "ttf"]

private class BlockRule {
    let regex: NSRegularExpression
    let loadType: LoadType
    let resourceType: ResourceType
    let domainExceptions: [NSRegularExpression]?

    init(regex: NSRegularExpression, loadType: LoadType, resourceType: ResourceType, domainExceptions: [NSRegularExpression]?) {
        self.regex = regex
        self.loadType = loadType
        self.resourceType = resourceType
        self.domainExceptions = domainExceptions
    }
}

private class BlockList {
    fileprivate var blockRules = [BlockRule]()

    init(lists: [String]) {
        for filename in lists {
            let path = pathForResource(filename)
            let json = try? Data(contentsOf: URL(fileURLWithPath: path))
            let list = try! JSONSerialization.jsonObject(with: json!, options: []) as! [[String: AnyObject]]
            for rule in list {
                let trigger = rule["trigger"] as! [String: AnyObject]
                let filter = trigger["url-filter"] as! String
                let filterRegex = try! NSRegularExpression(pattern: filter, options: [])

                let domainExceptions: [NSRegularExpression]? = (trigger["unless-domain"] as? [String])?.map { domain in
                    // Convert the domain exceptions into regular expressions.
                    var regex = domain + "$"
                    if regex.characters.first == "*" {
                        regex = "." + regex
                    }
                    regex = regex.replacingOccurrences(of: ".", with: "\\.")
                    return try! NSRegularExpression(pattern: regex, options: [])
                }

                // Only "third-party" is supported; other types are not used in our block lists.
                let loadTypes = trigger["load-type"] as? [String] ?? []
                let loadType = loadTypes.contains("third-party") ? LoadType.thirdParty : .all

                // Only "font" is supported; other types are not used in our block lists.
                let resourceTypes = trigger["resource-type"] as? [String] ?? []
                let resourceType = resourceTypes.contains("font") ? ResourceType.font : .all

                blockRules.append(BlockRule(regex: filterRegex, loadType: loadType, resourceType: resourceType, domainExceptions: domainExceptions))
            }
        }
    }

    private func pathForResource(_ resource: String) -> String {
        return Bundle.main.path(forResource: resource, ofType: "json")!
    }

    func isBlocked(_ request: URLRequest) -> Bool {
        guard let documentUrl = request.mainDocumentURL,
              let documentHost = documentUrl.host,
            let resourceUrl = request.url else {
            return false
        }

        let resourceString = resourceUrl.absoluteString
        let resourceRange = NSMakeRange(0, (resourceString as NSString).length)
        let documentString = documentUrl.absoluteString
        let documentRange = NSMakeRange(0, (documentString as NSString).length)

        domainSearch: for rule in blockRules {
            // If this is a font rule, only proceed if this resource is a font.
            if rule.resourceType == .font && !fontExtensions.contains(resourceUrl.pathExtension) {
                continue
            }

            // First, test the top-level filters to see if this URL might be blocked.
            if rule.regex.firstMatch(in: resourceString, options: .anchored, range: resourceRange) != nil {
                // If this is a third-party load, don't block first-party sites.
                if rule.loadType == .thirdParty {
                    if rule.regex.firstMatch(in: documentString, options: .anchored, range: documentRange) != nil {
                        continue
                    }
                }

                // We matched, and there are no exceptions.
                guard let domainExceptions = rule.domainExceptions else {
                    return true
                }

                // Check the domain exceptions. If a domain exception matches, this filter does not apply.
                for domainRegex in domainExceptions {
                    let range = NSMakeRange(0, (documentHost as NSString).length)
                    if domainRegex.firstMatch(in: documentHost, options: [], range: range) != nil {
                        continue domainSearch
                    }
                }

                return true
            }
        }

        return false
    }
}
