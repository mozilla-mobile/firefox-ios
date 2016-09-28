/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class ContentBlocker: NSURLProtocol, NSURLSessionDelegate, NSURLSessionDataDelegate {
    private static let blockList = BlockList()
    private var dataTask: NSURLSessionDataTask?

    override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }

    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        return true
    }

    override func startLoading() {
        guard let url = request.URL where !ContentBlocker.blockList.isBlocked(url) else { return }

        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        dataTask = session.dataTaskWithRequest(request)
        dataTask?.resume()

    }

    override func stopLoading() {
        dataTask?.cancel()
    }

    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .Allowed)
        completionHandler(.Allow)
    }

    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        client?.URLProtocol(self, didLoadData: data)
    }

    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let error = error {
            client?.URLProtocol(self, didFailWithError: error)
            return
        }

        client?.URLProtocolDidFinishLoading(self)
    }

    func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        client?.URLProtocol(self, wasRedirectedToRequest: request, redirectResponse: response)
        completionHandler(request)
    }
}

private class BlockRule {
    private let regex: NSRegularExpression
    private let domainExceptions: [NSRegularExpression]?

    init(regex: NSRegularExpression, domainExceptions: [NSRegularExpression]?) {
        self.regex = regex
        self.domainExceptions = domainExceptions
    }
}

private class BlockList {
    private var blockRules = [BlockRule]()

    init() {
        let lists = ["disconnect-advertising",
                     "disconnect-analytics",
                     "disconnect-social"]

        for filename in lists {
            let path = NSBundle.mainBundle().pathForResource(filename, ofType: "json")
            let json = NSData(contentsOfFile: path!)
            let list = try! NSJSONSerialization.JSONObjectWithData(json!, options: []) as! [[String: AnyObject]]
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
                    regex = regex.stringByReplacingOccurrencesOfString(".", withString: "\\.")
                    return try! NSRegularExpression(pattern: regex, options: [])
                }

                blockRules.append(BlockRule(regex: filterRegex, domainExceptions: domainExceptions))
            }
        }
    }

    func isBlocked(url: NSURL) -> Bool {
        guard let absoluteString = url.absoluteString,
              let host = url.host else { return false }

        let range = NSRange(location: 0, length: absoluteString.characters.count)

        domainSearch: for rule in blockRules {
            // First, test the top-level filters to see if this URL might be blocked.
            if rule.regex.firstMatchInString(absoluteString, options: .Anchored, range: range) != nil {
                // We matched, and there are no exceptions.
                guard let domainExceptions = rule.domainExceptions else {
                    return true
                }

                // Check the domain exceptions. If a domain exception matches, this filter does not apply.
                for domainRegex in domainExceptions {
                    let range = NSRange(location: 0, length: host.characters.count)
                    if domainRegex.firstMatchInString(host, options: [], range: range) != nil {
                        continue domainSearch
                    }
                }

                return true
            }
        }

        return false
    }
}
