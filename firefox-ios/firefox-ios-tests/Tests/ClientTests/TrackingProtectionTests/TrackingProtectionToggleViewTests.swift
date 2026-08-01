// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class TrackingProtectionToggleViewTests: XCTestCase {
    private typealias A11y = AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen

    /// Widths of the tracking protection panel, not of the device. The panel is 480pt wide as a popover and
    /// narrower whenever it is shown in an iPad split view.
    private struct PanelWidth {
        static let splitViewThird: CGFloat = 320
        static let splitViewHalf: CGFloat = 375
        static let popover: CGFloat = 480
        static let wide: CGFloat = 700
    }

    func test_toggleRow_atSplitViewThirdWidth_staysWithinBounds() {
        assertToggleRowStaysWithinBounds(panelWidth: PanelWidth.splitViewThird)
    }

    func test_toggleRow_atSplitViewHalfWidth_staysWithinBounds() {
        assertToggleRowStaysWithinBounds(panelWidth: PanelWidth.splitViewHalf)
    }

    func test_toggleRow_atPopoverWidth_staysWithinBounds() {
        assertToggleRowStaysWithinBounds(panelWidth: PanelWidth.popover)
    }

    func test_toggleRow_atWideWidth_staysWithinBounds() {
        assertToggleRowStaysWithinBounds(panelWidth: PanelWidth.wide)
    }

    // MARK: - Helpers

    private func assertToggleRowStaysWithinBounds(
        panelWidth: CGFloat,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let subject = createSubject()
        // Installs the real localized strings. Without them the labels have no intrinsic width, so there is
        // nothing competing with the switch for horizontal space and the assertions below pass vacuously.
        subject.setupDetails(isOn: true)
        subject.setupAccessibilityIdentifiers(
            toggleViewLabelsContainerA11yId: A11y.toggleViewLabelsContainer,
            toggleLabelA11yId: A11y.toggleLabel,
            toggleSwitchA11yId: A11y.toggleSwitch,
            toggleStatusLabelA11yId: A11y.toggleStatusLabel
        )
        layout(subject, inPanelOfWidth: panelWidth)

        guard let toggleSwitch = firstView(withA11yId: A11y.toggleSwitch, in: subject) else {
            XCTFail("Expected to find the toggle switch", file: file, line: line)
            return
        }

        // The switch must keep its natural size. It draws its track at that size regardless of how far its
        // frame is squeezed, so a compressed switch is what renders outside the row.
        // Compared with `>=` rather than `==` because a `UISwitch`'s frame is a couple of points wider than
        // its intrinsic content size.
        XCTAssertGreaterThanOrEqual(
            toggleSwitch.frame.width,
            toggleSwitch.intrinsicContentSize.width,
            "Switch was compressed below its intrinsic width at panel width \(panelWidth)",
            file: file,
            line: line
        )

        // Guards the other way the layout can fail: the switch keeping its size but being pushed past the
        // trailing edge. Measured against the row's edge rather than the 16pt margin, because Auto Layout
        // satisfies that margin in alignment-rect space and a `UISwitch`'s frame sits ~2pt outside it.
        XCTAssertLessThanOrEqual(
            toggleSwitch.frame.maxX,
            subject.bounds.maxX,
            "Switch is outside the toggle view at panel width \(panelWidth)",
            file: file,
            line: line
        )

        for labelA11yId in [A11y.toggleLabel, A11y.toggleStatusLabel] {
            guard let label = firstView(withA11yId: labelA11yId, in: subject) else {
                XCTFail("Expected to find \(labelA11yId)", file: file, line: line)
                return
            }
            let labelFrame = subject.convert(label.bounds, from: label)
            XCTAssertLessThanOrEqual(
                labelFrame.maxX,
                toggleSwitch.frame.minX + 0.5,
                "\(labelA11yId) overlaps the switch at panel width \(panelWidth)",
                file: file,
                line: line
            )
        }
    }

    /// Pins the subject into a host view the same way `TrackingProtectionViewController` does, so `panelWidth`
    /// means the width of the panel rather than of the toggle view itself.
    private func layout(_ subject: TrackingProtectionToggleView, inPanelOfWidth panelWidth: CGFloat) {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: panelWidth, height: 1000))
        host.addSubview(subject)
        NSLayoutConstraint.activate([
            subject.leadingAnchor.constraint(
                equalTo: host.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            subject.trailingAnchor.constraint(
                equalTo: host.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            subject.topAnchor.constraint(equalTo: host.topAnchor)
        ])
        subject.adjustLayout()
        host.layoutIfNeeded()
    }

    private func firstView(withA11yId a11yId: String, in view: UIView) -> UIView? {
        return allSubviews(in: view).first { $0.accessibilityIdentifier == a11yId }
    }

    private func allSubviews(in view: UIView) -> [UIView] {
        return view.subviews + view.subviews.flatMap { allSubviews(in: $0) }
    }

    private func createSubject() -> TrackingProtectionToggleView {
        let subject = TrackingProtectionToggleView()
        trackForMemoryLeaks(subject)
        return subject
    }
}
