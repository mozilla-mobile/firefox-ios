// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest
import WebKit

class SearchPrefsMigrationTests: XCTestCase {
    private let mockV1Prefs: SearchEnginePrefs = {
        let engines = ["Google", "MyWebsite", "Wikipedia", "DuckDuckGo"]
        let disabled = ["Wikipedia"]
        return SearchEnginePrefs(engineIdentifiers: engines,
                                 disabledEngines: disabled,
                                 version: .v1)
    }()

    private let mockV2Prefs: SearchEnginePrefs = {
        let engines = ["google", "Custom-1234-1234-1234-1234", "wikipedia", "duckduckgo"]
        let disabled = ["wikipedia"]
        return SearchEnginePrefs(engineIdentifiers: engines,
                                 disabledEngines: disabled,
                                 version: .v2)
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
            shortName: "MyWebsite",
            image: UIImage(),
            searchTemplate: "",
            suggestTemplate: "",
            isCustomEngine: true
        ),
    ]

    private let mockXMLBasedEngines: [OpenSearchEngine] = [
        OpenSearchEngine(
            engineID: "google-b-1-m",
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
            shortName: "Wikipedia",
            image: UIImage(),
            searchTemplate: "",
            suggestTemplate: "",
            isCustomEngine: false
        ),
        OpenSearchEngine(
            engineID: "Custom-1234-1234-1234-1234",
            shortName: "MyWebsite",
            image: UIImage(),
            searchTemplate: "",
            suggestTemplate: "",
            isCustomEngine: true
        ),
    ]

    func testMigrateV1toV2Preferences() {
        let migrator = createSubject()
        let prefs = mockV1Prefs
        let output = migrator.migratePrefsIfNeeded(prefs, to: .v2, availableEngines: mockRemoteSettingsEngines)

        XCTAssertEqual(output.version, .v2)
        XCTAssertEqual(output.engineIdentifiers, ["google", "Custom-1234-1234-1234-1234", "wikipedia", "ddg"])
        XCTAssertEqual(output.disabledEngines, ["wikipedia"])
    }

    func testMigrateV2toV1Preferences() {
        let migrator = createSubject()
        let prefs = mockV2Prefs
        let output = migrator.migratePrefsIfNeeded(prefs, to: .v1, availableEngines: mockXMLBasedEngines)

        XCTAssertEqual(output.version, .v1)
        // Note: currently handling for v2 -> v1 migration is TBD, so aspects of this are in flux.
        XCTAssertEqual(output.engineIdentifiers, ["Google", "MyWebsite", "Wikipedia", "DuckDuckGo"])
        XCTAssertEqual(output.disabledEngines, ["Wikipedia"])
    }

    private func createSubject() -> DefaultSearchEnginePrefsMigrator {
        return DefaultSearchEnginePrefsMigrator(logger: MockLogger())
    }
}
