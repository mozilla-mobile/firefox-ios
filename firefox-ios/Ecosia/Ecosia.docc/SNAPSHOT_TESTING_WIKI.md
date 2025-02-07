# 📸 Snapshot Testing Library

The SnapshotTesting library is a Swift package that allows you to capture screenshots of iOS views and compare them over time, ensuring your UI does not change unexpectedly. It is highly effective in preventing visual regressions during development.
[Repo link](https://github.com/pointfreeco/swift-snapshot-testing?tab=readme-ov-file)

## SnapshotTestHelper

SnapshotTestHelper is a utility class designed to facilitate snapshot testing across different UI themes, device configurations, and locales for both UIView and UIViewController. It abstracts complex snapshot configurations and provides a simplified API for performing localized snapshot tests.

### Key Functions a.k.a. what happens under the hood 👀

#### performSnapshot

- **Purpose**: Executes the snapshot test with specified configurations.
- **Parameters**:
  - `initializer`: A closure that returns the UI component to be tested.
  - `locales`: An array of locales to test the component in different languages.
  - `wait`: Duration to wait before taking the snapshot, allowing UI to stabilize.
  - `precision`: The accuracy of the snapshot comparison.
  - `file`, `testName`, `line`: Standard XCTest parameters for identifying the test source.

The device name, orientation, and locales of the current test run are retrieved from the `environment.json` file.

#### assertSnapshot

- **Purpose**: Public interfaces for asserting snapshots of UIView and UIViewController.
- **Parameters**:
  - Includes parameters for initializing content, device simulation, locale settings, and test configurations.

#### setLocale

- **Purpose**: Sets the application’s locale to simulate different languages.
- **Implementation Details**: Updates the UserDefaults to reflect the chosen locale and swaps the main Bundle to use localized resources.

#### setupContent

- **Purpose**: Configures the UIWindow with the content to be snapshot.
- **Details**: Adds the content to the window, sets appropriate bounds, and ensures it is ready for display and snapshotting.

### Snapshot Testing Configuration

This JSON configuration is designed for automated snapshot testing of an iOS application. It defines the locales, devices, and specific test plans that should be used during the snapshot tests.

#### Breakdown of the JSON Structure:

#### 1. Locales (`"locales"`)
This array lists all the language locales that the app will be tested in. In this example, the locales are:
- English (`"en"`)
- Italian (`"it"`)
- German (`"de"`)
- Spanish (`"es"`)
- Dutch (`"nl"`)

#### 2. Devices (`"devices"`)
This array specifies the devices on which the snapshot tests will be executed. Each device entry includes:
- **`"name"`**: The name of the device (e.g., `"iPhone SE (2nd generation)"`).
- **`"orientation"`**: The orientation in which the device should be tested (e.g., `"portrait"` or `"landscape"`).
- **`"os"`**: The operating system version to simulate (e.g., `"17.5"`). If `"os"` is not specified, the default would be used.
> Make sure the devices you are going to list down are present or available in the machine you are going to run the tests.

#### 3. Test Bundles (`"testBundles"`)
This array defines the test bundles, which are groups of tests to be executed under the specified configurations. Each test plan contains:
- **`"name"`**: The name of the test bundle (e.g., `"EcosiaSnapshotTests"`).
- **`"testClasses"`**: An array of test classes to be executed within this plan. Each test class includes:
  - **`"name"`**: The name of the test class (e.g., `"OnboardingTests"`).
  - **`"devices"`**: An array specifying the devices this test class should run on. If `"all"` is specified, the test will run on all devices listed in the `"devices"` section.
  - **`"locales"`**: An array specifying the locales this test class should be tested in. If `"all"` is specified, the test will run in all locales listed in the `"locales"` section.

#### Purpose

This JSON file configures the settings for automated snapshot tests, which involve capturing screenshots of the app’s UI to ensure it looks correct across various devices and locales.

- **Locales**: Helps ensure that the app displays correctly in multiple languages.
- **Devices**: Ensures that the UI is responsive and correctly rendered on different screen sizes and orientations.
- **Test Plans**: Organizes which tests should run on which devices and in which locales, allowing for comprehensive testing without manually configuring each test.

This configuration is typically consumed by a script or a test runner that uses this information to execute the specified tests, taking screenshots of the app's UI in the defined scenarios and comparing them to reference images to detect any unintended changes.

### Localization Support 🗣️

SnapshotTestHelper can perform snapshots in various languages by dynamically setting the application’s locale before rendering the UI. This is particularly useful for apps supporting multiple languages, ensuring that all localized strings appear correctly in the UI across different device configurations.

### Example Usage

#### Testing a UIViewController (Welcome Screen)

```swift
func testWelcomeScreen() {
    SnapshotTestHelper.assertSnapshot(initializingWith: {
        Welcome(delegate: MockWelcomeDelegate())
    }, wait: 1.0)
}
```

This test initializes a Welcome view controller with a mock delegate and asserts its appearance in English by default against an iPhone12Pro form factor in portrait mode.

#### Testing a UIView (NTPLogoCell)

```swift
func testNTPLogoCell() {
    SnapshotTestHelper.assertSnapshot(initializingWith: {
        NTPLogoCell(frame: CGRect(x: 0, y: 0, width: self.commonWidth, height: 100))
    })
}
```

This test captures a snapshot of the NTPLogoCell, a custom view, to ensure its visual layout remains consistent across updates.

This documentation should help developers understand how to leverage SnapshotTestHelper for comprehensive UI testing, including handling different themes, devices, and languages.

### FAQ ⁉️

<details>
<summary> What if I want to test on different devices? </summary>

To perform snapshot tests on different devices, you can specify the devices as part of the `snapshot_configuration.json`.
SnapshotTestHelper will take care of retrieving all the details and configure the test environment to simulate the screen size and resolution of the specified devices.

**Example:**
```json
{
  "locales": [
    "en",
    "it",
    "de",
    "es",
    "nl"
  ],
  "devices": [
    {
      "name": "iPhone SE (3rd generation)",
      "orientation": "portrait",
      "os": "17.5"
    },
    {
      "name": "iPhone 15 Pro",
      "orientation": "portrait",
      "os": "17.5",
      "isDefaultTestDevice": true
    },
    {
      "name": "iPhone 15 Pro Max",
      "orientation": "landscape"
    },
    {
      "name": "iPad Pro (12.9-inch) (6th generation)",
      "orientation": "portrait"
    }
  ],
  "testBundles": [
    {
      "name": "EcosiaSnapshotTests",
      "testClasses": [
        {
          "name": "OnboardingTests",
          "devices": ["all", "portrait"],
          "locales": ["all"]
        },
        {
          "name": "NTPComponentTests",
          "devices": ["iPhone 15 Pro"],
          "locales": ["all"]
        }
      ]
    }
  ]
}
```

This configuration executes the `OnboardingTests` class which is part of the `EcosiaSnapshotTests` on both an iPhone SE and iPad Pro in portrait mode for the English and Spanish languages.
</details>

<details>
<summary> What if I want to test with different languages? </summary>

To perform snapshot tests on different locales, you can specify the devices as part of the `snapshot_configuration.json`. All available locales are declared in the `locales` array.
SnapshotTestHelper will take care of retrieving all the details and configure the test environment to the specified languages.

```json
{
  "locales": [
    "en",
    "it",
    "de",
    "es",
    "nl"
  ],
  "devices": [
    {
      "name": "iPhone SE (3rd generation)",
      "orientation": "portrait",
      "os": "17.5"
    },
    {
      "name": "iPhone 15 Pro",
      "orientation": "portrait",
      "os": "17.5",
      "isDefaultTestDevice": true
    },
    {
      "name": "iPhone 15 Pro Max",
      "orientation": "landscape"
    },
    {
      "name": "iPad Pro (12.9-inch) (6th generation)",
      "orientation": "portrait"
    }
  ],
  "testBundles": [
    {
      "name": "EcosiaSnapshotTests",
      "testClasses": [
        {
          "name": "OnboardingTests",
          "devices": [
            "iPhone SE (2nd generation)", 
            "iPad Pro (12.9-inch) (4th generation)"
            ],
          "locales": [
            "en", 
            "it",
            "es"
            ]
        },
        {
          "name": "NTPComponentTests",
          "devices": ["iPhone 15 Pro"],
          "locales": ["all"]
        }
      ]
    }
  ]
}
```

This configuration executes the `OnboardingTests` class which is part of the `EcosiaSnapshotTests` on both an iPhone SE and iPad Pro in portrait mode for the English, Italian and Spanish languages.
</details>

<details>
<summary> What if I want to add another device in landscape orientation? </summary>

Here’s how you can add a device in landscape orientation:

In your DeviceType enum, ensure you have a landscape configuration set up for the device:

```swift
enum DeviceType: String, CaseIterable {
    case iPhone12Pro_Portrait
    case iPhone12Pro_Landscape // Define the landscape configuration

    var config: ViewImageConfig {
        switch self {
        case .iPhone12Pro_Portrait:
            return ViewImageConfig.iPhone12Pro(.portrait)
        case .iPhone12Pro_Landscape:
            return ViewImageConfig.iPhone12Pro(.landscape)
        }
    }

    static func from(deviceName: String, orientation: String) -> DeviceType {
        switch (deviceName, orientation) {
        case ("iPhone 12 Pro", "portrait"):
            return .iPhone12Pro_Portrait
        case ("iPhone 12 Pro", "landscape"):
            return .iPhone12Pro_Landscape
        default:
            fatalError("Device Name \(deviceName) and Orientation \(orientation) not found. Please add them correctly.")
        }
    }
}
```

Do not forget to also declare the new device in the `snapshot_configuration.json` as well 👇

```json
{
  "locales": [
    "en",
    "it",
    "de",
    "es",
    "nl"
  ],
  "devices": [
    {
      "name": "iPhone SE (2nd generation)",
      "orientation": "portrait",
      "os": "17.5"
    },
    {
      "name": "iPhone 12 Pro",
      "orientation": "landscape",
      "os": "17.5"
    }
    ...
  ],
  "testBundles": [
    {
      "name": "EcosiaSnapshotTests",
      "testClasses": [
        {
          "name": "OnboardingTests",
          "devices": ["all"],
          "locales": ["all"]
        }
        ...
      ]
    }
  ]
}
```
</details>

<details>
<summary> What if I want to perform a certain test class against all devices in portrait orientation? </summary>

You can specify the requirements as part of the devices list of that test class. The script will take care of selecting only the devices matching the desired orientation.

```json
{
  "locales": [
    "en",
    "it",
    "de",
    "es",
    "nl"
  ],
  "devices": [
    {
      "name": "iPhone SE (2nd generation)",
      "orientation": "portrait",
      "os": "17.5"
    },
    {
      "name": "iPhone 15 Pro",
      "orientation": "portrait",
      "os": "17.5"
    },
    {
      "name": "iPhone 12 Pro",
      "orientation": "landscape",
      "os": "17.5"
    }
    ...
  ],
  "testBundles": [
    {
      "name": "EcosiaSnapshotTests",
      "testClasses": [
        {
          "name": "OnboardingTests",
          "devices": ["all", "portrait"],
          "locales": ["all"]
        }
        ...
      ]
    }
  ]
}
```

</details>

<details>
<summary> How does the compare logic work? </summary>

The SnapshotTesting library captures screenshots of your UI components and compares these images against reference images stored in your project. If a reference image does not exist, it is created on the first run, meaning the initial test will always “pass” by creating the needed baseline images.

On subsequent test runs, the newly captured snapshot is compared pixel by pixel against the reference image. If differences are detected beyond the specified precision threshold, the test fails, and the differences can be reviewed visually in Xcode. This helps identify unintended changes or regressions in the UI layout and appearance.

</details>

### Key Points 🎯:

- Reference images are stored in your project directory under a folder typically named __Snapshots__.
- The precision parameter allows for control over how exact the comparison needs to be, accommodating minor rendering differences across environments.
- Failed tests will provide a visual diff image showing highlighted differences between the reference and the test snapshots.