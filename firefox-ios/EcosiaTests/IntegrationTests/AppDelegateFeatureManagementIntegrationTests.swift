// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
@testable import Ecosia

final class AppDelegateFeatureManagementIntegrationTests: XCTestCase {
    var appDelegate: AppDelegate!
    var initialModel: Unleash.Model!

    override func setUp() {
        super.setUp()

        appDelegate = AppDelegate()
        DependencyHelperMock().bootstrapDependencies()
        initialModel = Unleash.model
        // Reset Unleash model to initial state
        Unleash.model = Unleash.Model()
    }

    func testInitialStateOfUnleashModel() {
        XCTAssertEqual(Unleash.model.toggles.count, 0)
        XCTAssertEqual(Unleash.model.updated, Date(timeIntervalSince1970: 0))
    }

    func testStateAfterDidFinishLaunchingWithOptions_expectsModelUpdates() async {
        let application = await UIApplication.shared
        let options: [UIApplication.LaunchOptionsKey: Any]? = nil

        // Store an updated model so to not let Unleash perform a call
        await storeUnleashModel()

        let didFinishLaunching = await appDelegate.application(application, didFinishLaunchingWithOptions: options)

        XCTAssertTrue(didFinishLaunching)
        // Let it go thru all the activities, including the Task detached ones
        wait(1)
        XCTAssertNotEqual(Unleash.model.updated, Date(timeIntervalSince1970: 0))
        XCTAssertNotEqual(Unleash.model.toggles.count, 0)
    }

    func testStateAfterDidBecomeActive_expectesSameModel_AfterDidFinishLaunchingWithOptions() async {
        let application = await UIApplication.shared

        // Store an updated model so to not let Unleash perform a call
        await storeUnleashModel()

        // Simulate didFinishLaunchingWithOptions
        let options: [UIApplication.LaunchOptionsKey: Any]? = nil
        let didFinishLaunching = await appDelegate.application(application, didFinishLaunchingWithOptions: options)

        XCTAssertTrue(didFinishLaunching)
        // Let it go thru all the activities, including the Task detached ones
        wait(1)
        let modelAfterLaunch = Unleash.model

        // Simulate entering background and foreground again
        await appDelegate.applicationDidBecomeActive(application)

        wait(1)
        XCTAssertEqual(Unleash.model.toggles.count, modelAfterLaunch.toggles.count)
        XCTAssertEqual(Unleash.model.updated, modelAfterLaunch.updated)
    }
}

extension AppDelegateFeatureManagementIntegrationTests {

    func storeUnleashModel() async {
        let jsonString =
        """
        {
          "appVersion": "10.0.0",
          "updated": 743349796.463453,
          "id": "626C1D87-975E-4CC6-9397-1137AF7F7637",
          "deviceRegion": "us",
          "etag": "example-etag",
          "toggles": [
            {
              "variant": {
                "name": "disabled",
                "enabled": false
              },
              "name": "example_toggle",
              "enabled": true
            }
          ]
        }
        """
        let decoder = JSONDecoder()
        let model = try? decoder.decode(Unleash.Model.self, from: jsonString.data(using: .utf8)!)
        try? await Unleash.save(model!)
    }
}
