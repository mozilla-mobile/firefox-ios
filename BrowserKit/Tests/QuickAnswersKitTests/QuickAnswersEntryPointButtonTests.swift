// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Testing
import UIKit

@testable import QuickAnswersKit

@MainActor
struct QuickAnswersEntryPointButtonTests {
    private let theme = LightTheme()

    @Test
    func test_init_doesNotGlow() {
        let subject = createSubject()

        #expect(subject.isGlowing == false)
    }

    @Test
    func test_startGlow_whenThemeApplied_startsGlowing() {
        let subject = createSubject()
        subject.applyTheme(theme: theme)

        subject.startGlow()

        #expect(subject.isGlowing == true)
    }

    @Test
    func test_startGlow_beforeThemeApplied_startsGlowingOnceThemeIsApplied() {
        let subject = createSubject()

        subject.startGlow()
        #expect(subject.isGlowing == false)

        subject.applyTheme(theme: theme)

        #expect(subject.isGlowing == true)
    }

    @Test
    func test_stopGlow_stopsGlowing() {
        let subject = createSubject()
        subject.applyTheme(theme: theme)
        subject.startGlow()

        subject.stopGlow()

        #expect(subject.isGlowing == false)
    }

    @Test
    func test_startGlow_afterGlowStopped_doesNotGlowAgain() {
        let subject = createSubject()
        subject.applyTheme(theme: theme)
        subject.startGlow()
        subject.stopGlow()

        subject.startGlow()

        #expect(subject.isGlowing == false)
    }

    @Test
    func test_glow_afterGlowDuration_stopsOnItsOwn() async throws {
        let subject = createSubject(glowDuration: 0.1)
        subject.applyTheme(theme: theme)

        subject.startGlow()
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(subject.isGlowing == false)
    }

    @Test
    func test_tap_callsOnTap() {
        var tapCount = 0
        let subject = createSubject(onTap: { tapCount += 1 })

        subject.sendActions(for: .touchUpInside)

        #expect(tapCount == 1)
    }

    // MARK: - Helper
    private func createSubject(
        glowDuration: TimeInterval = 5.0,
        onTap: @escaping () -> Void = {}
    ) -> QuickAnswersEntryPointButton {
        let subject = QuickAnswersEntryPointButton(glowDuration: glowDuration, onTap: onTap)
        subject.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        return subject
    }
}
