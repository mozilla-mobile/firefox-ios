import XCTest

class TabsPerformanceTest: BaseTestCase {

    let fixtures = ["testPerfTabs_1_20startup": "tabsState20.archive", "testPerfTabs_3_20tabTray": "tabsState20.archive", "testPerfTabs_2_1280startup": "tabsState1280.archive", "testPerfTabs_4_1280tabTray": "tabsState1280.archive"]

    override func setUp() {
        // Test name looks like: "[Class testFunc]", parse out function name
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let functionName = String(parts[1])
        let archiveName = fixtures[functionName]

        // defaults
        launchArguments = [LaunchArguments.PerformanceTest, LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, LaunchArguments.SkipETPCoverSheet]

        // append specific load profiles to LaunchArguments
        if fixtures.keys.contains(functionName) {
            launchArguments.append(LaunchArguments.LoadTabsStateArchive + archiveName!)
        }
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // This test run first to install the app in the device
    func testAppStart() {
        app.launch()
    }

    // 1 perf test per tabsStateArchive of size: 20, 1280
    // Taking the edges, low and high load. For more values in the middle
    // check the available archives
    func testPerfTabs_1_20startup() {
        if #available(iOS 13.0, *) {
            measure(metrics: [
                XCTMemoryMetric(),
                XCTClockMetric(), // to measure timeClock Mon
                XCTCPUMetric(), // to measure cpu cycles
                XCTStorageMetric(), // to measure storage consuming
                XCTMemoryMetric()]) {
                // activity measurement here
                app.launch()
            }
        }
    }

    func testPerfTabs_2_1280startup() {
        if #available(iOS 13.0, *) {
            measure(metrics: [
                XCTMemoryMetric(),
                XCTClockMetric(), // to measure timeClock Mon
                XCTCPUMetric(), // to measure cpu cycles
                XCTStorageMetric(), // to measure storage consuming
                XCTMemoryMetric()]) {
                // activity measurement here
                app.launch()
            }
        }
    }

    func testPerfTabs_3_20tabTray() {
        if #available(iOS 13.0, *) {
            app.launch()
            waitForExistence(app.buttons["urlBar-cancel"], timeout: 10)
            navigator.performAction(Action.CloseURLBarOpen)
            waitForTabsButton()
            measure(metrics: [
                XCTClockMetric(), // to measure timeClock Mon
                XCTCPUMetric(), // to measure cpu cycles
                XCTStorageMetric(), // to measure storage consuming
                XCTMemoryMetric()]) {
                // go to tab tray
                waitForExistence(app.buttons["TabToolbar.tabsButton"])
                app.buttons["TabToolbar.tabsButton"].tap()
                waitForExistence(app.buttons["doneButtonTabTray"])
                app.buttons["doneButtonTabTray"].tap()
            }
        }
    }

    func testPerfTabs_4_1280tabTray() {
        if #available(iOS 13.0, *) {
            app.launch()
            navigator.performAction(Action.CloseURLBarOpen)
            waitForTabsButton()
            measure(metrics: [
                XCTClockMetric(), // to measure timeClock Mon
                XCTCPUMetric(), // to measure cpu cycles
                XCTStorageMetric(), // to measure storage consuming
                XCTMemoryMetric()]) {
                // go to tab tray
                app.buttons["TabToolbar.tabsButton"].tap()
                app.buttons["doneButtonTabTray"].tap()
            }
        }
    }

    // Additional Scenarios
    // 1. Start app
    // 2. Open tabs Tray
    // 3. Open 1 new tab
    // 4. Close 1 tab
    // 5. Cloase all tabs
    // 6. Switch to private browsing
    // 7. Switch back from private browsing
    // 8. Create new tab in private browsing

    // This can be used for generating new tabs
    /*
    func testTabs5Setup() {
        let archiveSize = 1080
        let fileName = "/Users/rpappalax/git/firefox-ios-TABS-PERF-WIP/Client/Assets/topdomains.txt"
        var contents = ""
        var urls = [String]()
        do {
            contents = try String(contentsOfFile: fileName)
            urls = contents.components(separatedBy: "\n")
        } catch {
            print("COULDNT LOAD")
        }
        navigator.goto(NewTabScreen)
        var counter = 0
        let topDomainsCount = urls.count
        //for url in urls {
        for n in 0...archiveSize {
            print(urls[counter])
            if (counter >= archiveSize) {
                break
            }
            // if we don't have enough urls, start from the beginning of list
            if (counter >= (topDomainsCount - 1)) {
                counter = 0
            }
            counter += 1
        }
    }*/
}
