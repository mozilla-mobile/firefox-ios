// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class LibraryScreen {
    private let app: XCUIApplication
    private let sel: LibrarySelectorsSet

    init(app: XCUIApplication, selectors: LibrarySelectorsSet = LibrarySelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var editButton: XCUIElement { sel.EDIT_BUTTON.element(in: app) }
    private var doneButton: XCUIElement { sel.DONE_BUTTON.element(in: app) }
    private var bottmLeftButton: XCUIElement { sel.BOTTOM_LEFT_BUTTON.element(in: app) }
    private var titleTextField: XCUIElement { sel.TITLE_TEXT_FIELD.element(in: app) }
    private var saveButton: XCUIElement { sel.SAVE_BUTTON.element(in: app) }
    private var bookmarkFolderCell: XCUIElement { sel.BOOKMARKS_FOLDER.element(in: app) }
    private var deleteButton: XCUIElement { sel.DELETE_BUTTON.element(in: app) }
    private var backButton: XCUIElement { sel.BACK_BUTTON.element(in: app) }
    private var backButtoniOS18: XCUIElement { sel.BACK_BUTTON_iOS18.element(in: app) }
    private var generalBackButton: XCUIElement { sel.GENERAL_BACK_BUTTON.element(in: app) }

    func assertBookmarkExists(named name: String, timeout: TimeInterval = TIMEOUT_LONG) {
        let bookmarksTable = sel.BOOKMARKS_LIST.element(in: app)

        // Wait for the table and the specific bookmark to exist.
        BaseTestCase().waitForElementsToExist([
            bookmarksTable,
            bookmarksTable.staticTexts[name]
        ], timeout: timeout)
    }

    func assertBookmarkList() {
        let bookmarksTable = sel.BOOKMARKS_LIST.element(in: app)
        BaseTestCase().mozWaitForElementToExist(bookmarksTable)
    }

    func assertBookmarkListCount(numberOfEntries: Int) {
        let bookmarksTable = sel.BOOKMARKS_LIST.element(in: app)
        XCTAssertEqual(bookmarksTable.cells.count, numberOfEntries)
    }

    func swipeBookmarkEntry(entryName: String) {
        let bookmarksTable = sel.BOOKMARKS_LIST.element(in: app)
        bookmarksTable.cells.staticTexts[entryName].swipeLeft()
    }

    func tapDeleteBookmarkButton() {
        deleteButton.waitAndTap()
    }

    func swipeAndDeleteBookmark(entryName: String) {
        swipeBookmarkEntry(entryName: entryName)
        tapDeleteBookmarkButton()
    }

    func assertEmptyStateSignInButtonExists() {
        BaseTestCase().mozWaitForElementToExist(sel.SIGN_IN_BUTTON.element(in: app))
    }

    func assertBookmarkListLabel(label: String) {
        let bookmarksTable = sel.BOOKMARKS_LIST.element(in: app)
        XCTAssertEqual(bookmarksTable.label, "Empty list")
    }

    func assertBookmarkEmptyStateTextExists(shouldExist: Bool = true) {
        if shouldExist {
            BaseTestCase().mozWaitForElementToExist(sel.BOOKMARK_EMPTY_STATE.element(in: app))
        } else {
            BaseTestCase().mozWaitForElementToNotExist(sel.BOOKMARK_EMPTY_STATE.element(in: app))
        }
    }

    func assertIdenticalFoldersNamesCreated(identifier: String, nrOfFolders: Int) {
        let elements = app.staticTexts.matching(identifier: identifier)
        XCTAssertEqual(elements.count, nrOfFolders, "Expected \(nrOfFolders) identical folder names")
    }

    func tapSaveButton() {
        saveButton.waitAndTap()
    }

    func tapEditButton() {
        editButton.firstMatch.waitAndTap()
    }

    func tapDoneButton() {
        doneButton.firstMatch.waitAndTap()
    }

    func tapBottomLeftButton() {
        bottmLeftButton.waitAndTap()
    }

    func assertEditButtonExists() {
        BaseTestCase().mozWaitForElementToExist(editButton)
    }

    func assertNewFolderButtonExists(shouldExists: Bool = true) {
        if shouldExists {
            BaseTestCase().mozWaitForElementToExist(bottmLeftButton)
        } else {
            BaseTestCase().mozWaitForElementToNotExist(bottmLeftButton)
        }
    }

    func addFreshNewFolder(text: String) {
        // This function adds a new first folder in the bookmark list
        tapEditButton()
        tapBottomLeftButton()
        titleTextField.typeText(text)
        // Folder structure contains only the "Bookmarks" folder
        BaseTestCase().mozWaitForElementToExist(bookmarkFolderCell)
        XCTAssertEqual(app.tables.cells.staticTexts.element(boundBy: 0).label,
                       "Bookmarks",
                       "The first folder should be the default Bookmarks folder")
        XCTAssertEqual(app.tables.cells.staticTexts.count, 1, "Folder structure should contain only the Bookmarks folder")
        tapSaveButton()
    }

    func addNewFolder(text: String) {
        titleTextField.typeText(text)
        tapSaveButton()
    }

    func assertNewFreshFolderCreated(folderName: String) {
        // The new folder is created, and the user is returned to the main Bookmarks view in Edit mode
        BaseTestCase().mozWaitForElementToExist(doneButton)
        BaseTestCase().mozWaitForElementToExist(bottmLeftButton)
        BaseTestCase().mozWaitForElementToExist(app.staticTexts[folderName])
    }

    func tapOnFolder(folderName: String) {
        app.staticTexts[folderName].waitAndTap()
    }

    func assertSavedFolder(folderName: String) {
        BaseTestCase().mozWaitForElementToExist(app.staticTexts[folderName])
    }

    func assertSelectedFolderOpens(folderName: String) {
        BaseTestCase().mozWaitForElementToExist(app.navigationBars[folderName])
    }

    func deleteFolder(folderName: String) {
        app.tables.cells.buttons["Remove \(folderName)"].waitAndTap()
        deleteButton.waitAndTap()
    }

    func assertNewFolderScreen() {
        BaseTestCase().mozWaitForElementToExist(app.navigationBars["New Folder"])
    }

    func assertParentFolder(parentFolderName: String) {
        BaseTestCase().mozWaitForElementToExist(bookmarkFolderCell)
        BaseTestCase().mozWaitForElementToExist(app.staticTexts[parentFolderName])
    }

    func tapBackButton(isInsideFolder: Bool = false) {
        if #available(iOS 26, *) {
            backButton.waitAndTap()
        } else {
            if !isInsideFolder {
                backButtoniOS18.firstMatch.waitAndTap()
            } else {
                generalBackButton.waitAndTap()
            }
        }
    }

    func longPressAndSelectContextMenuOption(option: String) {
        let tableContextMenu = app.tables["Context Menu"]
        app.tables.staticTexts.element(boundBy: 0).press(forDuration: 1)
        BaseTestCase().mozWaitForElementToExist(tableContextMenu)
        tableContextMenu.cells.buttons[option].waitAndTap()
    }
}
