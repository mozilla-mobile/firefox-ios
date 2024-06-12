/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import CryptoKit

class ContentBlockerHelper {
    static let shared = ContentBlockerHelper()

    var handler: (([WKContentRuleList]) -> Void)?

    let ruleStore = WKContentRuleListStore.default()

    func updateContentRuleListIfNeeded() {
        removeOldListsByHashFromStore { [weak self] in
            self?.removeOldListsByNameFromStore {
                self?.getBlockLists { list in
                    self?.handler?(list)
                }
            }
        }
    }

    private func removeOldListsByNameFromStore(completion: @escaping () -> Void) {
        var noMatchingIdentifierFoundForRule = false

        ruleStore?.getAvailableContentRuleListIdentifiers { available in
            guard let available = available else {
                completion()
                return
            }

            let blocklists = Utils.getEnabledLists()
            // If any file from the list on disk is not installed, remove all the rules and re-install them
            for listOnDisk in blocklists where !available.contains(where: { $0 == listOnDisk }) {
                noMatchingIdentifierFoundForRule = true
                break
            }

            if !noMatchingIdentifierFoundForRule {
                completion()
                return
            }

            self.removeAllRulesInStore {
                completion()
            }
        }
    }

    // If any blocker files have a newer hash than the hash saved in defaults,
    // remove all the content blockers and reload them.
    private func removeOldListsByHashFromStore(completion: @escaping () -> Void) {
        if hasBlockerFileChanged() {
            removeAllRulesInStore {
                completion()
            }
        } else {
            completion()
        }
    }

    private func removeAllRulesInStore(completion: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        ruleStore?.getAvailableContentRuleListIdentifiers { [weak self] available in
            guard let available = available else {
                completion()
                return
            }
            for filename in available {
                dispatchGroup.enter()
                self?.ruleStore?.removeContentRuleList(forIdentifier: filename) { _ in
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: DispatchQueue.main) {
                completion()
            }
        }
    }

    private func calculateHash(forFileAtPath path: String) -> String? {
        guard let fileData = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }

        let hash = SHA256.hash(data: fileData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func hasBlockerFileChanged() -> Bool {
        let blocklists = Utils.getEnabledLists()
        let defaults = UserDefaults.standard
        var hasChanged = false

        for list in blocklists {
            guard let path = Bundle.main.path(forResource: list, ofType: "json"),
                  let newHash = calculateHash(forFileAtPath: path) else { continue }

            let oldHash = defaults.string(forKey: list)
            if oldHash != newHash {
                defaults.set(newHash, forKey: list)
                hasChanged = true
            }
        }

        return hasChanged
    }

    func reload() {
        guard let handler = handler else { return }
        getBlockLists(callback: handler)
    }

    func getBlockLists(callback: @escaping ([WKContentRuleList]) -> Void) {
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

    private static func compileItem(item: String, callback: @escaping (WKContentRuleList) -> Void) {
        let path = Bundle.main.path(forResource: item, ofType: "json")!
        guard let jsonFileContent = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) else { fatalError("Rule list for \(item) doesn't exist!") }
        WKContentRuleListStore.default().compileContentRuleList(forIdentifier: item, encodedContentRuleList: jsonFileContent) { (ruleList, error) in
            guard let ruleList = ruleList else { fatalError("problem compiling \(item)") }
            callback(ruleList)
        }
    }
}
