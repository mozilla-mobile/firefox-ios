// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest
import WebKit

class SearchPrefsMigrationTests: XCTestCase {
    private let mockV1Prefs: SearchEngineOrderingPrefs = {
        let engines = ["Google", "Custom", "Wikipedia", "DuckDuckGo"]
        return SearchEngineOrderingPrefs(engineIdentifiers: engines, version: .v1)
    }()

    private let mockV2Prefs: SearchEngineOrderingPrefs = {
        let engines = ["google", "Custom", "wikipedia", "duckduckgo"]
        return SearchEngineOrderingPrefs(engineIdentifiers: engines, version: .v2)
    }()

    private let mockRemoteSettingsEngines: [OpenSearchEngine] = [
        OpenSearchEngine(
            engineID: "google",
            shortName: "Google",
            image: UIImage(),
            searchTemplate: "",
            suggestTemplate: "",
            isCustomEngine: false
        ),
        OpenSearchEngine(
            engineID: "ddg",
            shortName: "DuckDuckGo",
            image: UIImage(),
            searchTemplate: "",
            suggestTemplate: "",
            isCustomEngine: false
        ),
        OpenSearchEngine(
            engineID: "wikipedia",
            shortName: "Wikipedia (en)",
            image: UIImage(),
            searchTemplate: "",
            suggestTemplate: "",
            isCustomEngine: false
        ),
        OpenSearchEngine(
            engineID: "Custom-1234-1234-1234-1234",
            shortName: "Custom",
            image: UIImage(),
            searchTemplate: "",
            suggestTemplate: "",
            isCustomEngine: true
        ),
    ]

    func testMigrateV1toV2Preferences() async throws {
        let migrator = createSubject()
        let prefs = mockV1Prefs
        let output = migrator.migratePrefsIfNeeded(prefs, to: .v2, availableEngines: mockRemoteSettingsEngines)

        XCTAssertEqual(output.version, .v2)
        XCTAssertEqual(output.engineIdentifiers, ["google", "Custom-1234-1234-1234-1234", "wikipedia", "ddg"])
    }

    private func createSubject() -> DefaultSearchEnginePrefsMigrator {
        return DefaultSearchEnginePrefsMigrator(logger: MockLogger())
    }
}
