// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

enum WKContentBlocklistFileName: String, CaseIterable {
    case advertisingURLs = "disconnect-block-advertising"
    case analyticsURLs = "disconnect-block-analytics"
    case socialURLs = "disconnect-block-social"
    case cryptomining = "disconnect-block-cryptomining"
    case fingerprinting = "disconnect-block-fingerprinting"
    case advertisingCookies = "disconnect-block-cookies-advertising"
    case analyticsCookies = "disconnect-block-cookies-analytics"
    case socialCookies = "disconnect-block-cookies-social"

    static var standardSet: [WKContentBlocklistFileName] {
        return [
            .advertisingCookies,
            .analyticsCookies,
            .socialCookies,
            .cryptomining,
            .fingerprinting
        ]
    }

    static var strictSet: [WKContentBlocklistFileName] {
        return [
            .advertisingURLs,
            .analyticsURLs,
            .socialURLs,
            cryptomining,
            fingerprinting
        ]
    }
}

struct WKNoImageModeDefaults {
    static let Script = "[{'trigger':{'url-filter':'.*','resource-type':['image']},'action':{'type':'block'}}]"
        .replacingOccurrences(of: "'", with: "\"")
    static let ScriptName = "images"
}

enum WKContentBlockerState {
    case notReady
    case ready
}

class WKContentBlocker {
    private(set) var state: WKContentBlockerState = .notReady
    private let ruleStore = WKContentRuleListStore.default()
    private var blockImagesRule: WKContentRuleList?

    // MARK: - Initializer

    init(blockImagesRule: WKContentRuleList? = nil) {
        ruleStore?.compileContentRuleList(
            forIdentifier: WKNoImageModeDefaults.ScriptName,
            encodedContentRuleList: WKNoImageModeDefaults.Script) { rule, error in
                guard error == nil, rule != nil else { return }
                self.blockImagesRule = rule
            }

        // TODO: Read safelist during startup
        // TODO: Clean up and remove old blocker file lists based on date and name, if newer available
        
        compileListsNotInStore {
            self.state = .ready
        }
    }

    // MARK: - Internal Utility

    private func safelistAsJSON() -> String {
        // TODO: Compile safelist domains

        /*
        if safelistedDomains.domainSet.isEmpty {
            return ""
        }
        // Note that * is added to the front of domains, so foo.com becomes *foo.com
        let list = "'*" + safelistedDomains.domainSet.joined(separator: "','*") + "'"
         */
        let list = ""

        return ", {'action': { 'type': 'ignore-previous-rules' }, 'trigger': { 'url-filter': '.*', 'if-domain': [\(list)] }}"
            .replacingOccurrences(of: "'", with: "\"")
    }


    private func compileListsNotInStore(completion: @escaping () -> Void) {
        let blocklists = WKContentBlocklistFileName.allCases.map { $0.rawValue }
        let dispatchGroup = DispatchGroup()
        blocklists.forEach { filename in
            dispatchGroup.enter()
            ruleStore?.lookUpContentRuleList(forIdentifier: filename) { [weak self] contentRuleList, error in
                if contentRuleList != nil {
                    dispatchGroup.leave()
                    return
                }
                self?.loadJsonFromBundle(forResource: filename) { jsonString in
                    var str = jsonString
                    guard let self,
                          let range = str.range(of: "]", options: String.CompareOptions.backwards)
                    else {
                        dispatchGroup.leave()
                        return
                    }
                    str = str.replacingCharacters(in: range, with: self.safelistAsJSON() + "]")
                    self.ruleStore?.compileContentRuleList(
                        forIdentifier: filename,
                        encodedContentRuleList: str
                    ) { rule, error in
                        defer {
                            dispatchGroup.leave()
                        }
                        guard error == nil, rule != nil else { return }
                    }
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }

    private func loadJsonFromBundle(forResource file: String, completion: @escaping (_ jsonString: String) -> Void) {
        DispatchQueue.global().async {
            guard let path = Bundle.main.path(forResource: file, ofType: "json"),
                  let source = try? String(contentsOfFile: path, encoding: .utf8)
            else {
                assertionFailure("Error unwrapping the resource contents")
                return
            }

            DispatchQueue.main.async {
                completion(source)
            }
        }
    }
}
