/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import JavaScriptCore
import Shared
import Storage
import XCGLogger

private let log = Logger.browserLogger

class DocumentServicesHelper: TabEventHandler {
    private var tabObservers: TabObservers!

    private lazy var singleThreadedQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Document Services JSContext queue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    private lazy var context: JSContext = {
        let virtualMachine = JSVirtualMachine()
        let context: JSContext = JSContext(virtualMachine: virtualMachine)

        context.exceptionHandler = { context, exception in
            if let exception = exception {
                log.error("DocumentServices.js: \(exception)")
            }
        }

        let name = "DocumentServices"
        guard let path = Bundle.main.path(forResource: name, ofType: "js"),
            let jsFile = try? String(contentsOfFile: path, encoding: .utf8) else {
            log.error("DocumentServices are unavailable due to missing or corrupt JS file")
            return context
        }

        context.evaluateScript("var __firefox__;")
        context.evaluateScript(jsFile)

        return context
    }()

    private lazy var documentServices: JSValue? = {
        guard let firefox = context.objectForKeyedSubscript("__firefox__"),
            let isConfigured = firefox.objectForKeyedSubscript("isConfigured"),
            isConfigured.isBoolean && isConfigured.toBool() else {
                log.error("Unable to do anything without a firefox object.")
                return nil
        }
        return firefox
    }()

    init() {
        self.tabObservers = registerFor(
            .didLoadPageMetadata,
            queue: singleThreadedQueue)
    }

    deinit {
        unregister(tabObservers)
    }

    func tab(_ tab: Tab, didLoadPageMetadata metadata: PageMetadata) {
        let analyze = documentServices?.objectForKeyedSubscript("analyze")
        guard let jsValue = analyze?.call(withArguments: [metadata.toDictionary() as NSDictionary]), jsValue.isObject else {
            log.error("There was some problem in DocumentServices.js, see the log above")
            return
        }

        guard let dict = jsValue.toDictionary() as? [String: Any],
            !dict.isEmpty else {
            log.debug("Nothing interesting came back from DocumentServices. Exiting.")
            return
        }

        let derived = DerivedMetadata.fromDictionary(dict)

        // XXX we came from the main thread (.PageMedataParser) and we're posting
        // to the main thread for most of our use cases.
        // NotificationCenter is deadlocked when we do that directly, so
        // post to NotificationCenter indirectly.
        DispatchQueue.global().async {
            TabEvent.post(.didDeriveMetadata(derived), for: tab)
        }
    }
}

struct DerivedMetadata {
    let language: String?

    static func fromDictionary(_ d: [String: Any]) -> DerivedMetadata {
        let language: String?
        if let lang = d["language"] as? [String: String],
            let identifier = lang["iso639_1"] ?? lang["iso639_2T"] {
            language = Locale.canonicalLanguageIdentifier(from: identifier)
        } else {
            language = nil
        }

        return DerivedMetadata(language: language)
    }
}
