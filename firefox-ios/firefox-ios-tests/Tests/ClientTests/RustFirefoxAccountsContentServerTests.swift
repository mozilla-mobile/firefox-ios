// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Shared
import XCTest

/// `contentServerURL(prefs:)` decides which origin the pairing URL parser treats as ours, so each
/// server-selection branch is asserted directly.
final class RustFirefoxAccountsContentServerTests: XCTestCase {
    private let release = URL(string: "https://accounts.firefox.com")
    private let stage = URL(string: "https://accounts.stage.mozaws.net")
    private let stableDev = URL(string: "https://stable.dev.lcip.org")

    func testReturnsReleaseServerByDefault() {
        XCTAssertEqual(RustFirefoxAccounts.contentServerURL(prefs: MockProfilePrefs()), release)
    }

    func testReturnsReleaseServerWhenPrefsAreMissing() {
        XCTAssertEqual(RustFirefoxAccounts.contentServerURL(prefs: nil), release)
    }

    func testReturnsStageServerWhenStagePrefIsSet() {
        let prefs = MockProfilePrefs()
        prefs.setInt(1, forKey: PrefsKeys.UseStageServer)

        XCTAssertEqual(RustFirefoxAccounts.contentServerURL(prefs: prefs), stage)
    }

    func testReturnsCustomServerWhenCustomContentServerIsEnabled() {
        let prefs = MockProfilePrefs()
        prefs.setBool(true, forKey: PrefsKeys.KeyUseCustomFxAContentServer)
        prefs.setString("http://localhost:3030", forKey: PrefsKeys.KeyCustomFxAContentServer)

        XCTAssertEqual(RustFirefoxAccounts.contentServerURL(prefs: prefs), URL(string: "http://localhost:3030"))
    }

    /// The custom pref wins over the stage pref, matching `createAccountManager`'s ordering.
    func testCustomServerTakesPrecedenceOverStage() {
        let prefs = MockProfilePrefs()
        prefs.setInt(1, forKey: PrefsKeys.UseStageServer)
        prefs.setBool(true, forKey: PrefsKeys.KeyUseCustomFxAContentServer)
        prefs.setString("http://localhost:3030", forKey: PrefsKeys.KeyCustomFxAContentServer)

        XCTAssertEqual(RustFirefoxAccounts.contentServerURL(prefs: prefs), URL(string: "http://localhost:3030"))
    }

    func testFallsBackToStableDevWhenCustomServerIsEnabledWithoutAValue() {
        let prefs = MockProfilePrefs()
        prefs.setBool(true, forKey: PrefsKeys.KeyUseCustomFxAContentServer)

        XCTAssertEqual(RustFirefoxAccounts.contentServerURL(prefs: prefs), stableDev)
    }

    func testUsesStableDevWhenOnlyTheTokenServerIsOverridden() {
        let prefs = MockProfilePrefs()
        prefs.setBool(true, forKey: PrefsKeys.KeyUseCustomSyncTokenServerOverride)

        XCTAssertEqual(RustFirefoxAccounts.contentServerURL(prefs: prefs), stableDev)
    }

    /// `createAccountManager` selects `FxAConfig.Server.china`, which app-services maps to its own
    /// host, so the parser must agree or a genuine China pairing link is treated as a normal URL.
    func testReturnsChinaServerWhenChinaSyncIsEnabled() {
        let prefs = MockProfilePrefs()
        prefs.setBool(true, forKey: PrefsKeys.KeyEnableChinaSyncService)

        XCTAssertEqual(
            RustFirefoxAccounts.contentServerURL(prefs: prefs),
            URL(string: "https://accounts.firefox.com.cn")
        )
    }

    /// `createAccountManager` checks the stage pref before the China pref, so this must too.
    func testStageTakesPrecedenceOverChina() {
        let prefs = MockProfilePrefs()
        prefs.setInt(1, forKey: PrefsKeys.UseStageServer)
        prefs.setBool(true, forKey: PrefsKeys.KeyEnableChinaSyncService)

        XCTAssertEqual(RustFirefoxAccounts.contentServerURL(prefs: prefs), stage)
    }

    func testCustomServerTakesPrecedenceOverChina() {
        let prefs = MockProfilePrefs()
        prefs.setBool(true, forKey: PrefsKeys.KeyEnableChinaSyncService)
        prefs.setBool(true, forKey: PrefsKeys.KeyUseCustomFxAContentServer)
        prefs.setString("http://localhost:3030", forKey: PrefsKeys.KeyCustomFxAContentServer)

        XCTAssertEqual(RustFirefoxAccounts.contentServerURL(prefs: prefs), URL(string: "http://localhost:3030"))
    }

    /// An unparseable custom value must fail closed rather than resolve to some other live server,
    /// so the pairing parser rejects every URL instead of trusting the wrong origin.
    func testReturnsNilForAnUnparseableCustomServer() {
        let prefs = MockProfilePrefs()
        prefs.setBool(true, forKey: PrefsKeys.KeyUseCustomFxAContentServer)
        prefs.setString("http://my server", forKey: PrefsKeys.KeyCustomFxAContentServer)

        XCTAssertNil(RustFirefoxAccounts.contentServerURL(prefs: prefs))
    }
}
