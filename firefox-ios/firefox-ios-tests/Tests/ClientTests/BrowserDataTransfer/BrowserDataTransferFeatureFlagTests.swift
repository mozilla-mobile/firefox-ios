// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest

@testable import Client

@MainActor
final class BrowserDataTransferFeatureFlagTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
    }

    override func tearDown() async throws {
        FxNimbus.shared.features.browserDataTransferFeature.with { variables, prefs in
            BrowserDataTransferFeature(variables, prefs)
        }
        try await super.tearDown()
    }

    func testNimbusDefaults_matchBuildChannel() {
        let feature = BrowserDataTransferFeature()

        #if MOZ_CHANNEL_release
        XCTAssertFalse(feature.importEnabled)
        XCTAssertFalse(feature.exportEnabled)
        #else
        XCTAssertTrue(feature.importEnabled)
        XCTAssertTrue(feature.exportEnabled)
        #endif
    }

    func testNimbusLayer_readsEachVariableIndependently() {
        let layer = NimbusFeatureFlagLayer()
        let prefs = MockProfilePrefs()

        FxNimbus.shared.features.browserDataTransferFeature.with { _, _ in
            BrowserDataTransferFeature(exportEnabled: false, importEnabled: true)
        }
        XCTAssertTrue(layer.checkNimbusConfigFor(.browserDataImport, with: prefs))
        XCTAssertFalse(layer.checkNimbusConfigFor(.browserDataExport, with: prefs))

        FxNimbus.shared.features.browserDataTransferFeature.with { _, _ in
            BrowserDataTransferFeature(exportEnabled: true, importEnabled: false)
        }
        XCTAssertFalse(layer.checkNimbusConfigFor(.browserDataImport, with: prefs))
        XCTAssertTrue(layer.checkNimbusConfigFor(.browserDataExport, with: prefs))
    }

    func testDebugOverride_appliesToOneDirection() throws {
        let prefs = MockProfilePrefs()
        let layer = NimbusFeatureFlagLayer()
        FxNimbus.shared.features.browserDataTransferFeature.with { _, _ in
            BrowserDataTransferFeature(exportEnabled: true, importEnabled: true)
        }
        let importDebugKey = try XCTUnwrap(FeatureFlagID.browserDataImport.debugKey)
        prefs.setBool(false, forKey: importDebugKey)

        #if MOZ_CHANNEL_beta || MOZ_CHANNEL_developer
        XCTAssertFalse(layer.checkNimbusConfigFor(.browserDataImport, with: prefs))
        #else
        XCTAssertTrue(layer.checkNimbusConfigFor(.browserDataImport, with: prefs))
        #endif
        XCTAssertTrue(layer.checkNimbusConfigFor(.browserDataExport, with: prefs))
    }
}
