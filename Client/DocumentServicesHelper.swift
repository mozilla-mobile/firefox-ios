/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import JavaScriptCore
import Shared
import Storage
import NaturalLanguage

protocol DocumentAnalyser {
    var name: String { get }
    func analyse(metadata: PageMetadata) -> DerivedMetadata?
}

struct DerivedMetadata {
    let language: String?
}

struct LanguageDetector: DocumentAnalyser {
    let name = "NLTranslator"

    func analyse(metadata: PageMetadata) -> DerivedMetadata? {
        let text = [metadata.description, metadata.title].compactMap({$0}).joined(separator: " ")
        let language: String?
        if #available(iOS 12.0, *) {
            language = NLLanguageRecognizer.dominantLanguage(for: text)?.rawValue
        } else {
            language = NSLinguisticTagger.dominantLanguage(for: text)
        }
        return DerivedMetadata(language: language)
    }
}

class DocumentServicesHelper: TabEventHandler {
    private var tabObservers: TabObservers!

    private lazy var singleThreadedQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Document Services queue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
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
        guard let langaugeMetadata = LanguageDetector().analyse(metadata: metadata) else { return }
        DispatchQueue.global().async {
            TabEvent.post(.didDeriveMetadata(langaugeMetadata), for: tab)
        }
    }
}
