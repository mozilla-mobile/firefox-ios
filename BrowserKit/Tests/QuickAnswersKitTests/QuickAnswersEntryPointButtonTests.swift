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
    func test_configure_whenNotGlowing_doesNotGlow() {
        let subject = createSubject()

        let didStartGlow = subject.configure(theme: theme, glowing: false)

        #expect(didStartGlow == false)
        #expect(subject.isGlowing == false)
    }

    @Test
    func test_configure_whenGlowingTrue_startsGlowing() {
        let subject = createSubject()

        let didStartGlow = subject.configure(theme: theme, glowing: true)

        #expect(didStartGlow == true)
        #expect(subject.isGlowing == true)
    }

    @Test
    func test_configure_calledTwice_startsTheGlowOnlyOnce() {
        let subject = createSubject()
        subject.configure(theme: theme, glowing: true)

        let didStartGlow = subject.configure(theme: theme, glowing: true)

        #expect(didStartGlow == false)
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
