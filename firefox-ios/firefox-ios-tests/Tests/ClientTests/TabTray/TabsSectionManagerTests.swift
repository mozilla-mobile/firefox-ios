// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
final class TabsSectionManagerTests: XCTestCase {
    struct DeviceSize {
        static let iPhoneDuoExpandedPortrait = CGSize(width: 669, height: 951)
        static let iPhoneDuoExpandedLandscape = CGSize(width: 951, height: 669)
        static let iPhoneProMaxPortrait = CGSize(width: 440, height: 956)
        static let iPhoneProMaxLandscape = CGSize(width: 956, height: 440)
        static let iPadPortrait = CGSize(width: 1024, height: 1366)
    }

    // MARK: - numberOfCellsPerRow

    func test_numberOfCellsPerRow_expandedPhonePortrait_showsThreeColumns() {
        let environment = createEnvironment(size: DeviceSize.iPhoneDuoExpandedPortrait,
                                            idiom: .phone,
                                            horizontalSizeClass: .regular,
                                            verticalSizeClass: .regular)

        XCTAssertEqual(createSubject().numberOfCellsPerRow(for: environment), 3)
    }

    func test_numberOfCellsPerRow_expandedPhoneLandscape_showsThreeColumns() {
        let environment = createEnvironment(size: DeviceSize.iPhoneDuoExpandedLandscape,
                                            idiom: .phone,
                                            horizontalSizeClass: .regular,
                                            verticalSizeClass: .regular)

        XCTAssertEqual(createSubject().numberOfCellsPerRow(for: environment), 3)
    }

    func test_numberOfCellsPerRow_proMaxPortrait_showsTwoColumns() {
        let environment = createEnvironment(size: DeviceSize.iPhoneProMaxPortrait,
                                            idiom: .phone,
                                            horizontalSizeClass: .compact,
                                            verticalSizeClass: .regular)

        XCTAssertEqual(createSubject().numberOfCellsPerRow(for: environment), 2)
    }

    func test_numberOfCellsPerRow_proMaxLandscape_usesCompactCellWidth() {
        let environment = createEnvironment(size: DeviceSize.iPhoneProMaxLandscape,
                                            idiom: .phone,
                                            horizontalSizeClass: .regular,
                                            verticalSizeClass: .compact)

        XCTAssertEqual(createSubject().numberOfCellsPerRow(for: environment), 5)
    }

    func test_numberOfCellsPerRow_iPad_usesRegularCellWidth() {
        let environment = createEnvironment(size: DeviceSize.iPadPortrait,
                                            idiom: .pad,
                                            horizontalSizeClass: .regular,
                                            verticalSizeClass: .regular)

        XCTAssertEqual(createSubject().numberOfCellsPerRow(for: environment), 4)
    }

    // MARK: - leadingInset

    func test_leadingInset_proMaxLandscape_usesStandardInset() {
        let traitCollection = createTraitCollection(idiom: .phone,
                                                    horizontalSizeClass: .regular,
                                                    verticalSizeClass: .compact)

        XCTAssertEqual(TabsSectionManager.leadingInset(traitCollection: traitCollection),
                       TabsSectionManager.UX.standardInset)
    }

    func test_leadingInset_regularLayout_usesIPadInset() {
        let traitCollection = createTraitCollection(idiom: .phone,
                                                    horizontalSizeClass: .regular,
                                                    verticalSizeClass: .regular)

        XCTAssertEqual(TabsSectionManager.leadingInset(traitCollection: traitCollection),
                       TabsSectionManager.UX.iPadInset)
    }

    // MARK: - Helpers

    private func createTraitCollection(idiom: UIUserInterfaceIdiom,
                                       horizontalSizeClass: UIUserInterfaceSizeClass,
                                       verticalSizeClass: UIUserInterfaceSizeClass) -> UITraitCollection {
        return UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: idiom),
            UITraitCollection(horizontalSizeClass: horizontalSizeClass),
            UITraitCollection(verticalSizeClass: verticalSizeClass)
        ])
    }

    private func createEnvironment(size: CGSize,
                                   idiom: UIUserInterfaceIdiom,
                                   horizontalSizeClass: UIUserInterfaceSizeClass,
                                   verticalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutEnvironment {
        let traitCollection = createTraitCollection(idiom: idiom,
                                                    horizontalSizeClass: horizontalSizeClass,
                                                    verticalSizeClass: verticalSizeClass)
        return MockLayoutEnvironment(container: MockLayoutContainer(size: size), traitCollection: traitCollection)
    }

    private func createSubject() -> TabsSectionManager {
        return TabsSectionManager()
    }
}

private final class MockLayoutContainer: NSObject, NSCollectionLayoutContainer {
    let contentSize: CGSize
    let effectiveContentSize: CGSize
    let contentInsets: NSDirectionalEdgeInsets = .zero
    let effectiveContentInsets: NSDirectionalEdgeInsets = .zero

    init(size: CGSize) {
        contentSize = size
        effectiveContentSize = size
    }
}

private final class MockLayoutEnvironment: NSObject, NSCollectionLayoutEnvironment {
    let container: NSCollectionLayoutContainer
    let traitCollection: UITraitCollection

    init(container: NSCollectionLayoutContainer, traitCollection: UITraitCollection) {
        self.container = container
        self.traitCollection = traitCollection
    }
}
