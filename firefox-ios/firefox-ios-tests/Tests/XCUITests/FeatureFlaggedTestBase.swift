// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

/// Provides utilities to enable experiments and feature flags for specific test cases within a test class.
///
/// See also:
/// https://github.com/mozilla-mobile/firefox-ios/wiki/Automated-UI-Tests#experiments--feature-flags
class FeatureFlaggedTestBase: BaseTestCase {
    override func setUpApp() {
        // Important: `app.launch()` must be called explicitly in each test case.
        setUpLaunchArguments()
    }

    /// Adds experiment data and feature flag information to the app's launch arguments.
    ///
    /// - Parameters:
    ///   - jsonFileName: The name of the JSON file containing experiment configurations.
    ///   - featureName: The feature name as defined in the Nimbus feature YAML file,
    ///                  written in kebab-case under the `features:` section.
    func addLaunchArgument(jsonFileName: String, featureName: String) {
        var launchArgs = app.launchArguments
        launchArgs.append("\(LaunchArguments.LoadExperiment)\(jsonFileName)")
        launchArgs.append("\(LaunchArguments.ExperimentFeatureName)\(featureName)")
        app.launchArguments = launchArgs
        launchArguments = launchArgs + launchArguments
    }
}

/// Provides utilities to enable experiments and feature flags for an entire test class.
/// Use this when *all* tests in the class require the same experiment and feature flag.
///
/// See also:
/// https://github.com/mozilla-mobile/firefox-ios/wiki/Automated-UI-Tests#experiments--feature-flags
class FeatureFlaggedTestSuite: FeatureFlaggedTestBase {
    /// Set these variables inside the `setUpExperimentVariables()` method.
    var jsonFileName: String!
    var featureName: String!

    override func setUpApp() {
        addLaunchArgument(jsonFileName: jsonFileName, featureName: featureName)
    }

    override func setUp() {
        continueAfterFailure = false
        setUpExperimentVariables()
        setUpApp()
        setUpLaunchArguments()
        setUpScreenGraph()
    }

    // Important: `launchApp` must be called explicitly in each test case.
    func launchApp() {
        app.launch()
        mozWaitForElementToExist(app.windows.otherElements.firstMatch)
    }
}
