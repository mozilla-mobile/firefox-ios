// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import ComponentLibrary
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

        subject.configure(with: .empty)

        XCTAssertEqual(view(subject, withID: A11y.weeklyCountLabel)?.isHidden, true)
        // The footer stays in the layout but is empty (no a11y label) in the empty state.
        XCTAssertEqual(footerPill(in: subject)?.isAccessibilityElement, false)
        XCTAssertNil(footerPill(in: subject)?.accessibilityLabel)
        XCTAssertEqual((view(subject, withID: A11y.headerLabel) as? UILabel)?.text,
                       TrackerBlockerSheetState.empty.emptyMessage)
    }

    func test_configureFilledState_showsWeeklyCountAndFooter() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        subject.configure(with: .filled)

        let weeklyLabel = view(subject, withID: A11y.weeklyCountLabel) as? UILabel
        XCTAssertEqual(weeklyLabel?.isHidden, false)
        XCTAssertEqual(weeklyLabel?.text, TrackerBlockerSheetState.filled.weeklyCount?.formatted(.number))
        XCTAssertEqual(footerPill(in: subject)?.accessibilityLabel, TrackerBlockerSheetState.filled.total?.text)
    }

    func test_configureFilledState_setsCategoryRowIdentifiers() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        subject.configure(with: .filled)

        for index in 0..<TrackerBlockerSheetState.filled.categories.count {
            XCTAssertNotNil(view(subject, withID: A11y.categoryRow(index)),
                            "Expected a category row for index \(index)")
        }
    }

    func test_configureWeeklyResetState_showsZeroWeeklyCountAndFooter() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        subject.configure(with: .weeklyReset)

        let weeklyLabel = view(subject, withID: A11y.weeklyCountLabel) as? UILabel
        XCTAssertEqual(weeklyLabel?.isHidden, false)
        XCTAssertEqual(weeklyLabel?.text, 0.formatted(.number))
        XCTAssertEqual(footerPill(in: subject)?.accessibilityLabel, TrackerBlockerSheetState.weeklyReset.total?.text)
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
        subject.configure(with: .filled)

        let total = try XCTUnwrap(TrackerBlockerSheetState.filled.total)
        let text = try XCTUnwrap(footerLabel(in: subject)?.attributedText)
        let countRange = try XCTUnwrap(total.text.range(of: total.countText))

        XCTAssertEqual(text.string, total.text)
        XCTAssertTrue(isBold(text, at: NSRange(countRange, in: total.text).location),
                      "Expected the count to be bold")
        XCTAssertFalse(isBold(text, at: text.length - 1), "Expected the trailing copy to stay regular")
    }

    /// Reconfiguring must not compound the bolding: the base font can't be read back from the label, which
    /// reports the attributed string's first font once one is set.
    func test_configureFilledStateRepeatedly_keepsTheTrailingCopyRegular() throws {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        subject.configure(with: .filled)
        subject.configure(with: .filled)

        let text = try XCTUnwrap(footerLabel(in: subject)?.attributedText)
        XCTAssertFalse(isBold(text, at: text.length - 1), "Expected the trailing copy to stay regular")
    }

    func test_configureEmptyState_clearsFooterText() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        subject.configure(with: .empty)

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
        let subject = TrackerBlockerSheetState.weeklyReset

        for category in subject.categories {
            XCTAssertEqual(subject.fillRatio(for: category), 0)
        }
    }

    func test_fillRatio_withNilWeeklyCount_isZero() {
        let subject = TrackerBlockerSheetState.empty

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

        let titleFrame = try frame(of: XCTUnwrap(label(in: row, withText: .PrivacyDashboard.Fingerprinters)), in: row)
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
        XCTAssertEqual(background.backgroundColor, theme.colors.layer1)
    }

    /// The gradient tokens are Nova-only, so a classic theme has to fall back to the flat fill alone.
    func test_applyTheme_withClassicTheme_drawsNoBackgroundGradient() throws {
        let theme = LightTheme()
        let subject = createSubject(themeManager: MockThemeManager(currentTheme: theme))

        subject.loadViewIfNeeded()

        let background = try XCTUnwrap(backgroundGradientView(in: subject))
        XCTAssertNil((background.layer as? CAGradientLayer)?.colors)
        XCTAssertEqual(background.backgroundColor, theme.colors.layer1)
    }

    /// The card is translucent so the sheet's gradient shows through it, per the Protection Dashboard design.
    func test_applyTheme_usesTranslucentFillForCategoriesCard() throws {
        let theme = NovaDarkTheme()
        let subject = createSubject(themeManager: MockThemeManager(currentTheme: theme))

        subject.loadViewIfNeeded()

        let card = try XCTUnwrap(categoriesCard(in: subject))
        XCTAssertEqual(card.backgroundColor, theme.colors.layerSurfaceMediumAlpha)
        let alpha = try XCTUnwrap(card.backgroundColor?.cgColor.alpha)
        XCTAssertLessThan(alpha, 1, "Expected the card to let the sheet background through")
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
        subject.configure(with: .filled)
        let separators = separators(in: subject)

        themeManager.setManualTheme(to: .dark)
        subject.applyTheme()

        XCTAssertEqual(separators.count, TrackerBlockerSheetState.filled.categories.count - 1)
        XCTAssertTrue(separators.allSatisfy { $0.backgroundColor == DarkTheme().colors.borderPrimary },
                      "Expected every separator to pick up the new theme")
    }

    /// The iPad form sheet wraps its content, so the size it asks for has to track what the sheet is showing.
    func test_contentPreferredSize_tracksTheContentHeight() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        subject.configure(with: .empty)
        let emptySize = subject.contentPreferredSize()
        subject.configure(with: .filled)
        let filledSize = subject.contentPreferredSize()

        XCTAssertEqual(emptySize.width, UX.formSheetWidth)
        XCTAssertEqual(filledSize.width, UX.formSheetWidth)
        XCTAssertGreaterThan(
            filledSize.height,
            emptySize.height,
            "Expected the filled state to ask for a taller sheet than the empty one"
        )
    }

    /// The card breathes above the first row and below the last one, rather than clipping them at its edges.
    func test_categoriesCard_insetsRowsVertically() throws {
        let subject = createSubject()
        subject.loadViewIfNeeded()
        subject.view.frame = CGRect(x: 0, y: 0, width: UX.sheetWidth, height: UX.sheetHeight)
        subject.view.layoutIfNeeded()

        let card = try XCTUnwrap(categoriesCard(in: subject))
        let stack = try XCTUnwrap(allSubviews(in: card).compactMap { $0 as? UIStackView }.first)
        let stackFrame = stack.convert(stack.bounds, to: card)

        XCTAssertEqual(stackFrame.minY, UX.cardTopPadding, accuracy: 0.5)
        XCTAssertEqual(card.bounds.maxY - stackFrame.maxY, UX.cardBottomPadding, accuracy: 0.5)
    }

    /// The line is inset from both ends of the row rather than spanning the card, and never starts before the
    /// row titles do.
    func test_separators_areInsetFromTheRowEdges() throws {
        let subject = createSubject()
        subject.loadViewIfNeeded()
        subject.view.frame = CGRect(x: 0, y: 0, width: UX.sheetWidth, height: UX.sheetHeight)
        subject.view.layoutIfNeeded()

        let card = try XCTUnwrap(categoriesCard(in: subject))
        let line = try XCTUnwrap(separators(in: subject).first)
        let row = try XCTUnwrap(allSubviews(in: card).compactMap { $0 as? TrackerCategoryRowView }.first)
        let icon = try XCTUnwrap(icon(in: row))

        let lineFrame = line.convert(line.bounds, to: card)
        let rowFrame = row.convert(row.bounds, to: card)
        let iconFrame = icon.convert(icon.bounds, to: card)

        XCTAssertEqual(
            lineFrame.minX,
            rowFrame.minX + UX.separatorLeadingInset,
            accuracy: 0.5,
            "Expected the line to start at the leading inset"
        )
        XCTAssertEqual(
            lineFrame.maxX,
            rowFrame.maxX - UX.separatorTrailingInset,
            accuracy: 0.5,
            "Expected the line to stop short of the row's trailing edge"
        )
        XCTAssertGreaterThanOrEqual(
            lineFrame.minX,
            iconFrame.maxX + UX.rowHorizontalSpacing,
            "Expected the line to start no earlier than the title text"
        )
    }

    private func backgroundGradientView(in controller: UIViewController) -> GradientView? {
        // The only `GradientView` directly under the root view; the progress bars' fills sit deeper.
        return controller.view.subviews.compactMap { $0 as? GradientView }.first
    }

    /// Each separator is a transparent container holding the inset line, so the line is one level down.
    private func separators(in controller: UIViewController) -> [UIView] {
        guard let card = view(controller, withID: A11y.categoriesCard),
              let stack = allSubviews(in: card).compactMap({ $0 as? UIStackView }).first else { return [] }
        return stack.arrangedSubviews
            .filter { !($0 is TrackerCategoryRowView) }
            .compactMap { $0.subviews.first }
    }

    // MARK: - Helpers

    /// Mirrors the private `TrackerCategoryRowView.UX` and sheet `UX` values the layout assertions depend on.
    private enum UX {
        static let rowWidth: CGFloat = 320
        static let rowVerticalPadding: CGFloat = 12
        static let rowHorizontalSpacing: CGFloat = 12
        static let emptyStateMinHeight: CGFloat = 55
        static let sheetWidth: CGFloat = 393
        static let sheetHeight: CGFloat = 700
        static let cardTopPadding: CGFloat = 16
        static let cardBottomPadding: CGFloat = 12
        static let separatorLeadingInset: CGFloat = 49
        static let separatorTrailingInset: CGFloat = 10
        static let formSheetWidth: CGFloat = 525
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

    private func createSubject(state: TrackerBlockerSheetState = .filled,
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

    private func categoriesCard(in controller: UIViewController) -> UIView? {
        return view(controller, withID: A11y.categoriesCard)
    }

    private func view(_ controller: UIViewController, withID identifier: String) -> UIView? {
        return allSubviews(in: controller.view).first { $0.accessibilityIdentifier == identifier }
    }

    private func allSubviews(in view: UIView) -> [UIView] {
        return view.subviews + view.subviews.flatMap { allSubviews(in: $0) }
    }
}

/// Sample data for the states the sheet can show. Only the empty state exists in the app itself
/// (`TrackerBlockerSheetState.empty`); the populated ones live here until real data is wired up.
private extension TrackerBlockerSheetState {
    /// Trackers were blocked this week, with a lifetime total in the footer.
    static var filled: TrackerBlockerSheetState {
        TrackerBlockerSheetState(
            weeklyCount: 2195,
            emptyMessage: nil,
            categories: [
                Category(kind: .crossSiteTrackingCookies, count: 1999),
                Category(kind: .fingerprinters, count: 101),
                Category(kind: .trackingContent, count: 90),
                Category(kind: .socialMediaTrackers, count: 5)
            ],
            total: Total(count: 43251, sinceDate: "02/13/26")
        )
    }

    /// The week has just rolled over: the bars are empty but the lifetime total remains.
    static var weeklyReset: TrackerBlockerSheetState {
        TrackerBlockerSheetState(
            weeklyCount: 0,
            emptyMessage: nil,
            categories: Category.Kind.allCases.map { Category(kind: $0, count: 0) },
            total: Total(count: 5305, sinceDate: "02/13/26")
        )
    }

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
