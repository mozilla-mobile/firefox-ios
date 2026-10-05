// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import UIKit
import XCTest

@testable import Client

final class TabGroupsTrayBarTests: XCTestCase {
    func testActiveTint_onlyUsesGroupTintWhenGroupSelected() {
        var model = makeViewModel()
        model.groupColor = .orange
        XCTAssertEqual(model.activeTint, model.colors.emphasis)

        let groupedModel = makeViewModel(isGroupSelected: true, groupColor: .orange)
        XCTAssertEqual(groupedModel.activeTint, .orange)
    }

    func testThemedColors_novaUsesTabGroupGlassTintAndDefaultGroupForeground() {
        let themes: [any Theme] = [NovaLightTheme(), NovaDarkTheme()]
        for theme in themes {
            let colors = TabGroupsTrayBarViewModel.Colors.themed(theme, isDefaultGroup: true)

            XCTAssertEqual(colors.glassTint, Color(theme.colors.layerTabGroupGlassTint))
            XCTAssertEqual(colors.onEmphasis, Color(theme.colors.iconPrimary))
            XCTAssertEqual(TabGroupsTrayBarViewModel.Colors.themed(theme).onEmphasis, Color(theme.colors.iconOnColor))
        }
    }

    func testThemedColors_classicUsesExistingLayerFallback() {
        let theme = LightTheme()

        let colors = TabGroupsTrayBarViewModel.Colors.themed(theme)

        XCTAssertEqual(colors.glassTint, Color(theme.colors.layer2))
        XCTAssertEqual(colors.onEmphasis, Color(theme.colors.iconOnColor))
    }

    @MainActor
    func testNativeToolbar_hostedGlassRowExposesButtonsInPanelOrder() throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Native glass toolbars require iOS 26.") }
        let toolbar = TabGroupsTrayNativeToolbar { _ in }
        toolbar.update(viewModel: makeViewModel(), usesGlassButtons: true)
        let row = try XCTUnwrap(toolbar.makeHostedItems().compactMap {
            $0.customView as? TabGroupsTrayNativeToolbar.GlassRow
        }.first)

        let buttons = try accessibleButtons(in: row)

        XCTAssertEqual(buttons.compactMap(\.accessibilityIdentifier), ["tabGroupsTray.addTab",
                                                                       "tabGroupsTray.panel.privateTabs",
                                                                       "tabGroupsTray.panel.tabs",
                                                                       "tabGroupsTray.panel.syncedTabs",
                                                                       "tabGroupsTray.done"])
        for button in buttons {
            XCTAssertTrue(button.isAccessibilityElement, button.accessibilityIdentifier ?? "Toolbar button")
        }
    }

    @MainActor
    func testNativeToolbar_fallbackHidesSharedBackgroundOnlyAroundPanelSelector() throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Shared toolbar backgrounds require iOS 26.") }
        let toolbar = TabGroupsTrayNativeToolbar { _ in }
        toolbar.update(viewModel: makeViewModel(), usesGlassButtons: false)
        let panel = try XCTUnwrap(toolbar.items.first { $0.customView === toolbar.panelSelector })
        let add = try XCTUnwrap(toolbar.items.first { $0.accessibilityIdentifier == "tabGroupsTray.addTab" })
        let done = try XCTUnwrap(toolbar.items.first { $0.accessibilityIdentifier == "tabGroupsTray.done" })

        XCTAssertTrue(panel.hidesSharedBackground)
        XCTAssertFalse(add.hidesSharedBackground)
        XCTAssertFalse(done.hidesSharedBackground)
    }

    @MainActor
    func testNativeToolbar_glassPanelUsesOneEffectAndRoutesSelectedPanelActions() throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Native glass toolbars require iOS 26.") }
        var receivedAction: TabGroupsTrayBarAction?
        let toolbar = TabGroupsTrayNativeToolbar { receivedAction = $0 }
        let model = makeViewModel()
        toolbar.update(viewModel: model, usesGlassButtons: true)
        let panel = try glassPanel(in: toolbar)
        let item = try XCTUnwrap(toolbar.items.first { $0.customView === panel })
        let panels: [TabTrayPanelType] = [.privateTabs, .tabs, .syncedTabs]
        let identifiers = ["tabGroupsTray.panel.privateTabs", "tabGroupsTray.panel.tabs", "tabGroupsTray.panel.syncedTabs"]
        let titles = panels.map(\.label)

        XCTAssertEqual(toolbar.items.count, 5)
        XCTAssertTrue(item.hidesSharedBackground)
        XCTAssertTrue(try XCTUnwrap(panel.effect as? UIGlassEffect).isInteractive)
        XCTAssertEqual(panel.buttons.count, 3)
        XCTAssertEqual(panel.buttons.compactMap(\.accessibilityIdentifier), identifiers)
        XCTAssertEqual(panel.buttons.map(\.isSelected), [false, true, false])
        XCTAssertFalse(toolbar.items.contains { $0.customView === toolbar.panelSelector })
        for (index, button) in panel.buttons.enumerated() {
            XCTAssertEqual(button.configuration?.title, titles[index])
            XCTAssertEqual(button.accessibilityLabel, titles[index])
            let font = try XCTUnwrap(button.titleLabel?.font)
            XCTAssertEqual(font.pointSize, UIFontMetrics(forTextStyle: .subheadline).scaledValue(for: 15), accuracy: 0.01)
            XCTAssertEqual(font.fontName, UIFont.systemFont(ofSize: 15, weight: index == 1 ? .semibold : .medium).fontName)
            XCTAssertEqual(button.titleLabel?.adjustsFontForContentSizeCategory, true)
            button.sendActions(for: .touchUpInside)
            XCTAssertEqual(receivedAction, .selectPanel(panels[index]))
        }

        toolbar.update(viewModel: makeViewModel(selectedPanel: .privateTabs), usesGlassButtons: true)
        XCTAssertEqual(try glassPanel(in: toolbar).buttons.map(\.isSelected), [true, false, false])
        toolbar.update(viewModel: makeViewModel(selectedPanel: .syncedTabs), usesGlassButtons: true)
        XCTAssertEqual(try glassPanel(in: toolbar).buttons.map(\.isSelected), [false, false, true])
    }

    @MainActor
    func testNativeToolbar_glassPanTracksFingerWithoutCommittingOrSnappingOnUpdate() throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Native glass toolbars require iOS 26.") }
        var actions: [TabGroupsTrayBarAction] = []
        try withHostedGlassPanel(onAction: { actions.append($0) }) { toolbar, panel in
            let originalFrame = panel.selectionIndicator.frame
            XCTAssertGreaterThan(originalFrame.width, 0)
            XCTAssertTrue(panel.contentView.gestureRecognizers?.contains { $0 is UIPanGestureRecognizer } == true)
            let grab = CGPoint(x: originalFrame.midX - 8, y: originalFrame.midY)

            panel.handlePan(state: .began, location: grab)
            XCTAssertEqual(panel.selectionIndicator.frame, originalFrame)
            panel.handlePan(state: .changed, location: CGPoint(x: grab.x + 20, y: grab.y))
            XCTAssertEqual(panel.selectionIndicator.center.x, originalFrame.midX + 20, accuracy: 0.01)
            toolbar.update(viewModel: makeViewModel(), usesGlassButtons: true)
            panel.layoutIfNeeded()
            XCTAssertEqual(panel.selectionIndicator.center.x, originalFrame.midX + 20, accuracy: 0.01)
            let centers = panel.buttons.map { $0.convert($0.bounds, to: panel.contentView).midX }
            panel.handlePan(state: .changed, location: CGPoint(x: -100, y: grab.y))
            XCTAssertEqual(panel.selectionIndicator.center.x, try XCTUnwrap(centers.min()), accuracy: 0.01)
            panel.handlePan(state: .changed, location: CGPoint(x: panel.bounds.maxX + 100, y: grab.y))
            XCTAssertEqual(panel.selectionIndicator.center.x, try XCTUnwrap(centers.max()), accuracy: 0.01)
            XCTAssertTrue(actions.isEmpty)
        }
    }

    @MainActor
    func testNativeToolbar_cancelledGlassPanRestoresSelectionWithoutCommitting() throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Native glass toolbars require iOS 26.") }
        var actions: [TabGroupsTrayBarAction] = []
        try withHostedGlassPanel(onAction: { actions.append($0) }) { _, panel in
            let originalFrame = panel.selectionIndicator.frame
            let destination = panel.buttons[0].convert(panel.buttons[0].bounds, to: panel.contentView)
            let states: [UIGestureRecognizer.State] = [.cancelled, .failed]

            for state in states {
                panel.handlePan(state: .began, location: CGPoint(x: originalFrame.midX, y: originalFrame.midY))
                panel.handlePan(state: .changed, location: CGPoint(x: destination.midX, y: destination.midY))
                XCTAssertNotEqual(panel.selectionIndicator.frame, originalFrame)
                panel.handlePan(state: state, location: CGPoint(x: destination.midX, y: destination.midY))
                XCTAssertEqual(panel.selectionIndicator.frame, originalFrame)
                XCTAssertTrue(actions.isEmpty)
            }
        }
    }

    @MainActor
    func testNativeToolbar_glassPanCommitsNearestSegmentOnceInEitherLayoutDirection() throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Native glass toolbars require iOS 26.") }
        let directions: [UISemanticContentAttribute] = [.forceLeftToRight, .forceRightToLeft]
        for direction in directions {
            var actions: [TabGroupsTrayBarAction] = []
            try withHostedGlassPanel(direction: direction, onAction: { actions.append($0) }) { _, panel in
                let destination = panel.buttons[0].convert(panel.buttons[0].bounds, to: panel.contentView)
                let selected = panel.buttons[1].convert(panel.buttons[1].bounds, to: panel.contentView)
                XCTAssertEqual(destination.midX < selected.midX, direction == .forceLeftToRight)
                let release = CGPoint(x: destination.midX + (selected.midX - destination.midX) * 0.4,
                                      y: selected.midY)

                panel.handlePan(state: .began, location: CGPoint(x: selected.midX, y: selected.midY))
                panel.handlePan(state: .changed, location: release)
                XCTAssertTrue(actions.isEmpty)
                panel.handlePan(state: .ended, location: release)
                panel.handlePan(state: .ended, location: release)
                XCTAssertEqual(actions, [.selectPanel(.privateTabs)])
                XCTAssertEqual(panel.selectionIndicator.frame, destination.insetBy(dx: 0, dy: 4))
            }
        }
    }

    @MainActor
    func testNativeToolbar_glassPanelFillsAvailableWidthAndRestoresIntrinsicSizing() throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Native glass toolbars require iOS 26.") }
        let toolbar = TabGroupsTrayNativeToolbar { _ in }
        toolbar.update(viewModel: makeViewModel(), usesGlassButtons: true)
        let panel = try glassPanel(in: toolbar)
        let intrinsicWidth = panel.intrinsicContentSize.width
        let reservedWidth: CGFloat = 2 * (48 + 12)
        let availableWidths: [CGFloat] = [393, 600]

        for availableWidth in availableWidths {
            toolbar.updateLayout(availableWidth: availableWidth)
            toolbar.update(viewModel: makeViewModel(), usesGlassButtons: true)

            XCTAssertEqual(panel.preferredWidth, availableWidth - reservedWidth)
            XCTAssertEqual(panel.intrinsicContentSize.width, availableWidth - reservedWidth, accuracy: 0.5)
        }
        toolbar.updateLayout(availableWidth: nil)

        XCTAssertNil(panel.preferredWidth)
        XCTAssertEqual(panel.intrinsicContentSize.width, intrinsicWidth, accuracy: 0.5)
    }

    @MainActor
    func testNativeToolbar_availableWidthResizesPanelAndRestoresIntrinsicFallback() {
        let toolbar = TabGroupsTrayNativeToolbar { _ in }
        toolbar.update(viewModel: makeViewModel(), usesGlassButtons: false)
        let intrinsicWidth = toolbar.panelSelector.bounds.width
        let reservedWidth = 2 * (TabGroupsTrayBarMetrics.buttonSize + 12)

        let availableWidths: [CGFloat] = [393, 600, 600]
        for availableWidth in availableWidths {
            toolbar.updateLayout(availableWidth: availableWidth)

            XCTAssertEqual(toolbar.panelSelector.bounds.width, availableWidth - reservedWidth, accuracy: 0.5)
        }

        let unavailableWidths: [CGFloat?] = [nil, 0, reservedWidth]
        for unavailableWidth in unavailableWidths {
            toolbar.updateLayout(availableWidth: 393)
            toolbar.updateLayout(availableWidth: unavailableWidth)

            XCTAssertEqual(toolbar.panelSelector.bounds.width, intrinsicWidth, accuracy: 0.5)
        }
    }

    @MainActor
    func testNativeToolbar_hostedFallbackPanelFillsAvailableWidthAfterRepeatedUpdates() throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Native glass toolbars require iOS 26.") }
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previousKeyWindow = scene.windows.first { $0.isKeyWindow }
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 393, height: 200)
        let controller = UIViewController()
        window.rootViewController = controller
        let nativeToolbar = UIToolbar(frame: CGRect(x: 0, y: 144, width: 393, height: 56))
        controller.view.addSubview(nativeToolbar)
        let toolbar = TabGroupsTrayNativeToolbar { _ in }
        toolbar.update(viewModel: makeViewModel(), usesGlassButtons: false)
        nativeToolbar.setItems(toolbar.items, animated: false)
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            previousKeyWindow?.makeKeyAndVisible()
        }
        window.layoutIfNeeded()
        nativeToolbar.layoutIfNeeded()
        XCTAssertTrue(toolbar.panelSelector.isDescendant(of: nativeToolbar))
        XCTAssertTrue(nativeToolbar.window === window)
        let availableWidth = nativeToolbar.layoutMarginsGuide.layoutFrame.width
        let reservedWidth = 2 * (TabGroupsTrayBarMetrics.buttonSize + 12)
        XCTAssertGreaterThan(availableWidth, reservedWidth)

        for updatesViewModel in [false, true] {
            if updatesViewModel {
                toolbar.update(viewModel: makeViewModel(), usesGlassButtons: false)
            }
            toolbar.updateLayout(availableWidth: availableWidth)
            window.layoutIfNeeded()
            nativeToolbar.layoutIfNeeded()

            XCTAssertEqual(toolbar.panelSelector.frame.width,
                           availableWidth - reservedWidth,
                           accuracy: 0.5,
                           "Toolbar: \(nativeToolbar.frame), panel: \(toolbar.panelSelector.frame), " +
                           "available width: \(availableWidth), updated view model: \(updatesViewModel)")
        }
    }

    @MainActor
    func testNativeToolbar_modelUpdatesKeepFlatControlsUntilHostedItemsAreRequested() throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Native glass toolbars require iOS 26.") }
        let toolbar = TabGroupsTrayNativeToolbar { _ in }
        let model = makeViewModel()
        toolbar.update(viewModel: model, usesGlassButtons: true)
        let hostedItems = toolbar.makeHostedItems()
        let row = try XCTUnwrap(hostedItems.compactMap {
            $0.customView as? TabGroupsTrayNativeToolbar.GlassRow
        }.first)
        let controls = toolbar.items.compactMap(\.customView)
        XCTAssertEqual(controls.count, 3)
        XCTAssertTrue(controls.allSatisfy { $0.superview === row })
        let flatHost = UIView()
        controls.forEach { flatHost.addSubview($0) }

        toolbar.update(viewModel: model, usesGlassButtons: true)

        XCTAssertTrue(controls.allSatisfy { $0.superview === flatHost })
        let restoredItems = toolbar.makeHostedItems()
        let restoredRow = try XCTUnwrap(restoredItems.compactMap {
            $0.customView as? TabGroupsTrayNativeToolbar.GlassRow
        }.first)
        XCTAssertTrue(controls.allSatisfy { $0.superview === restoredRow })
    }

    @MainActor
    func testNativeToolbar_hostedGlassPanelFillsAvailableWidthAfterRepeatedUpdates() throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Native glass toolbars require iOS 26.") }
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previousKeyWindow = scene.windows.first { $0.isKeyWindow }
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 393, height: 200)
        let controller = UIViewController()
        window.rootViewController = controller
        let nativeToolbar = UIToolbar(frame: CGRect(x: 0, y: 144, width: 393, height: 56))
        nativeToolbar.directionalLayoutMargins.leading = 16
        nativeToolbar.directionalLayoutMargins.trailing = 16
        controller.view.addSubview(nativeToolbar)
        let toolbar = TabGroupsTrayNativeToolbar { _ in }
        toolbar.update(viewModel: makeViewModel(), usesGlassButtons: true)
        let panel = try glassPanel(in: toolbar)
        nativeToolbar.setItems(toolbar.makeHostedItems(), animated: false)
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            previousKeyWindow?.makeKeyAndVisible()
        }
        window.layoutIfNeeded()
        nativeToolbar.layoutIfNeeded()
        XCTAssertTrue(panel.isDescendant(of: nativeToolbar))
        XCTAssertTrue(nativeToolbar.window === window)
        let availableWidth = nativeToolbar.layoutMarginsGuide.layoutFrame.width
        let reservedWidth: CGFloat = 2 * (48 + 12)
        XCTAssertGreaterThan(availableWidth, reservedWidth)

        for updatesViewModel in [false, true] {
            if updatesViewModel {
                toolbar.update(viewModel: makeViewModel(), usesGlassButtons: true)
            }
            toolbar.updateLayout(availableWidth: availableWidth)
            window.layoutIfNeeded()
            nativeToolbar.layoutIfNeeded()

            let addItem = try XCTUnwrap(toolbar.items.first { $0.accessibilityIdentifier == "tabGroupsTray.addTab" })
            let doneItem = try XCTUnwrap(toolbar.items.first { $0.accessibilityIdentifier == "tabGroupsTray.done" })
            let add = try glassButton(in: addItem)
            let done = try glassButton(in: doneItem)
            XCTAssertTrue(add.isDescendant(of: nativeToolbar))
            XCTAssertTrue(done.isDescendant(of: nativeToolbar))
            XCTAssertEqual(add.bounds.size, CGSize(width: 48, height: 48))
            XCTAssertEqual(done.bounds.size, CGSize(width: 48, height: 48))
            XCTAssertGreaterThanOrEqual(add.convert(add.bounds, to: nativeToolbar).minX, 16)
            XCTAssertLessThanOrEqual(done.convert(done.bounds, to: nativeToolbar).maxX, nativeToolbar.bounds.width - 16)
            XCTAssertEqual(panel.frame.width,
                           availableWidth - reservedWidth,
                           accuracy: 0.5,
                           "Toolbar: \(nativeToolbar.frame), panel: \(panel.frame), " +
                           "available width: \(availableWidth), updated view model: \(updatesViewModel)")
            for button in panel.buttons {
                XCTAssertGreaterThanOrEqual(button.frame.height, 44)
            }
        }
    }

    @MainActor
    func testNativeToolbar_glassEndButtonsRouteActionsAndRestoreFallback() throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Native glass toolbars require iOS 26.") }
        var receivedAction: TabGroupsTrayBarAction?
        let toolbar = TabGroupsTrayNativeToolbar { receivedAction = $0 }
        let model = makeViewModel()
        toolbar.update(viewModel: model, usesGlassButtons: true)
        let identifiers = ["tabGroupsTray.addTab", "tabGroupsTray.done"]
        let labels = [model.addTabAccessibilityLabel, model.doneAccessibilityLabel]
        let actions: [TabGroupsTrayBarAction] = [.addTab, .done]

        for (index, identifier) in identifiers.enumerated() {
            let item = try XCTUnwrap(toolbar.items.first { $0.accessibilityIdentifier == identifier })
            let button = try glassButton(in: item)
            XCTAssertTrue(item.hidesSharedBackground)
            XCTAssertEqual(button.accessibilityLabel, labels[index])
            XCTAssertNotNil(button.configuration)
            button.sendActions(for: .touchUpInside)
            XCTAssertEqual(receivedAction, actions[index])
        }
        toolbar.update(viewModel: model, usesGlassButtons: false)

        for identifier in identifiers {
            let item = try XCTUnwrap(toolbar.items.first { $0.accessibilityIdentifier == identifier })
            XCTAssertNil(item.customView)
            XCTAssertFalse(item.hidesSharedBackground)
        }
    }

    @MainActor
    func testNativeToolbar_defaultGroupKeepsPlainDoneVisibleAndProminentFillNeutral() throws {
        let themes: [any Theme] = [NovaLightTheme(), NovaDarkTheme()]
        let toolbar = TabGroupsTrayNativeToolbar { _ in }
        for theme in themes {
            var model = makeViewModel(isGroupSelected: true, groupColor: Color(theme.colors.tabGroupNoColor))
            model.colors = .themed(theme, isDefaultGroup: true)
            toolbar.update(viewModel: model, usesGlassButtons: false)
            let done = try XCTUnwrap(toolbar.items.first { $0.accessibilityIdentifier == "tabGroupsTray.done" })

            XCTAssertEqual(done.tintColor, UIColor(Color(theme.colors.iconPrimary)))

            if #available(iOS 26.0, *) {
                toolbar.update(viewModel: model, usesGlassButtons: true)
                let button = try glassButton(in: done)
                XCTAssertEqual(button.configuration?.baseBackgroundColor, UIColor(Color(theme.colors.tabGroupNoColor)))
            }
        }
    }

    @MainActor
    func testNativeToolbar_keepsTabsSegmentStableAndRoutesPanelActions() {
        var receivedAction: TabGroupsTrayBarAction?
        let toolbar = TabGroupsTrayNativeToolbar { receivedAction = $0 }
        toolbar.update(viewModel: makeViewModel(), usesGlassButtons: false)

        XCTAssertEqual(toolbar.items.count, 5)
        XCTAssertEqual(toolbar.panelSelector.titleForSegment(at: 1), String.TabsTray.TabsSelectorNormalTabsTitle)
        XCTAssertEqual(toolbar.panelSelector.selectedSegmentIndex, 1)

        toolbar.panelSelector.selectedSegmentIndex = 0
        toolbar.panelSelector.sendActions(for: .valueChanged)
        XCTAssertEqual(receivedAction, .selectPanel(.privateTabs))

        toolbar.panelSelector.selectedSegmentIndex = 2
        toolbar.panelSelector.sendActions(for: .valueChanged)
        XCTAssertEqual(receivedAction, .selectPanel(.syncedTabs))
    }

    @MainActor
    func testNativeToolbar_fallbackSegmentsFitAtAccessibilityTextSize() {
        let toolbar = TabGroupsTrayNativeToolbar { _ in }
        let traits = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        traits.performAsCurrent {
            toolbar.update(viewModel: makeViewModel(),
                           usesGlassButtons: false)
        }

        let availableWidth = 393 - 2 * (TabGroupsTrayBarMetrics.buttonSize + 16)
        XCTAssertLessThanOrEqual(toolbar.panelSelector.bounds.width, availableWidth)
    }

    @MainActor
    @available(iOS 26.0, *)
    private func accessibleButtons(in row: TabGroupsTrayNativeToolbar.GlassRow) throws -> [UIButton] {
        let containers = try XCTUnwrap(row.accessibilityElements as? [UIView])
        return try containers.flatMap { try XCTUnwrap($0.accessibilityElements as? [UIButton]) }
    }

    @MainActor
    @available(iOS 26.0, *)
    private func withHostedGlassPanel(
        direction: UISemanticContentAttribute = .forceLeftToRight,
        onAction: @escaping (TabGroupsTrayBarAction) -> Void,
        body: (TabGroupsTrayNativeToolbar, TabGroupsTrayGlassPanel) throws -> Void
    ) throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previousKeyWindow = scene.windows.first { $0.isKeyWindow }
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 393, height: 200)
        window.semanticContentAttribute = direction
        let controller = UIViewController()
        window.rootViewController = controller
        controller.view.semanticContentAttribute = direction
        let toolbar = TabGroupsTrayNativeToolbar(onAction: onAction)
        toolbar.update(viewModel: makeViewModel(), usesGlassButtons: true)
        let panel = try glassPanel(in: toolbar)
        panel.semanticContentAttribute = direction
        panel.preferredWidth = 240
        controller.view.addSubview(panel)
        NSLayoutConstraint.activate([
            panel.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            panel.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor)
        ])
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            previousKeyWindow?.makeKeyAndVisible()
        }
        window.layoutIfNeeded()
        controller.view.layoutIfNeeded()
        panel.layoutIfNeeded()
        panel.contentView.layoutIfNeeded()
        panel.setNeedsLayout()
        panel.layoutIfNeeded()
        XCTAssertFalse(panel.selectionIndicator.frame.isEmpty)
        try body(toolbar, panel)
    }

    @MainActor
    @available(iOS 26.0, *)
    private func glassButton(in item: UIBarButtonItem) throws -> UIButton {
        let container = try XCTUnwrap(item.customView as? TabGroupsTrayNativeToolbar.GlassButtonContainer)
        return container.button
    }

    @MainActor
    @available(iOS 26.0, *)
    private func glassPanel(in toolbar: TabGroupsTrayNativeToolbar) throws -> TabGroupsTrayGlassPanel {
        try XCTUnwrap(toolbar.items.compactMap { $0.customView as? TabGroupsTrayGlassPanel }.first)
    }

    private func makeViewModel(
        isGroupSelected: Bool = false,
        groupColor: Color? = nil,
        selectedPanel: TabTrayPanelType = .tabs
    ) -> TabGroupsTrayBarViewModel {
        TabGroupsTrayBarViewModel(destinationTitle: "20 Tabs",
                                  isGroupSelected: isGroupSelected,
                                  selectedPanel: selectedPanel,
                                  doneAccessibilityLabel: String.TabGroups.Accessibility.DoneButton,
                                  addTabAccessibilityLabel: String.TabGroups.Accessibility.NewTabButton,
                                  groupColor: groupColor)
    }
}
