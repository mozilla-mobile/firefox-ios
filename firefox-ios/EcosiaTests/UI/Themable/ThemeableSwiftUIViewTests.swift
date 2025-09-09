// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import SwiftUI
import Common
@testable import Ecosia

final class ThemeableSwiftUIViewTests: XCTestCase {

    // MARK: - Unit Tests

    func testThemeUpdatesCorrectly() {
        // Given
        let mockThemeManager = ThemeableMockThemeManager()
        mockThemeManager.currentTheme = LightTheme()

        // When
        var testTheme = TestTheme()
        testTheme.applyTheme(theme: mockThemeManager.getCurrentTheme(for: .XCTestDefaultUUID))

        // Then
        XCTAssertEqual(testTheme.backgroundColor, Color.white)
        XCTAssertEqual(testTheme.textColor, Color.black)

        // When theme changes
        mockThemeManager.currentTheme = DarkTheme()
        testTheme.applyTheme(theme: mockThemeManager.getCurrentTheme(for: .XCTestDefaultUUID))

        // Then
        XCTAssertEqual(testTheme.backgroundColor, Color.black)
        XCTAssertEqual(testTheme.textColor, Color.white)
    }

    func testNilWindowUUID() {
        // Given
        var testTheme = TestTheme()
        let windowUUID: WindowUUID? = nil
        let themeBinding = Binding<TestTheme>(
            get: { testTheme },
            set: { testTheme = $0 }
        )

        // When/Then
        let view = Text("Test").ecosiaThemed(windowUUID, themeBinding)
        let viewMirror = Mirror(reflecting: view)
        XCTAssertTrue(viewMirror.description.contains("ThemeModifier"))
    }

    // MARK: - Integration Tests

    @available(iOS 16.0, *)
    func testThemeModifierWithMockView() {
        // Given
        let initialTheme = TestTheme()
        let mockView = MockView(theme: initialTheme, windowUUID: .XCTestDefaultUUID)

        // When/Then
        let mirror = Mirror(reflecting: mockView.body)
        XCTAssertTrue(mirror.description.contains("ThemeModifier"))
    }
}

extension ThemeableSwiftUIViewTests {

    struct TestTheme: EcosiaThemeable {
        var backgroundColor = Color.white
        var textColor = Color.black
        var themeApplied = false

        mutating func applyTheme(theme: Theme) {
            backgroundColor = theme.type == .dark ? Color.black : Color.white
            textColor = theme.type == .dark ? Color.white : Color.black
            themeApplied = true
        }
    }

    @available(iOS 16.0, *)
    struct MockView: View {
        // Using StateObject instead of State to avoid "Accessing State's value outside of being installed on a View" warning
        @StateObject private var themeContainer = ThemeContainer()
        let initialTheme: TestTheme
        let windowUUID: WindowUUID

        init(theme: TestTheme, windowUUID: WindowUUID) {
            self.initialTheme = theme
            self.windowUUID = windowUUID
            self.themeContainer.theme = theme
        }

        var body: some View {
            Text("Test")
                .foregroundColor(themeContainer.theme.textColor)
                .background(themeContainer.theme.backgroundColor)
                .ecosiaThemed(windowUUID, $themeContainer.theme)
        }
    }

    // Helper class to hold our theme in an ObservableObject
    class ThemeContainer: ObservableObject {
        @Published var theme = TestTheme()
    }

    class TestNotificationCenter: NotificationCenter, @unchecked Sendable {
        var postedNotifications: [Notification.Name] = []

        override func post(name: Notification.Name, object: Any?, userInfo: [AnyHashable: Any]? = nil) {
            postedNotifications.append(name)
            super.post(name: name, object: object, userInfo: userInfo)
        }
    }
}
