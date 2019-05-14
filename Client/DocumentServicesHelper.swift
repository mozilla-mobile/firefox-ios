/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Storage
import NaturalLanguage

protocol DocumentAnalyser {
    var name: String { get }
    associatedtype NewMetadata
    func analyse(metadata: PageMetadata) -> NewMetadata?
}

struct LanguageDetector: DocumentAnalyser {
    let name = "language" //This key matches the DerivedMetadata property
    typealias NewMetadata = String //This matches the value for the DerivedMetadata key above

    func analyse(metadata: PageMetadata) -> LanguageDetector.NewMetadata? {
        if let metadataLanguage = metadata.language {
            return metadataLanguage
        }
        // Lets not use any language detection until we can pass more text to the language detector
        return nil // https://bugzilla.mozilla.org/show_bug.cgi?id=1519503
        /*
        guard let text = metadata.description else { return nil }
        let language: String?
        if #available(iOS 12.0, *) {
            language = NLLanguageRecognizer.dominantLanguage(for: text)?.rawValue
        } else {
            language = NSLinguisticTagger.dominantLanguage(for: text)
        }
        return language
        */
    }
}

struct DerivedMetadata: Codable {
    let language: String?

    // New keys need to be mapped in this constructor
    static func from(dict: [String: Any?]) -> DerivedMetadata? {
        return DerivedMetadata(language: dict["language"] as? String)
    }
}

class DocumentServicesHelper: TabEventHandler {
    private lazy var singleThreadedQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Document Services queue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    init() {
        register(self, forTabEvents: .didLoadPageMetadata)
    }

    func tab(_ tab: Tab, didLoadPageMetadata metadata: PageMetadata) {
        singleThreadedQueue.addOperation {
            // New analyzers go here. We map through each one and reduce into one dictionary
            let analyzers = [LanguageDetector()]
            let dict = analyzers.map({ [$0.name: $0.analyse(metadata: metadata)] }).compactMap({$0}).reduce([:]) { $0.merging($1) { (current, _) in current } }

            guard let derivedMetadata = DerivedMetadata.from(dict: dict) else { return }
            DispatchQueue.main.async {
                TabEvent.post(.didDeriveMetadata(derivedMetadata), for: tab)
            }
        }
    }
}
