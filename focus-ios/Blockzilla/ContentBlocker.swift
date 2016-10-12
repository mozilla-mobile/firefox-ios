/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class ContentBlocker: URLProtocol, URLSessionDelegate, URLSessionDataDelegate {
    fileprivate static let blockList = BlockList()
    fileprivate var dataTask: URLSessionDataTask?

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override func startLoading() {
        guard !ContentBlocker.blockList.isBlocked(request) else {
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Length": "0"])
            client?.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        let configuration = URLSessionConfiguration.default
        let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        dataTask = session.dataTask(with: request)
        dataTask?.resume()
    }

    override func stopLoading() {
        dataTask?.cancel()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
        completionHandler(request)
    }
}

private enum BlockType {
    case all
    case thirdParty
}

private class BlockRule {
    let regex: NSRegularExpression
    let type: BlockType
    let domainExceptions: [NSRegularExpression]?

    init(regex: NSRegularExpression, type: BlockType, domainExceptions: [NSRegularExpression]?) {
        self.regex = regex
        self.type = type
        self.domainExceptions = domainExceptions
    }
}

private class BlockList {
    fileprivate var blockRules = [BlockRule]()

    init() {
        let lists = ["disconnect-advertising",
                     "disconnect-analytics",
                     "disconnect-social"]

        for filename in lists {
            let path = Bundle.main.path(forResource: filename, ofType: "json")
            let json = try? Data(contentsOf: URL(fileURLWithPath: path!))
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

                // "first-party" is not supported since we don't use it in any block lists.
                let loadTypes = trigger["load-type"] as? [String] ?? []
                let blockType = loadTypes.contains("third-party") ? BlockType.thirdParty : .all

                blockRules.append(BlockRule(regex: filterRegex, type: blockType, domainExceptions: domainExceptions))
            }
        }
    }

    func isBlocked(_ request: URLRequest) -> Bool {
        guard let documentUrl = request.mainDocumentURL,
              let documentHost = documentUrl.host,
            let resourceUrl = request.url else {
            return false
        }

        let resourceString = resourceUrl.absoluteString
        let resourceRange = NSRange(location: 0, length: resourceString.characters.count)
        let documentString = documentUrl.absoluteString
        let documentRange = NSRange(location: 0, length: documentString.characters.count)

        domainSearch: for rule in blockRules {
            // First, test the top-level filters to see if this URL might be blocked.
            if rule.regex.firstMatch(in: resourceString, options: .anchored, range: resourceRange) != nil {
                // If this is a third-party load, don't block first-party sites.
                if rule.type == .thirdParty {
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
                    let range = NSRange(location: 0, length: documentHost.characters.count)
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
