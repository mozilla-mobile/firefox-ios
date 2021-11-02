//
//  ReaderModeStyleTests.swift
//  ClientTests
//
//  Created by Laurie Marceau on 2021-11-02.
//  Copyright © 2021 Mozilla. All rights reserved.
//

import XCTest
@testable import Client

class ReaderModeStyleTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        ThemeManager.instance.current = NormalTheme()
    }

    func test_initWithProperties_succeeds() {
        let readerModeStyle = ReaderModeStyle(theme: .dark,
                                              fontType: .sansSerif,
                                              fontSize: .size1)

        XCTAssertEqual(readerModeStyle.theme, ReaderModeTheme.dark)
        XCTAssertEqual(readerModeStyle.fontType, ReaderModeFontType.sansSerif)
        XCTAssertEqual(readerModeStyle.fontSize, ReaderModeFontSize.size1)
    }

    func test_encodingAsDictionary_succeeds() {
        let readerModeStyle = ReaderModeStyle(theme: .dark,
                                              fontType: .sansSerif,
                                              fontSize: .size1)

        let encodingResult: [String: Any] = readerModeStyle.encodeAsDictionary()
        let themeResult = encodingResult["theme"] as? String
        let fontTypeResult = encodingResult["fontType"] as? String
        let fontSizeResult = encodingResult["fontSize"] as? Int
        XCTAssertEqual(themeResult, ReaderModeTheme.dark.rawValue, "Encoding as dictionary theme result doesn't reflect style")
        XCTAssertEqual(fontTypeResult, ReaderModeFontType.sansSerif.rawValue, "Encoding as dictionary fontType result doesn't reflect style")
        XCTAssertEqual(fontSizeResult, ReaderModeFontSize.size1.rawValue, "Encoding as dictionary fontSize result doesn't reflect style")
    }

    func test_initWithDictionnary_succeeds() {
        let readerModeStyle = ReaderModeStyle(dict: ["theme": ReaderModeTheme.dark.rawValue,
                                                     "fontType": ReaderModeFontType.sansSerif.rawValue,
                                                     "fontSize": ReaderModeFontSize.size1.rawValue])

        XCTAssertEqual(readerModeStyle?.theme, ReaderModeTheme.dark)
        XCTAssertEqual(readerModeStyle?.fontType, ReaderModeFontType.sansSerif)
        XCTAssertEqual(readerModeStyle?.fontSize, ReaderModeFontSize.size1)
    }

    func test_initWithWrongDictionnary_fails() {
        let readerModeStyle = ReaderModeStyle(dict: ["wrong": 1,
                                                     "fontType": ReaderModeFontType.sansSerif,
                                                     "fontSize": ReaderModeFontSize.size1])

        XCTAssertNil(readerModeStyle)
    }

    func test_initWithEmptyDictionnary_fails() {
        let readerModeStyle = ReaderModeStyle(dict: [:])

        XCTAssertNil(readerModeStyle)
    }

    // MARK: - ReaderModeTheme

    func test_defaultReaderModeTheme() {
        let defaultTheme = ReaderModeTheme.preferredTheme(for: nil)
        XCTAssertEqual(defaultTheme, .light)
    }

    func test_appWideThemeDark_returnsDark() {
        ThemeManager.instance.current = DarkTheme()
        let theme = ReaderModeTheme.preferredTheme(for: ReaderModeTheme.light)

        XCTAssertEqual(theme, .dark)
    }

    func test_readerThemeSepia_returnsSepia() {
        let theme = ReaderModeTheme.preferredTheme(for: ReaderModeTheme.sepia)
        XCTAssertEqual(theme, .sepia)
    }

    func test_preferredColorTheme_changesFromLightToDark() {
        ThemeManager.instance.current = DarkTheme()

        var readerModeStyle = ReaderModeStyle(theme: .light,
                                              fontType: .sansSerif,
                                              fontSize: .size1)
        XCTAssertEqual(readerModeStyle.theme, .light)
        readerModeStyle.ensurePreferredColorThemeIfNeeded()
        XCTAssertEqual(readerModeStyle.theme, .dark)
    }
}
