// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest
@testable import ContentBlockerGenerator

final class ContentBlockerGeneratorTests: XCTestCase {

    private var fileManager: MockContentBlockerFileManager!
    private var parserData: ParserData!

    override func setUp() {
        super.setUp()
        self.fileManager = MockContentBlockerFileManager()
        self.parserData = ParserData()
    }

    override func tearDown() {
        super.tearDown()
        self.fileManager = nil
        self.parserData = nil
    }

    func testGenerator_whenEmptyFiles_generateNothing() {
        let subject = ContentBlockerGenerator(fileManager: fileManager)
        subject.generateLists()

        XCTAssertEqual(fileManager.capturedFileContent, [])
        XCTAssertEqual(fileManager.capturedCategoryTitle, [])
        XCTAssertEqual(fileManager.capturedActionType, [])
    }

    func testGenerator_whenAdsList_generateProperAdsFile() {
        let subject = ContentBlockerGenerator(fileManager: fileManager)
        let entityJson = parserData.getDictData(from: .entity)
        let adsList = parserData.getListData(from: .ads)
        fileManager.entityList = entityJson
        fileManager.categoryFile[FileCategory.advertising] = adsList

        subject.generateLists()

        XCTAssertEqual(fileManager.capturedFileContent.count, 2, "Generated 'block' and 'block cookies' ads list")
        XCTAssertEqual(fileManager.capturedCategoryTitle.count, 2)
        XCTAssertEqual(fileManager.capturedCategoryTitle[0], .advertising)
        XCTAssertEqual(fileManager.capturedCategoryTitle[1], .advertising)
        XCTAssertEqual(fileManager.capturedActionType.count, 2)
        XCTAssertEqual(fileManager.capturedActionType[0], .blockAll)
        XCTAssertEqual(fileManager.capturedActionType[1], .blockCookies)
    }
}

// MARK: - MockContentBlockerFileManager
class MockContentBlockerFileManager: ContentBlockerFileManager {

    var entityList = [String : Any]()
    func getEntityList() -> [String : Any] {
        return entityList
    }

    var categoryFile = [FileCategory: [String]]()
    func getCategoryFile(categoryTitle: FileCategory) -> [String] {
        return categoryFile[categoryTitle] ?? []
    }

    var capturedFileContent = [String]()
    var capturedCategoryTitle = [FileCategory]()
    var capturedActionType = [ActionType]()

    func write(fileContent: String,
               categoryTitle: FileCategory,
               actionType: ActionType) {
        capturedFileContent.append(fileContent)
        capturedCategoryTitle.append(categoryTitle)
        capturedActionType.append(actionType)
    }
}
