// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct ContentBlockerGenerator {
    public static func factory() -> ContentBlockerGenerator {
        return ContentBlockerGenerator()
    }

    private let fileManager: ContentBlockerFileManager
    private let parser: ContentBlockerParser

    init(fileManager: ContentBlockerFileManager = DefaultContentBlockerFileManager(),
         parser: ContentBlockerParser = DefaultContentBlockerParser()) {
        self.fileManager = fileManager
        self.parser = parser

        let entityList = fileManager.getEntityList()
        parser.parseEntityList(entityList)
    }

    public func generateLists() {
        // Block lists
        generate(actionType: .blockAll,
                 categories: [.advertising, .analytics, .social, .cryptomining, .fingerprinting, .content])

        // Block cookies lists
        generate(actionType: .blockCookies,
                 categories: [.advertising, .analytics, .social, .content])
    }

    // MARK: - Private

    private func generate(actionType: ActionType,
                          categories: [FileCategory]) {
        for categoryTitle in categories {
            let fileContent = generateFileContent(actionType: actionType, categoryTitle: categoryTitle)
            guard !fileContent.isEmpty else {
                return
            }

            fileManager.write(fileContent: fileContent, categoryTitle: categoryTitle, actionType: actionType)
        }
    }

    private func generateFileContent(actionType: ActionType,
                                     categoryTitle: FileCategory) -> String {
        let categoryList = fileManager.getCategoryFile(categoryTitle: categoryTitle)
        let fileLines = parser.parseCategoryList(categoryList,
                                                 actionType: actionType)

        return fileLines.isEmpty ? "" : "[\n" + fileLines.joined(separator: ",\n") + "\n]"
    }
}
