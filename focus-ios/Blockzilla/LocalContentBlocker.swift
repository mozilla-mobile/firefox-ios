/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class ContentBlockerHelper {
    static func compileItem(item: String, callback: @escaping (WKContentRuleList) -> Void) {
        let path = Bundle.main.path(forResource: item, ofType: "json")!
        guard let jsonFileContent = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) else { fatalError("Rule list for \(item) doesn't exist!") }
        WKContentRuleListStore.default().compileContentRuleList(forIdentifier: item, encodedContentRuleList: jsonFileContent) { (ruleList, error) in
            guard let ruleList = ruleList else { fatalError("problem compiling \(item)") }
            callback(ruleList)
        }
    }

    static func getBlockLists(callback: @escaping ([WKContentRuleList]) -> Void) {
        // If we already have a list, return it
        let enabledList = Utils.getEnabledLists()
        var returnList = [WKContentRuleList]()
        let dispatchGroup = DispatchGroup()
        let listStore = WKContentRuleListStore.default()

        for list in enabledList {
            dispatchGroup.enter()

            listStore?.lookUpContentRuleList(forIdentifier: list) { (ruleList, error) in
                if let ruleList = ruleList {
                    returnList.append(ruleList)
                    dispatchGroup.leave()
                } else {
                    ContentBlockerHelper.compileItem(item: list) { ruleList in
                        returnList.append(ruleList)
                        dispatchGroup.leave()
                    }
                }
            }
        }

        dispatchGroup.notify(queue: .global()) {
            callback(returnList)
        }
    }
}
