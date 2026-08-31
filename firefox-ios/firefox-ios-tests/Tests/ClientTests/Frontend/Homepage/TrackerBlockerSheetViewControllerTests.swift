// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import ComponentLibrary
import Shared
import UIKit

@testable import Client

@MainActor
final class TrackerBlockerSheetViewControllerTests: XCTestCase {
    private typealias A11y = AccessibilityIdentifiers.FirefoxHomepage.TrackerBlockerModule.Sheet

    func test_loadView_setsUpKeySubviews() {
        let subject = createSubject()

        subject.loadViewIfNeeded()

        XCTAssertNotNil(view(subject, withID: A11y.shieldIcon))
        XCTAssertNotNil(view(subject, withID: A11y.weeklyCountLabel))
        XCTAssertNotNil(view(subject, withID: A11y.categoriesCard))
    }

    func test_configureEmptyState_hidesWeeklyCountAndFooter() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        subject.configure(with: .dummyEmpty)

        XCTAssertEqual(view(subject, withID: A11y.weeklyCountLabel)?.isHidden, true)
        // The footer stays in the layout but is empty (no a11y label) in the empty state.
        XCTAssertEqual(footerPill(in: subject)?.isAccessibilityElement, false)
        XCTAssertNil(footerPill(in: subject)?.accessibilityLabel)
        XCTAssertEqual((view(subject, withID: A11y.headerLabel) as? UILabel)?.text,
                       TrackerBlockerSheetState.dummyEmpty.emptyMessage)
    }

    func test_configureFilledState_showsWeeklyCountAndFooter() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        subject.configure(with: .dummyFilled)

        let weeklyLabel = view(subject, withID: A11y.weeklyCountLabel) as? UILabel
        XCTAssertEqual(weeklyLabel?.isHidden, false)
        XCTAssertEqual(weeklyLabel?.text, TrackerBlockerSheetState.dummyFilled.weeklyCount?.formatted(.number))
        XCTAssertEqual(footerPill(in: subject)?.accessibilityLabel, TrackerBlockerSheetState.dummyFilled.total?.text)
    }

    func test_configureFilledState_setsCategoryRowIdentifiers() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        subject.configure(with: .dummyFilled)

        for index in 0..<TrackerBlockerSheetState.dummyFilled.categories.count {
            XCTAssertNotNil(view(subject, withID: A11y.categoryRow(index)),
                            "Expected a category row for index \(index)")
        }
    }

    func test_configureWeeklyResetState_showsZeroWeeklyCountAndFooter() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        subject.configure(with: .dummyWeeklyReset)

        let weeklyLabel = view(subject, withID: A11y.weeklyCountLabel) as? UILabel
        XCTAssertEqual(weeklyLabel?.isHidden, false)
        XCTAssertEqual(weeklyLabel?.text, 0.formatted(.number))
        XCTAssertEqual(footerPill(in: subject)?.accessibilityLabel, TrackerBlockerSheetState.dummyWeeklyReset.total?.text)
    }

    func test_loadView_setsUpCloseButton() {
        let subject = createSubject()

        subject.loadViewIfNeeded()

        XCTAssertNotNil(view(subject, withID: A11y.closeButton))
    }

    // MARK: - Progress bar widths

    /// A four-digit count is much wider than a one-digit count, but the bars beside them must still match.
    func test_configureMixedDigitCounts_givesEveryRowTheSameBarWidth() {
        let subject = createSubject()
        subject.loadViewIfNeeded()
        subject.view.frame = CGRect(x: 0, y: 0, width: 390, height: 700)

        subject.configure(with: .mixedDigitCounts)
        subject.view.layoutIfNeeded()

        let widths = Set(progressBars(in: subject).map { $0.bounds.width.rounded() })
        XCTAssertEqual(widths.count, 1, "Expected one shared bar width, got \(widths.sorted())")
    }

    func test_configureMixedDigitCounts_leavesRoomForTheWidestCount() throws {
        let subject = createSubject()
        subject.loadViewIfNeeded()
        subject.view.frame = CGRect(x: 0, y: 0, width: 390, height: 700)

        subject.configure(with: .mixedDigitCounts)
        subject.view.layoutIfNeeded()

        // The shared column has to fit the widest count without truncating it.
        let widest = try XCTUnwrap(allSubviews(in: subject.view)
            .compactMap { $0 as? UILabel }
            .first { $0.text == 4040.formatted(.number) })
        XCTAssertGreaterThanOrEqual(widest.bounds.width, widest.intrinsicContentSize.width)
        XCTAssertGreaterThan(
            progressBars(in: subject).first?.bounds.width ?? 0,
            0,
            "Expected the bars to keep a positive width"
        )
    }

    private func progressBars(in controller: UIViewController) -> [TrackerBlockerProgressBarView] {
        return allSubviews(in: controller.view).compactMap { $0 as? TrackerBlockerProgressBarView }
    }

    // MARK: - Footer pill

    func test_configureFilledState_boldsOnlyTheTotalCount() throws {
        let subject = createSubject()
        subject.loadViewIfNeeded()
        subject.configure(with: .dummyFilled)

        let total = try XCTUnwrap(TrackerBlockerSheetState.dummyFilled.total)
        let text = try XCTUnwrap(footerLabel(in: subject)?.attributedText)
        let countRange = try XCTUnwrap(total.text.range(of: total.countText))

        XCTAssertEqual(text.string, total.text)
        XCTAssertTrue(isBold(text, at: NSRange(countRange, in: total.text).location),
                      "Expected the count to be bold")
        XCTAssertFalse(isBold(text, at: text.length - 1), "Expected the trailing copy to stay regular")
    }

    func test_configureEmptyState_clearsFooterText() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        subject.configure(with: .dummyEmpty)

        XCTAssertNil(footerLabel(in: subject)?.attributedText)
        XCTAssertNil(footerLabel(in: subject)?.text)
    }

    private func footerLabel(in controller: UIViewController) -> UILabel? {
        return footerPill(in: controller)?.subviews.compactMap { $0 as? UILabel }.first
    }

    private func isBold(_ text: NSAttributedString, at location: Int) -> Bool {
        let font = text.attribute(.font, at: location, effectiveRange: nil) as? UIFont
        return font?.fontDescriptor.symbolicTraits.contains(.traitBold) ?? false
    }

    // MARK: - Fill ratios

    func test_fillRatio_isCategoryShareOfWeeklyCount() {
        let subject = TrackerBlockerSheetState(
            weeklyCount: 100,
            emptyMessage: nil,
            categories: [
                .init(kind: .fingerprinters, count: 70),
                .init(kind: .trackingContent, count: 30)
            ],
            total: nil
        )

        XCTAssertEqual(subject.fillRatio(for: subject.categories[0]), 0.7, accuracy: 0.0001)
        XCTAssertEqual(subject.fillRatio(for: subject.categories[1]), 0.3, accuracy: 0.0001)
    }

    func test_fillRatio_withZeroWeeklyCount_isZero() {
        let subject = TrackerBlockerSheetState.dummyWeeklyReset

        for category in subject.categories {
            XCTAssertEqual(subject.fillRatio(for: category), 0)
        }
    }

    func test_fillRatio_withNilWeeklyCount_isZero() {
        let subject = TrackerBlockerSheetState.dummyEmpty

        for category in subject.categories {
            XCTAssertEqual(subject.fillRatio(for: category), 0)
        }
    }

    /// The weekly count is the source of truth, so a category can never overfill its bar.
    func test_fillRatio_withCountAboveWeeklyCount_isClampedToOne() {
        let subject = TrackerBlockerSheetState(
            weeklyCount: 10,
            emptyMessage: nil,
            categories: [.init(kind: .fingerprinters, count: 25)],
            total: nil
        )

        XCTAssertEqual(subject.fillRatio(for: subject.categories[0]), 1)
    }

    /// The header shield is a pre-coloured asset, so it must not be tinted from the theme.
    func test_loadView_setsUpShieldIcon() throws {
        let subject = createSubject()

        subject.loadViewIfNeeded()

        let shield = try XCTUnwrap(view(subject, withID: A11y.shieldIcon) as? UIImageView)
        XCTAssertNotNil(shield.image, "Expected \(ImageIdentifiers.shieldCheckmarkColored) to resolve to an asset")
        XCTAssertEqual(shield.image?.renderingMode, .automatic)
    }

    // MARK: - Category icons

    /// The sheet shows the same icon per category as the enhanced tracking protection panel.
    func test_categoryRow_usesTheCategoryIconForItsKind() throws {
        let expectedNames: [TrackerBlockerSheetState.Category.Kind: String] = [
            .crossSiteTrackingCookies: StandardImageIdentifiers.Large.cookies,
            .fingerprinters: StandardImageIdentifiers.Large.fingerprinter,
            .trackingContent: StandardImageIdentifiers.Large.image,
            .socialMediaTrackers: StandardImageIdentifiers.Large.socialMedia
        ]

        for kind in TrackerBlockerSheetState.Category.Kind.allCases {
            let expectedName = try XCTUnwrap(expectedNames[kind])
            XCTAssertEqual(kind.imageName, expectedName)

            // Also catches a name that no longer resolves to an asset in the bundle.
            let imageView = try XCTUnwrap(icon(in: makeRow(count: 12, kind: kind)))
            XCTAssertNotNil(imageView.image, "Expected \(expectedName) to resolve to an asset")
            XCTAssertEqual(imageView.image?.renderingMode, .alwaysTemplate)
        }
    }

    func test_categoryRow_tintsIconWithSecondaryIconColour() throws {
        let theme = LightTheme()
        let row = makeRow(count: 12)

        row.applyTheme(theme: theme)

        XCTAssertEqual(try XCTUnwrap(icon(in: row)).tintColor, theme.colors.iconSecondary)
    }

    // MARK: - Category row layout

    func test_categoryRow_withoutCount_collapsesProgressBarHeight() {
        let filled = makeRow(count: 12)
        let empty = makeRow(count: nil)

        XCTAssertLessThan(height(of: empty), height(of: filled))
    }

    /// Neither the icon nor a single line of title fills the empty row, so it sits at the fixed minimum.
    func test_categoryRow_emptyState_usesMinimumHeight() {
        let empty = makeRow(count: nil)

        XCTAssertEqual(height(of: empty), UX.emptyStateMinHeight, accuracy: 0.5)
    }

    func test_categoryRow_emptyState_centersIconInRow() throws {
        let row = laidOutRow(count: nil)

        let iconFrame = try frame(of: XCTUnwrap(icon(in: row)), in: row)

        XCTAssertEqual(iconFrame.midY, row.bounds.midY, accuracy: 0.5)
        XCTAssertGreaterThanOrEqual(iconFrame.minY, UX.rowVerticalPadding)
    }

    /// The minimum is a floor, not a fixed height: a wrapping title still grows the row past it.
    func test_categoryRow_emptyStateWithWrappingTitle_growsPastMinimumHeight() {
        let empty = makeRow(count: nil, title: String(repeating: "Cross-Site Tracking Cookies ", count: 4))

        XCTAssertGreaterThan(height(of: empty), UX.emptyStateMinHeight)
    }

    /// The icon is centred on the title rather than on the row, so it stays beside the text when the title wraps.
    func test_categoryRow_withWrappingTitle_centersIconOnTitle() throws {
        let title = String(repeating: "Cross-Site Tracking Cookies ", count: 4)
        let row = laidOutRow(count: 12, title: title)

        let iconFrame = try frame(of: XCTUnwrap(icon(in: row)), in: row)
        let titleFrame = try frame(of: XCTUnwrap(label(in: row, withText: title)), in: row)

        XCTAssertGreaterThan(titleFrame.height, iconFrame.height, "Expected the title to wrap past the icon height")
        XCTAssertEqual(iconFrame.midY, titleFrame.midY, accuracy: 0.5)
        XCTAssertNotEqual(iconFrame.midY, row.bounds.midY, accuracy: 0.5)
    }

    func test_categoryRow_placesCountInlineWithProgressBar() throws {
        let row = laidOutRow(count: 12)

        let titleFrame = try frame(of: XCTUnwrap(label(in: row, withText: "Fingerprinters")), in: row)
        let countFrame = try frame(of: XCTUnwrap(label(in: row, withText: 12.formatted(.number))), in: row)
        let barFrame = try frame(
            of: XCTUnwrap(allSubviews(in: row).first { $0 is TrackerBlockerProgressBarView }),
            in: row
        )

        XCTAssertGreaterThan(countFrame.minY, titleFrame.maxY, "Expected the count to sit below the title")
        XCTAssertEqual(countFrame.midY, barFrame.midY, accuracy: 0.5)
        XCTAssertLessThan(barFrame.maxX, countFrame.minX, "Expected the count to trail the bar")
    }

    // MARK: - Theming

    func test_applyTheme_withNovaTheme_drawsBackgroundGradient() throws {
        let theme = NovaLightTheme()
        let subject = createSubject(themeManager: MockThemeManager(currentTheme: theme))

        subject.loadViewIfNeeded()

        let background = try XCTUnwrap(backgroundGradientView(in: subject))
        XCTAssertEqual((background.layer as? CAGradientLayer)?.colors as? [CGColor],
                       theme.colors.gradientAccentSubtle.cgColors)
        // The gradient carries its own alpha, so the flat fill stays behind it.
        XCTAssertEqual(background.backgroundColor, theme.colors.layer2)
    }

    /// The gradient tokens are Nova-only, so a classic theme has to fall back to the flat fill alone.
    func test_applyTheme_withClassicTheme_drawsNoBackgroundGradient() throws {
        let theme = LightTheme()
        let subject = createSubject(themeManager: MockThemeManager(currentTheme: theme))

        subject.loadViewIfNeeded()

        let background = try XCTUnwrap(backgroundGradientView(in: subject))
        XCTAssertNil((background.layer as? CAGradientLayer)?.colors)
        XCTAssertEqual(background.backgroundColor, theme.colors.layer2)
    }

    func test_applyTheme_withNovaTheme_appliesGlassToCategoriesCard() throws {
        guard #available(iOS 26.0, *), !DeviceInfo.isRunningLiquidGlassEarlyBeta else {
            throw XCTSkip("The card only carries glass on iOS 26, outside the early betas")
        }
        let theme = NovaDarkTheme()
        let subject = createSubject(themeManager: MockThemeManager(currentTheme: theme))

        subject.loadViewIfNeeded()

        let card = try XCTUnwrap(categoriesCard(in: subject))
        let glass = try XCTUnwrap(card.effect as? UIGlassEffect)
        XCTAssertEqual(glass.tintColor, theme.colors.layerGlassTintNova)
        XCTAssertEqual(card.backgroundColor, .clear)
    }

    /// The glass tint tokens are Nova-only, so a classic theme keeps the flat card fill.
    func test_applyTheme_withClassicTheme_drawsFlatCategoriesCard() throws {
        let theme = LightTheme()
        let subject = createSubject(themeManager: MockThemeManager(currentTheme: theme))

        subject.loadViewIfNeeded()

        let card = try XCTUnwrap(categoriesCard(in: subject))
        XCTAssertNil(card.effect)
        XCTAssertEqual(card.backgroundColor, theme.colors.layer2)
    }

    /// Leaving Nova has to clear the glass, otherwise the flat fill would be layered on top of it.
    func test_applyTheme_afterLeavingNovaTheme_clearsCardGlass() throws {
        let themeManager = MockThemeManager(currentTheme: NovaDarkTheme())
        let subject = createSubject(themeManager: themeManager)
        subject.loadViewIfNeeded()

        themeManager.setManualTheme(to: .light)
        subject.applyTheme()

        let card = try XCTUnwrap(categoriesCard(in: subject))
        XCTAssertNil(card.effect)
        XCTAssertEqual(card.backgroundColor, LightTheme().colors.layer2)
    }

    func test_progressBar_withNovaTheme_usesGradientFill() throws {
        let theme = NovaLightTheme()
        let subject = TrackerBlockerProgressBarView()

        subject.applyTheme(theme: theme)

        let fill = try XCTUnwrap(allSubviews(in: subject).compactMap { $0 as? GradientView }.first)
        XCTAssertEqual((fill.layer as? CAGradientLayer)?.colors as? [CGColor], theme.colors.gradientBorder.cgColors)
        XCTAssertEqual(fill.backgroundColor, .clear)
    }

    func test_progressBar_withClassicTheme_usesSolidFill() throws {
        let theme = LightTheme()
        let subject = TrackerBlockerProgressBarView()

        subject.applyTheme(theme: theme)

        let fill = try XCTUnwrap(allSubviews(in: subject).compactMap { $0 as? GradientView }.first)
        XCTAssertNil((fill.layer as? CAGradientLayer)?.colors)
        XCTAssertEqual(fill.backgroundColor, theme.colors.actionPrimary)
    }

    /// Separators are built once per `configure(with:)` but have to keep up with later theme changes.
    func test_applyTheme_afterThemeChange_recoloursSeparators() {
        let themeManager = MockThemeManager(currentTheme: LightTheme())
        let subject = createSubject(themeManager: themeManager)
        subject.loadViewIfNeeded()
        subject.configure(with: .dummyFilled)
        let separators = separators(in: subject)

        themeManager.setManualTheme(to: .dark)
        subject.applyTheme()

        XCTAssertEqual(separators.count, TrackerBlockerSheetState.dummyFilled.categories.count - 1)
        XCTAssertTrue(separators.allSatisfy { $0.backgroundColor == DarkTheme().colors.borderPrimary },
                      "Expected every separator to pick up the new theme")
    }

    private func backgroundGradientView(in controller: UIViewController) -> GradientView? {
        // The only `GradientView` directly under the root view; the progress bars' fills sit deeper.
        return controller.view.subviews.compactMap { $0 as? GradientView }.first
    }

    private func separators(in controller: UIViewController) -> [UIView] {
        guard let card = view(controller, withID: A11y.categoriesCard),
              let stack = allSubviews(in: card).compactMap({ $0 as? UIStackView }).first else { return [] }
        return stack.arrangedSubviews.filter { !($0 is TrackerCategoryRowView) }
    }

    // MARK: - Helpers

    /// Mirrors the private `TrackerCategoryRowView.UX` values the layout assertions depend on.
    private enum UX {
        static let rowWidth: CGFloat = 320
        static let rowVerticalPadding: CGFloat = 12
        static let emptyStateMinHeight: CGFloat = 55
    }

    private func makeRow(count: Int?,
                         kind: TrackerBlockerSheetState.Category.Kind = .fingerprinters,
                         title: String? = nil) -> TrackerCategoryRowView {
        let row = TrackerCategoryRowView()
        row.configure(with: .init(kind: kind, count: count, title: title), fillRatio: 0.5, theme: LightTheme())
        return row
    }

    private func laidOutRow(count: Int?, title: String? = nil) -> TrackerCategoryRowView {
        let row = makeRow(count: count, title: title)
        row.frame = CGRect(x: 0, y: 0, width: UX.rowWidth, height: height(of: row))
        row.layoutIfNeeded()
        return row
    }

    private func icon(in row: TrackerCategoryRowView) -> UIImageView? {
        return allSubviews(in: row).compactMap { $0 as? UIImageView }.first
    }

    private func label(in row: TrackerCategoryRowView, withText text: String) -> UILabel? {
        return allSubviews(in: row).compactMap { $0 as? UILabel }.first { $0.text == text }
    }

    private func frame(of view: UIView, in row: TrackerCategoryRowView) -> CGRect {
        return view.convert(view.bounds, to: row)
    }

    private func height(of row: TrackerCategoryRowView) -> CGFloat {
        return row.systemLayoutSizeFitting(
            CGSize(width: UX.rowWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }

    private func createSubject(state: TrackerBlockerSheetState = .dummyFilled,
                               themeManager: MockThemeManager = MockThemeManager()) -> TrackerBlockerSheetViewController {
        let subject = TrackerBlockerSheetViewController(
            windowUUID: .XCTestDefaultUUID,
            state: state,
            themeManager: themeManager,
            notificationCenter: MockNotificationCenter()
        )
        trackForMemoryLeaks(subject)
        return subject
    }

    /// The footer pill is always in the hierarchy; in the empty state it has no total text / a11y label.
    private func footerPill(in controller: UIViewController) -> UIView? {
        return view(controller, withID: A11y.totalPill)
    }

    private func categoriesCard(in controller: UIViewController) -> UIVisualEffectView? {
        return view(controller, withID: A11y.categoriesCard) as? UIVisualEffectView
    }

    private func view(_ controller: UIViewController, withID identifier: String) -> UIView? {
        return allSubviews(in: controller.view).first { $0.accessibilityIdentifier == identifier }
    }

    private func allSubviews(in view: UIView) -> [UIView] {
        return view.subviews + view.subviews.flatMap { allSubviews(in: $0) }
    }
}

private extension TrackerBlockerSheetState {
    /// Counts spanning one to four digits, so the count column has to reconcile very different widths.
    static var mixedDigitCounts: TrackerBlockerSheetState {
        TrackerBlockerSheetState(
            weeklyCount: 4135,
            emptyMessage: nil,
            categories: [
                Category(kind: .crossSiteTrackingCookies, count: 4040),
                Category(kind: .fingerprinters, count: 6),
                Category(kind: .trackingContent, count: 89)
            ],
            total: nil
        )
    }
}
