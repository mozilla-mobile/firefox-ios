// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
import Common
@testable import Client

class ReaderModeStyleTests: XCTestCase {
    var themeManager: ThemeManager!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        themeManager = AppContainer.shared.resolve()
    }

    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
        themeManager = nil
    }

    func test_initWithProperties_succeeds() {
        let readerModeStyle = ReaderModeStyle(windowUUID: windowUUID,
                                              theme: .dark,
                                              fontType: .sansSerif,
                                              fontSize: .size1)

        XCTAssertEqual(readerModeStyle.theme, ReaderModeTheme.dark)
        XCTAssertEqual(readerModeStyle.fontType, ReaderModeFontType.sansSerif)
        XCTAssertEqual(readerModeStyle.fontSize, ReaderModeFontSize.size1)
    }

    func test_encodingAsDictionary_succeeds() {
        let readerModeStyle = ReaderModeStyle(windowUUID: windowUUID,
                                              theme: .dark,
                                              fontType: .sansSerif,
                                              fontSize: .size1)

        let encodingResult: [String: Any] = readerModeStyle.encodeAsDictionary()
        let themeResult = encodingResult["theme"] as? String
        let fontTypeResult = encodingResult["fontType"] as? String
        let fontSizeResult = encodingResult["fontSize"] as? Int
        XCTAssertEqual(
            themeResult,
            ReaderModeTheme.dark.rawValue,
            "Encoding as dictionary theme result doesn't reflect style"
        )
        XCTAssertEqual(
            fontTypeResult,
            ReaderModeFontType.sansSerif.rawValue,
            "Encoding as dictionary fontType result doesn't reflect style"
        )
        XCTAssertEqual(
            fontSizeResult,
            ReaderModeFontSize.size1.rawValue,
            "Encoding as dictionary fontSize result doesn't reflect style"
        )
    }

    func test_initWithDictionary_succeeds() {
        let readerModeStyle = ReaderModeStyle(windowUUID: windowUUID,
                                              dict: ["theme": ReaderModeTheme.dark.rawValue,
                                                     "fontType": ReaderModeFontType.sansSerif.rawValue,
                                                     "fontSize": ReaderModeFontSize.size1.rawValue])

        XCTAssertEqual(readerModeStyle?.theme, ReaderModeTheme.dark)
        XCTAssertEqual(readerModeStyle?.fontType, ReaderModeFontType.sansSerif)
        XCTAssertEqual(readerModeStyle?.fontSize, ReaderModeFontSize.size1)
    }

    func test_initWithWrongDictionary_fails() {
        let readerModeStyle = ReaderModeStyle(windowUUID: windowUUID,
                                              dict: ["wrong": 1,
                                                     "fontType": ReaderModeFontType.sansSerif,
                                                     "fontSize": ReaderModeFontSize.size1])

        XCTAssertNil(readerModeStyle)
    }

    func test_initWithEmptyDictionary_fails() {
        let readerModeStyle = ReaderModeStyle(windowUUID: windowUUID,
                                              dict: [:])

        XCTAssertNil(readerModeStyle)
    }

    // MARK: - ReaderModeTheme

    func test_defaultReaderModeTheme_returnsLight() {
        themeManager.setManualTheme(to: .light)
        let defaultTheme = ReaderModeTheme.preferredTheme(for: nil, window: windowUUID)
        XCTAssertEqual(defaultTheme, .light, "Expected light theme (default) if not theme is selected")
    }

    func test_appWideThemeDark_returnsDark() {
        themeManager.setManualTheme(to: .dark)
        let theme = ReaderModeTheme.preferredTheme(for: ReaderModeTheme.light, window: windowUUID)

        XCTAssertEqual(theme, .dark, "Expected dark theme because of the app theme")
    }

    func test_readerThemeSepia_returnsSepia() {
        themeManager.setManualTheme(to: .light)
        let theme = ReaderModeTheme.preferredTheme(for: ReaderModeTheme.sepia, window: windowUUID)
        XCTAssertEqual(theme, .sepia, "Expected sepia theme if App theme is not dark")
    }

    func test_readerThemeSepiaWithAppDark_returnsSepia() {
        themeManager.setManualTheme(to: .dark)
        let theme = ReaderModeTheme.preferredTheme(for: ReaderModeTheme.sepia, window: windowUUID)
        XCTAssertEqual(theme, .dark, "Expected dark theme if App theme is dark")
    }

    func test_preferredColorTheme_changesFromLightToDark() {
        themeManager.setManualTheme(to: .dark)
        var readerModeStyle = ReaderModeStyle(windowUUID: windowUUID,
                                              theme: .light,
                                              fontType: .sansSerif,
                                              fontSize: .size1)
        XCTAssertEqual(readerModeStyle.theme, .light)
        readerModeStyle.ensurePreferredColorThemeIfNeeded()
        XCTAssertEqual(readerModeStyle.theme, .dark)
    }

    func test_delegateMemoryLeak() {
        let mockReaderModeStyleViewControllerDelegate = MockDelegate()
        let readerModeStyleViewModel = ReaderModeStyleViewModel(windowUUID: windowUUID, isBottomPresented: false)
        readerModeStyleViewModel.delegate = mockReaderModeStyleViewControllerDelegate
        trackForMemoryLeaks(readerModeStyleViewModel)
    }

    // MARK: - Tests

    func testSelectTheme() {
        let viewModel = ReaderModeStyleViewModel(windowUUID: windowUUID, isBottomPresented: true)

        let theme = ReaderModeTheme.dark
        viewModel.selectTheme(theme)

        XCTAssertEqual(viewModel.readerModeStyle.theme, theme)
    }

    func testSelectFontType() {
        let viewModel = ReaderModeStyleViewModel(windowUUID: windowUUID, isBottomPresented: true)

        let fontType = ReaderModeFontType.sansSerif
        viewModel.selectFontType(fontType)

        XCTAssertEqual(viewModel.readerModeStyle.fontType, fontType)
    }

    func testReaderModeDidChangeTheme() {
        let viewModel = ReaderModeStyleViewModel(windowUUID: windowUUID, isBottomPresented: true)
        let mockDelegate = MockDelegate()
        viewModel.delegate = mockDelegate

        let theme = ReaderModeTheme.light
        viewModel.readerModeDidChangeTheme(theme)

        XCTAssertEqual(viewModel.readerModeStyle.theme, theme)
        XCTAssertTrue(viewModel.isUsingUserDefinedColor)
        XCTAssertTrue(mockDelegate.didCallConfigureStyle)
        XCTAssertEqual(mockDelegate.receivedStyle, viewModel.readerModeStyle)
        XCTAssertEqual(mockDelegate.receivedIsUsingUserDefinedColor, true)
    }

    func testFontSizeDidChangeSizeAction() {
        let viewModel = ReaderModeStyleViewModel(windowUUID: windowUUID, isBottomPresented: true)
        let mockDelegate = MockDelegate()
        viewModel.delegate = mockDelegate

        let originalFontSize = viewModel.readerModeStyle.fontSize

        viewModel.fontSizeDidChangeSizeAction(.smaller)
        XCTAssertTrue(viewModel.readerModeStyle.fontSize < originalFontSize)

        viewModel.fontSizeDidChangeSizeAction(.bigger)
        viewModel.fontSizeDidChangeSizeAction(.bigger)
        XCTAssertTrue(viewModel.readerModeStyle.fontSize > originalFontSize)

        viewModel.fontSizeDidChangeSizeAction(.reset)
        XCTAssertEqual(viewModel.readerModeStyle.fontSize, ReaderModeFontSize.defaultSize)

        XCTAssertTrue(mockDelegate.didCallConfigureStyle)
        XCTAssertEqual(mockDelegate.receivedStyle, viewModel.readerModeStyle)
        XCTAssertEqual(mockDelegate.receivedIsUsingUserDefinedColor, viewModel.isUsingUserDefinedColor)
    }

    func testFontTypeDidChange() {
        let viewModel = ReaderModeStyleViewModel(windowUUID: windowUUID, isBottomPresented: true)
        let mockDelegate = MockDelegate()
        viewModel.delegate = mockDelegate

        let fontType = ReaderModeFontType.serif
        viewModel.fontTypeDidChange(fontType)

        XCTAssertEqual(viewModel.readerModeStyle.fontType, fontType)
        XCTAssertTrue(mockDelegate.didCallConfigureStyle)
        XCTAssertEqual(mockDelegate.receivedStyle, viewModel.readerModeStyle)
        XCTAssertEqual(mockDelegate.receivedIsUsingUserDefinedColor, viewModel.isUsingUserDefinedColor)
    }
}

// MARK: - Mocks

class MockDelegate: ReaderModeStyleViewModelDelegate {
    var didCallConfigureStyle = false
    var receivedStyle: ReaderModeStyle?
    var receivedIsUsingUserDefinedColor: Bool?

    func readerModeStyleViewModel(_ readerModeStyleViewModel: ReaderModeStyleViewModel,
                                  didConfigureStyle style: ReaderModeStyle,
                                  isUsingUserDefinedColor: Bool) {
        didCallConfigureStyle = true
        receivedStyle = style
        receivedIsUsingUserDefinedColor = isUsingUserDefinedColor
    }
}

extension ReaderModeFontSize: @retroactive Comparable {
    public static func < (lhs: ReaderModeFontSize, rhs: ReaderModeFontSize) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension ReaderModeStyle: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.fontSize == rhs.fontSize && lhs.fontType == rhs.fontType && lhs.theme == rhs.theme
    }
}
