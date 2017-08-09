import WebKit

@available(iOS 11.0, *)
class ContentBlockerHelper {

    enum SettingsToggle: String {
        case blockAds = "BlockAds"
        case blockAnalytics = "BlockAnalytics"
        case blockSocial = "BlockSocial"
        case blockOther = "BlockOther"
        case blockFonts = "BlockFonts"
    }

    let blocklists: [SettingsToggle: String] = [
        .blockAds: "disconnect-advertising",
        .blockAnalytics: "disconnect-analytics",
        .blockSocial: "disconnect-social",
        .blockOther: "disconnect-content",
        .blockFonts: "web-fonts"
    ]

    private var ruleStore: WKContentRuleListStore!
    private weak var tab: Tab?

    private func loadJsonFromBundle(forResource file: String, completion: @escaping (_ jsonString: String) -> Void) {
        DispatchQueue.global().async {
            guard let path = Bundle.main.path(forResource: file, ofType: "json"),
                let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String else {
                    return
            }
            DispatchQueue.main.async {
                completion(source)
            }
        }
    }

    class func name() -> String {
        return "ContentBlockerHelper"
    }

    private func lastModifiedSince1970(path: String) -> TimeInterval? {
        do {
            let url = URL(fileURLWithPath: path)
            let attr = try FileManager.default.attributesOfItem(atPath: url.path)
            let date = attr[FileAttributeKey.modificationDate] as? Date
            return date?.timeIntervalSince1970
        } catch {
            return nil
        }
    }

    private func dateOfMostRecentBlockerFile() -> TimeInterval {
        return blocklists.reduce(TimeInterval(0)) { result, blockitem in
            guard let path = Bundle.main.path(forResource: blockitem.value, ofType: "json") else { return result }
            let date = lastModifiedSince1970(path: path) ?? 0
            return date > result ? date : result
        }
    }

    private func removeAllStoredRules(completion: @escaping () -> Void) {
        ruleStore.getAvailableContentRuleListIdentifiers { available in
            let dispatchGroup = DispatchGroup()
            dispatchGroup.notify(queue: .main) {
                completion()
            }

            available?.forEach {
                dispatchGroup.enter()
                self.ruleStore.removeContentRuleList(forIdentifier: $0) { err in
                    dispatchGroup.leave()
                }
            }
        }
    }

    // If any blocker files are newer than the date saved in prefs,
    // remove all the content blockers and reload them.
    private func removeStaleRules(completion: @escaping () -> Void) {
        struct RunOnce { static var ran = false }
        if RunOnce.ran {
            completion()
            return
        }
        RunOnce.ran = true

        var noMatchingIdentifierFoundForRule = false

        ruleStore.getAvailableContentRuleListIdentifiers { available in
            let available = available ?? [String]()
            for id in available {
                if !self.blocklists.contains(where: { $0.value == id }) {
                    noMatchingIdentifierFoundForRule = true
                    break
                }
            }

            let fileDate = self.dateOfMostRecentBlockerFile()
            let prefsNewestDate = UserDefaults.standard.double(forKey: "blocker-file-date")
            if fileDate <= prefsNewestDate && !noMatchingIdentifierFoundForRule {
                completion()
                return
            }
            UserDefaults.standard.set(fileDate, forKey: "blocker-file-date")

            self.removeAllStoredRules() {
                completion()
            }
        }
    }

    private func addToConfig(contentRuleList: WKContentRuleList?, error: Error?) {
        if let rules = contentRuleList {
            tab?.webView?.configuration.userContentController.add(rules)
        } else {
            print("Content blocker load error: " + (error?.localizedDescription ?? "empty rules"))
            assert(false)
        }
    }

    func removeAllFromTab() {
        tab?.webView?.configuration.userContentController.removeAllContentRuleLists()
    }

    func reinstallToTab() {
        for (_, filename) in self.blocklists {
            ruleStore.lookUpContentRuleList(forIdentifier: filename, completionHandler: addToConfig)
        }
    }

    init(tab: Tab) {
        if let ruleStore = WKContentRuleListStore.default() {
            self.ruleStore = ruleStore
        } else {
            print("WKContentRuleListStore unavailable.")
            assert(false)
            return
        }
        self.tab = tab

        removeStaleRules() {
            for (_, filename) in self.blocklists {
                self.ruleStore.lookUpContentRuleList(forIdentifier: filename) { contentRuleList, error in
                    if contentRuleList != nil {
                        self.addToConfig(contentRuleList: contentRuleList, error: error)
                        return
                    }

                    self.loadJsonFromBundle(forResource: filename) { jsonString in
                        self.ruleStore.compileContentRuleList(forIdentifier: filename, encodedContentRuleList: jsonString, completionHandler: self.addToConfig)
                    }
                }
            }
        }
    }
}

